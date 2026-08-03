function jsonResponse(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}

function base64UrlEncode(input) {
  const bytes =
    typeof input === 'string' ? new TextEncoder().encode(input) : input;
  let str = '';
  for (let i = 0; i < bytes.length; i++) str += String.fromCharCode(bytes[i]);
  return btoa(str).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function pemToArrayBuffer(pem) {
  const cleaned = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s+/g, '');
  const binary = atob(cleaned);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes.buffer;
}

async function getGoogleAccessTokenFromServiceAccount(env) {
  if (!env.GOOGLE_SERVICE_ACCOUNT_JSON) {
    return { ok: false, error: 'GOOGLE_SERVICE_ACCOUNT_JSON is missing' };
  }
  let sa;
  try {
    sa = JSON.parse(env.GOOGLE_SERVICE_ACCOUNT_JSON);
  } catch (_) {
    return { ok: false, error: 'GOOGLE_SERVICE_ACCOUNT_JSON invalid JSON' };
  }

  const clientEmail = sa.client_email;
  const privateKey = sa.private_key;
  if (!clientEmail || !privateKey) {
    return { ok: false, error: 'service account missing client_email/private_key' };
  }

  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: clientEmail,
    sub: clientEmail,
    aud: 'https://oauth2.googleapis.com/token',
    scope:
      'https://www.googleapis.com/auth/firebase.messaging https://www.googleapis.com/auth/cloud-platform',
    iat: now,
    exp: now + 3600,
  };

  const unsigned = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(
    JSON.stringify(payload),
  )}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(privateKey),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signature = await crypto.subtle.sign(
    { name: 'RSASSA-PKCS1-v1_5' },
    key,
    new TextEncoder().encode(unsigned),
  );
  const jwt = `${unsigned}.${base64UrlEncode(new Uint8Array(signature))}`;

  const tokenResp = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  });

  const tokenBody = await tokenResp.text();
  if (!tokenResp.ok) {
    return {
      ok: false,
      error: `oauth token exchange failed: ${tokenResp.status} ${tokenBody}`,
    };
  }
  let tokenJson;
  try {
    tokenJson = JSON.parse(tokenBody);
  } catch (_) {
    return { ok: false, error: 'oauth token response invalid JSON' };
  }

  if (!tokenJson.access_token) {
    return { ok: false, error: 'oauth token response missing access_token' };
  }
  return { ok: true, accessToken: tokenJson.access_token };
}

async function clearRecipientFcmToken(env, recipientUid, accessToken) {
  const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${recipientUid}?updateMask.fieldPaths=fcmToken`;
  const resp = await fetch(url, {
    method: 'PATCH',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      fields: {
        fcmToken: { stringValue: '' },
      },
    }),
  });
  if (!resp.ok) {
    const text = await resp.text();
    return { ok: false, error: `clear token failed: ${resp.status} ${text}` };
  }
  return { ok: true };
}

async function verifyFirebaseIdToken(idToken, env) {
  if (!env.FIREBASE_WEB_API_KEY) {
    return { ok: false, error: 'FIREBASE_WEB_API_KEY is missing' };
  }

  const resp = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${env.FIREBASE_WEB_API_KEY}`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ idToken }),
    },
  );

  if (!resp.ok) {
    const text = await resp.text();
    return { ok: false, error: `id token verify failed: ${resp.status} ${text}` };
  }

  const data = await resp.json();
  const user = data?.users?.[0];
  if (!user?.localId) {
    return { ok: false, error: 'id token verify missing localId' };
  }
  return { ok: true, uid: user.localId };
}

async function sendFcmV1(env, payload) {
  if (!env.FIREBASE_PROJECT_ID) {
    return { ok: false, error: 'FIREBASE_PROJECT_ID is missing' };
  }
  const token = await getGoogleAccessTokenFromServiceAccount(env);
  if (!token.ok) {
    return { ok: false, error: token.error };
  }

  const fcmResp = await fetch(
    `https://fcm.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/messages:send`,
    {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        authorization: `Bearer ${token.accessToken}`,
      },
      body: JSON.stringify({ message: payload }),
    },
  );

  const bodyText = await fcmResp.text();
  let bodyJson = null;
  try {
    bodyJson = JSON.parse(bodyText);
  } catch (_) {
    // Keep raw text fallback.
  }

  if (!fcmResp.ok) {
    const fcmErrorCode =
      bodyJson?.error?.details?.find?.(
        (d) => d?.['@type'] === 'type.googleapis.com/google.firebase.fcm.v1.FcmError',
      )?.errorCode || null;
    return {
      ok: false,
      status: fcmResp.status,
      fcmErrorCode,
      error: `FCM send failed: ${fcmResp.status} ${bodyText}`,
      accessToken: token.accessToken,
    };
  }
  return { ok: true, body: bodyText, accessToken: token.accessToken };
}

