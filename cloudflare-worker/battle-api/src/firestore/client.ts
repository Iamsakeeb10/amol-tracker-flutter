// ---------------------------------------------------------------------------
// Firestore REST Client Wrapper
//
// Provides getDoc, setDoc, updateDoc, and runTransaction using the
// Firestore REST API. Uses the service account OAuth2 token for auth.
// ---------------------------------------------------------------------------

import type { Env } from '../types.js';
import { getGoogleAccessToken } from './auth.js';
import { encodeDocument, decodeDocument } from './mapper.js';
import { internalError, notFoundError } from '../errors.js';

function getBaseUrl(projectId: string) {
  return `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;
}

/**
 * Helper to execute a REST API fetch with auth headers.
 */
async function firestoreFetch(env: Env, url: string, options: RequestInit = {}) {
  const token = await getGoogleAccessToken(env);
  const headers = new Headers(options.headers);
  headers.set('Authorization', `Bearer ${token}`);
  
  if (options.body && !headers.has('Content-Type')) {
    headers.set('Content-Type', 'application/json');
  }

  const response = await fetch(url, { ...options, headers });
  const data = await response.text();
  
  let json: any = null;
  if (data) {
    try {
      json = JSON.parse(data);
    } catch {
      // Ignored
    }
  }

  if (!response.ok) {
    throw internalError(`Firestore API error (${response.status}): ${data}`);
  }

  return json;
}

// ---------------------------------------------------------------------------
// Basic Operations
// ---------------------------------------------------------------------------

export async function getDoc(env: Env, path: string): Promise<Record<string, any> | null> {
  try {
    const url = `${getBaseUrl(env.FIREBASE_PROJECT_ID)}/${path}`;
    const result = await firestoreFetch(env, url);
    return decodeDocument(result.fields);
  } catch (err: any) {
    if (err.httpStatus === 404 || err.message?.includes('404')) {
      return null;
    }
    throw err;
  }
}

export async function setDoc(env: Env, path: string, data: Record<string, any>): Promise<void> {
  const { fields, transforms } = encodeDocument(data);
  const writes: any[] = [];
  const fullPath = `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`;

  // setDoc overwrites the entire document, so we don't use an updateMask
  writes.push({
    update: {
      name: fullPath,
      fields,
    }
  });

  if (transforms.length > 0) {
    writes.push({
      transform: {
        document: fullPath,
        fieldTransforms: transforms,
      }
    });
  }

  await firestoreFetch(env, `${getBaseUrl(env.FIREBASE_PROJECT_ID)}:commit`, {
    method: 'POST',
    body: JSON.stringify({ writes }),
  });
}

export async function updateDoc(env: Env, path: string, data: Record<string, any>): Promise<void> {
  const { fields, transforms } = encodeDocument(data);
  const writes: any[] = [];
  const fullPath = `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`;
  const fieldPaths = Object.keys(fields);

  const updateWrite: any = {
    update: {
      name: fullPath,
      fields,
    },
    // Fails if the document does not exist
    currentDocument: { exists: true },
  };

  if (fieldPaths.length > 0) {
    updateWrite.updateMask = { fieldPaths };
  }
  
  writes.push(updateWrite);

  if (transforms.length > 0) {
    writes.push({
      transform: {
        document: fullPath,
        fieldTransforms: transforms,
      }
    });
  }

  try {
    await firestoreFetch(env, `${getBaseUrl(env.FIREBASE_PROJECT_ID)}:commit`, {
      method: 'POST',
      body: JSON.stringify({ writes }),
    });
  } catch (err: any) {
    if (err.message?.includes('NOT_FOUND')) {
      throw notFoundError('Document not found for update');
    }
    throw err;
  }
}

export async function deleteDoc(env: Env, path: string): Promise<void> {
  const fullPath = `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`;
  await firestoreFetch(env, `${getBaseUrl(env.FIREBASE_PROJECT_ID)}:commit`, {
    method: 'POST',
    body: JSON.stringify({
      writes: [{ delete: fullPath }]
    }),
  });
}

/**
 * Execute a structured query via POST :runQuery.
 */
export async function runQuery(env: Env, parent: string, structuredQuery: any): Promise<any[]> {
  const url = `${getBaseUrl(env.FIREBASE_PROJECT_ID)}/${parent}:runQuery`;
  const response = (await firestoreFetch(env, url, {
    method: 'POST',
    body: JSON.stringify({ structuredQuery }),
  })) as any[];

  // runQuery returns an array of RunQueryResponse objects
  // Each object has a `document` property if a match was found.
  return response.filter((res) => res.document).map((res) => res.document);
}

// ---------------------------------------------------------------------------
// Transactions
// ---------------------------------------------------------------------------

export interface Transaction {
  get(path: string): Promise<Record<string, any> | null>;
  set(path: string, data: Record<string, any>): void;
  update(path: string, data: Record<string, any>): void;
  delete(path: string): void;
}

export async function runTransaction(
  env: Env,
  callback: (tx: Transaction) => Promise<void>
): Promise<void> {
  const baseUrl = getBaseUrl(env.FIREBASE_PROJECT_ID);
  
  // 1. Begin transaction
  const beginRes = await firestoreFetch(env, `${baseUrl}:beginTransaction`, {
    method: 'POST',
    body: JSON.stringify({ options: { readWrite: {} } }),
  });
  const transactionId = beginRes.transaction;

  const queuedWrites: any[] = [];

  // 2. Create the tx wrapper
  const tx: Transaction = {
    async get(path: string) {
      const fullPath = `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`;
      // batchGet must be used because normal GET doesn't support transactionId parameter
      const res = await firestoreFetch(env, `${baseUrl}:batchGet`, {
        method: 'POST',
        body: JSON.stringify({
          documents: [fullPath],
          transaction: transactionId,
        }),
      });
      
      // batchGet returns an array of results, either { found: Document } or { missing: string }
      if (Array.isArray(res) && res.length > 0 && res[0].found) {
        return decodeDocument(res[0].found.fields);
      }
      return null;
    },
    
    set(path: string, data: Record<string, any>) {
      const { fields, transforms } = encodeDocument(data);
      const fullPath = `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`;
      
      queuedWrites.push({
        update: { name: fullPath, fields }
      });
      
      if (transforms.length > 0) {
        queuedWrites.push({
          transform: { document: fullPath, fieldTransforms: transforms }
        });
      }
    },
    
    update(path: string, data: Record<string, any>) {
      const { fields, transforms } = encodeDocument(data);
      const fullPath = `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`;
      
      const updateWrite: any = {
        update: { name: fullPath, fields },
        currentDocument: { exists: true },
      };
      const fieldPaths = Object.keys(fields);
      if (fieldPaths.length > 0) {
        updateWrite.updateMask = { fieldPaths };
      }
      queuedWrites.push(updateWrite);
      
      if (transforms.length > 0) {
        queuedWrites.push({
          transform: { document: fullPath, fieldTransforms: transforms }
        });
      }
    },
    
    delete(path: string) {
      const fullPath = `projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${path}`;
      queuedWrites.push({ delete: fullPath });
    }
  };

  // 3. Execute the user callback
  await callback(tx);

  // 4. Commit the transaction
  if (queuedWrites.length > 0) {
    await firestoreFetch(env, `${baseUrl}:commit`, {
      method: 'POST',
      body: JSON.stringify({
        writes: queuedWrites,
        transaction: transactionId,
      }),
    });
  } else {
    // Optionally rollback if no writes? REST API transactions expire or auto-rollback.
    await firestoreFetch(env, `${baseUrl}:rollback`, {
      method: 'POST',
      body: JSON.stringify({ transaction: transactionId }),
    }).catch(() => {}); // Ignore errors on rollback
  }
}
