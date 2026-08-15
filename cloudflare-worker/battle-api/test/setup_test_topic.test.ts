import { describe, it } from 'vitest';
import { env } from 'cloudflare:test';
import type { Env } from '../src/types.js';
import { setDoc, serverTimestamp } from '../src/firestore/index.js';

const testEnv = env as unknown as Env;

describe('Setup Test Topic (Run Manually)', () => {
  it('injects a test topic and 5 active questions into Firestore', async () => {
    // Skip if no service account
    if (!testEnv.GOOGLE_SERVICE_ACCOUNT_JSON) {
      console.log('Skipping: No service account configured');
      return;
    }

    const topicId = 'test_topic_a4';
    
    // 1. Create Topic
    await setDoc(testEnv, `topics/${topicId}`, {
      nameEn: 'Test Topic A4',
      isActive: true,
      questionCount: 5,
      createdAt: serverTimestamp(),
    });
    console.log(`Created topic: topics/${topicId}`);

    // 2. Create 5 Questions
    for (let i = 1; i <= 5; i++) {
      await setDoc(testEnv, `topics/${topicId}/questions/q${i}`, {
        text: `Test Question ${i}`,
        options: ['A', 'B', 'C', 'D'],
        correctIndex: 0,
        difficulty: 'easy',
        isActive: true,
        createdAt: serverTimestamp(),
      });
      console.log(`Created question: topics/${topicId}/questions/q${i}`);
    }

    console.log('Setup complete!');
  }, 20000);
});