function readStringField(fields, key) {
  const value = fields?.[key];
  if (!value) return '';
  if (typeof value.stringValue === 'string') return value.stringValue;
  return '';
}

async function fetchAllUsersWithTokens(env, accessToken) {
  const users = [];
  let pageToken = '';

  do {
    const params = new URLSearchParams({ pageSize: '300' });
    if (pageToken) params.set('pageToken', pageToken);

    const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/users?${params}`;
    const resp = await fetch(url, {
      headers: { authorization: `Bearer ${accessToken}` },
    });
    if (!resp.ok) {
      const text = await resp.text();
      return { ok: false, error: `users list failed: ${resp.status} ${text}` };
    }

    const data = await resp.json();
    for (const doc of data.documents || []) {
      const uid = doc.name?.split('/').pop() || '';
      const fcmToken = readStringField(doc.fields, 'fcmToken').trim();
      if (uid && fcmToken) {
        users.push({ uid, fcmToken });
      }
    }
    pageToken = data.nextPageToken || '';
  } while (pageToken);

  return { ok: true, users };
}

async function fetchSingleUserWithToken(env, accessToken, uid) {
  const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${uid}`;
  const resp = await fetch(url, {
    headers: { authorization: `Bearer ${accessToken}` },
  });
  
  if (!resp.ok) {
    if (resp.status === 404) return { ok: true, users: [] };
    const text = await resp.text();
    return { ok: false, error: `user fetch failed: ${resp.status} ${text}` };
  }

  const data = await resp.json();
  const fcmToken = readStringField(data.fields, 'fcmToken').trim();
  
  // Always return the user so the inbox notification is written.
  // FCM push is only attempted if a token exists.
  return { ok: true, users: [{ uid, fcmToken }] };
}

async function writeNotificationItem(env, accessToken, uid, type, message) {
  const now = new Date().toISOString();
  const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/notifications/${uid}/items`;
  const resp = await fetch(url, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${accessToken}`,
    },
    body: JSON.stringify({
      fields: {
        type: { stringValue: type },
        message: { stringValue: message },
        isRead: { booleanValue: false },
        createdAt: { timestampValue: now },
      },
    }),
  });

  if (!resp.ok) {
    const text = await resp.text();
    return { ok: false, error: `notification write failed: ${resp.status} ${text}` };
  }

  const data = await resp.json();
  const notificationId = data.name?.split('/').pop() || '';
  return { ok: true, notificationId };
}

function logAdminPush(step, detail) {
  console.log(`[AdminPush] ${step}${detail ? `: ${detail}` : ''}`);
}

