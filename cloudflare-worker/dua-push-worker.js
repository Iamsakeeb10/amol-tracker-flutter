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
  return { ok: true, body: bodyText };
}

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') {
      return jsonResponse({ error: 'method_not_allowed' }, 405);
    }

    if (env.GATEWAY_KEY) {
      const key = request.headers.get('x-gateway-key');
      if (key !== env.GATEWAY_KEY) {
        return jsonResponse({ error: 'unauthorized_gateway_key' }, 401);
      }
    }

    const auth = request.headers.get('authorization') || '';
    const idToken = auth.startsWith('Bearer ') ? auth.slice(7) : '';
    if (!idToken) {
      return jsonResponse({ error: 'missing_id_token' }, 401);
    }

    let body;
    try {
      body = await request.json();
    } catch (_) {
      return jsonResponse({ error: 'invalid_json' }, 400);
    }

    const senderUid = String(body.senderUid || '');
    const recipientUid = String(body.recipientUid || '');
    const recipientFcmToken = String(body.recipientFcmToken || '');
    const senderName = String(body.senderName || 'Someone');
    const message = String(body.message || 'You received a dua');
    const notificationId = String(body.notificationId || '');

    if (!senderUid || !recipientUid || !recipientFcmToken) {
      return jsonResponse({ error: 'missing_required_fields' }, 400);
    }
    if (senderUid === recipientUid) {
      return jsonResponse({ error: 'self_send_not_allowed' }, 400);
    }

    const verify = await verifyFirebaseIdToken(idToken, env);
    if (!verify.ok) {
      return jsonResponse({ error: verify.error }, 401);
    }
    if (verify.uid !== senderUid) {
      return jsonResponse({ error: 'sender_uid_mismatch' }, 403);
    }

    const fcmPayload = {
      token: recipientFcmToken,
      notification: {
        title: 'New dua received',
        body: `${senderName} sent you a dua`,
      },
      data: {
        type: 'dua',
        notificationType: 'dua',
        senderUid,
        recipientUid,
        notificationId,
        message,
        click_action: 'FLUTTER_NOTIFICATION_CLICK',
      },
      android: {
        priority: 'high',
        notification: {
          channel_id: 'amal_tracker_daily',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
      apns: {
        headers: {
          'apns-priority': '10',
        },
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const sent = await sendFcmV1(env, fcmPayload);
    if (!sent.ok) {
      if (sent.fcmErrorCode === 'UNREGISTERED') {
        const cleared = await clearRecipientFcmToken(
          env,
          recipientUid,
          sent.accessToken,
        );
        if (!cleared.ok) {
          return jsonResponse(
            {
              error: sent.error,
              warning: 'token_unregistered_but_cleanup_failed',
              cleanupError: cleared.error,
            },
            502,
          );
        }
        return jsonResponse(
          {
            error: sent.error,
            warning: 'token_unregistered_and_cleared',
          },
          410,
        );
      }
      return jsonResponse({ error: sent.error }, 502);
    }

    return jsonResponse({ ok: true });
  },
};
