// ---------------------------------------------------------------------------
// Integration tests for the Firestore REST Client.
//
// These tests execute real HTTP requests against the dev Firestore project.
// They require GOOGLE_SERVICE_ACCOUNT_JSON to be set in .dev.vars or
// the environment.
// ---------------------------------------------------------------------------

import { env } from 'cloudflare:test';
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { getDoc, setDoc, updateDoc, deleteDoc, runTransaction } from '../src/firestore/client.js';
import { serverTimestamp } from '../src/firestore/mapper.js';
import type { Env } from '../src/types.js';

// The vitest pool automatically loads bindings from wrangler.toml and .dev.vars
// into the `env` object exported by 'cloudflare:test'.
const testEnv = env as unknown as Env;

const TEST_COLLECTION = '_test_battles';
const TEST_DOC_ID = `test_${Date.now()}`;
const TEST_PATH = `${TEST_COLLECTION}/${TEST_DOC_ID}`;

// We only run these tests if the service account secret is provided.
const hasSecret = Boolean(testEnv.GOOGLE_SERVICE_ACCOUNT_JSON);

describe.skipIf(!hasSecret)('Firestore REST Client Wrapper (Integration)', () => {
  afterAll(async () => {
    // Cleanup: try to delete the test document
    if (hasSecret) {
      try {
        await deleteDoc(testEnv, TEST_PATH);
      } catch (e) {
        console.error('Failed to clean up test document', e);
      }
    }
  });

  it('can setDoc and getDoc correctly', async () => {
    const data = {
      stringValue: 'hello',
      integerValue: 42,
      doubleValue: 3.14,
      booleanValue: true,
      nullValue: null,
      arrayValue: [1, 2, 'three'],
      mapValue: { nested: true },
      dateValue: new Date('2023-01-01T00:00:00Z'),
    };

    // 1. setDoc
    await setDoc(testEnv, TEST_PATH, data);

    // 2. getDoc
    const doc = await getDoc(testEnv, TEST_PATH);
    
    expect(doc).toBeDefined();
    expect(doc?.stringValue).toBe('hello');
    expect(doc?.integerValue).toBe(42);
    expect(doc?.doubleValue).toBe(3.14);
    expect(doc?.booleanValue).toBe(true);
    expect(doc?.nullValue).toBe(null);
    expect(doc?.arrayValue).toEqual([1, 2, 'three']);
    expect(doc?.mapValue).toEqual({ nested: true });
    // Date should decode back to a Date object
    expect(doc?.dateValue).toBeInstanceOf(Date);
    expect((doc?.dateValue as Date).toISOString()).toBe('2023-01-01T00:00:00.000Z');
  });

  it('can use serverTimestamp() in setDoc', async () => {
    const tsPath = `${TEST_PATH}_ts`;
    await setDoc(testEnv, tsPath, {
      createdAt: serverTimestamp(),
      otherField: 'test',
    });

    const doc = await getDoc(testEnv, tsPath);
    expect(doc).toBeDefined();
    expect(doc?.otherField).toBe('test');
    expect(doc?.createdAt).toBeInstanceOf(Date);
    // It should be roughly "now"
    const now = Date.now();
    const docTime = (doc?.createdAt as Date).getTime();
    expect(Math.abs(now - docTime)).toBeLessThan(60000); // within 1 minute

    await deleteDoc(testEnv, tsPath);
  });

  it('can updateDoc existing fields', async () => {
    await updateDoc(testEnv, TEST_PATH, {
      stringValue: 'updated',
      newField: 'added',
    });

    const doc = await getDoc(testEnv, TEST_PATH);
    expect(doc?.stringValue).toBe('updated');
    expect(doc?.newField).toBe('added');
    // Ensure old fields were not overwritten by the update
    expect(doc?.integerValue).toBe(42);
  });

  it('fails to updateDoc if document does not exist', async () => {
    const missingPath = `${TEST_COLLECTION}/does_not_exist`;
    await expect(updateDoc(testEnv, missingPath, { test: 1 })).rejects.toThrow('Document not found');
  });

  it('can runTransaction correctly', async () => {
    await runTransaction(testEnv, async (tx) => {
      const doc = await tx.get(TEST_PATH);
      expect(doc).toBeDefined();
      
      const currentCount = doc?.integerValue ?? 0;
      tx.update(TEST_PATH, { integerValue: currentCount + 1 });
    });

    const updatedDoc = await getDoc(testEnv, TEST_PATH);
    expect(updatedDoc?.integerValue).toBe(43);
  });

  it('can runTransaction to delete', async () => {
    await runTransaction(testEnv, async (tx) => {
      tx.delete(TEST_PATH);
    });

    const doc = await getDoc(testEnv, TEST_PATH);
    expect(doc).toBeNull();
  });
});

describe.runIf(!hasSecret)('Firestore REST Client Wrapper (Skipped)', () => {
  it('Service Account Secret missing', () => {
    console.warn('Skipping Firestore integration tests because GOOGLE_SERVICE_ACCOUNT_JSON is missing.');
    expect(true).toBe(true);
  });
});