async function fetchUserRole(env, accessToken, uid) {
  const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/users/${uid}`;
  const resp = await fetch(url, {
    headers: { authorization: `Bearer ${accessToken}` },
  });

  if (!resp.ok) {
    return { ok: false, error: `user fetch failed: ${resp.status}` };
  }

  const data = await resp.json();
  const role = readStringField(data.fields, 'role');
  return { ok: true, role };
}

export default {
  async fetch(request, env) {
    logAdminPush('request', `${request.method} ${request.url}`);

    if (request.method !== 'POST') {
      logAdminPush('reject', 'method_not_allowed');
      return jsonResponse({ error: 'method_not_allowed' }, 405);
    }

    if (env.GATEWAY_KEY) {
      const key = request.headers.get('x-gateway-key');
      if (key !== env.GATEWAY_KEY) {
        logAdminPush('reject', 'unauthorized_gateway_key');
        return jsonResponse({ error: 'unauthorized_gateway_key' }, 401);
      }
    }

    const auth = request.headers.get('authorization') || '';
    const idToken = auth.startsWith('Bearer ') ? auth.slice(7) : '';
    if (!idToken) {
      logAdminPush('reject', 'missing_id_token');
      return jsonResponse({ error: 'missing_id_token' }, 401);
    }

    let body;
    try {
      body = await request.json();
    } catch (_) {
      return jsonResponse({ error: 'invalid_json' }, 400);
    }

    const adminUid = String(body.adminUid || '');
    const title = String(body.title || '').trim();
    const message = String(body.message || '').trim();
    const type = String(body.type || 'announcement').trim();
    const targetUid = String(body.targetUid || '').trim();

    if (!adminUid || !title || !message) {
      logAdminPush('reject', 'missing_required_fields');
      return jsonResponse({ error: 'missing_required_fields' }, 400);
    }

    const verify = await verifyFirebaseIdToken(idToken, env);
    if (!verify.ok) {
      logAdminPush('reject', verify.error);
      return jsonResponse({ error: verify.error }, 401);
    }
    if (verify.uid !== adminUid) {
      logAdminPush('reject', `admin_uid_mismatch token=${verify.uid}`);
      return jsonResponse({ error: 'admin_uid_mismatch' }, 403);
    }

    const oauth = await getGoogleAccessTokenFromServiceAccount(env);
    if (!oauth.ok) {
      logAdminPush('reject', oauth.error);
      return jsonResponse({ error: oauth.error }, 502);
    }

    const roleResult = await fetchUserRole(env, oauth.accessToken, adminUid);
    if (!roleResult.ok) {
      logAdminPush('reject', roleResult.error);
      return jsonResponse({ error: 'failed_to_verify_role' }, 500);
    }
    if (roleResult.role !== 'admin') {
      logAdminPush('reject', `not_admin role=${roleResult.role} uid=${adminUid}`);
      return jsonResponse({ error: 'not_admin' }, 403);
    }

    logAdminPush('auth_ok', `adminUid=${adminUid} type=${type} targetUid=${targetUid || 'all'}`);

    const usersResult = targetUid
      ? await fetchSingleUserWithToken(env, oauth.accessToken, targetUid)
      : await fetchAllUsersWithTokens(env, oauth.accessToken);

    if (!usersResult.ok) {
      logAdminPush('reject', usersResult.error);
      return jsonResponse({ error: usersResult.error }, 502);
    }

    logAdminPush('users_loaded', `count=${usersResult.users.length}`);

    const resolvedBody = message;
    let sent = 0;
    let failed = 0;
    let fcmSkippedDuplicates = 0;
    const inboxWritten = [];
    const seenTokens = new Set();

    for (const user of usersResult.users) {
      const inbox = await writeNotificationItem(
        env,
        oauth.accessToken,
        user.uid,
        type,
        resolvedBody,
      );
      if (!inbox.ok) {
        failed += 1;
        continue;
      }
      inboxWritten.push(user.uid);

      // Skip FCM if no token stored for this user.
      if (!user.fcmToken) {
        continue;
      }

      if (seenTokens.has(user.fcmToken)) {
        fcmSkippedDuplicates += 1;
        continue;
      }
      seenTokens.add(user.fcmToken);

      // Data-only FCM: app shows one local notification (avoids system+app duplicate).
      const fcmPayload = {
        token: user.fcmToken,
        data: {
          type,
          notificationType: type,
          title,
          recipientUid: user.uid,
          notificationId: inbox.notificationId,
          message: resolvedBody,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
        },
        apns: {
          headers: {
            'apns-priority': '10',
          },
          payload: {
            aps: {
              alert: {
                title,
                body: resolvedBody,
              },
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const push = await sendFcmV1(env, fcmPayload);
      if (!push.ok) {
        failed += 1;
        if (push.fcmErrorCode === 'UNREGISTERED') {
          await clearRecipientFcmToken(env, user.uid, push.accessToken);
        }
        continue;
      }
      sent += 1;
    }

    const summary = {
      ok: true,
      sent,
      failed,
      fcmSkippedDuplicates,
      totalTokens: usersResult.users.length,
      uniqueTokens: seenTokens.size,
      inboxWritten: inboxWritten.length,
    };
    logAdminPush('done', JSON.stringify(summary));
    return jsonResponse(summary);
  },
};
