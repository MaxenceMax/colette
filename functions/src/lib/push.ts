import { FieldValue } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';
import { logger } from 'firebase-functions';
import { db } from './firestore';
import type { Device } from './types';

export type PushPayload = { title: string; body: string; data?: Record<string, string> };

const STALE_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

/** Envoie la notification aux appareils munis d'un token ; efface les tokens morts. */
export async function sendToDevices(code: string, devices: Device[], payload: PushPayload): Promise<number> {
  const targets = devices.filter((d): d is Device & { fcmToken: string } => !!d.fcmToken);
  if (targets.length === 0) return 0;

  const response = await getMessaging().sendEachForMulticast({
    tokens: targets.map((d) => d.fcmToken),
    notification: { title: payload.title, body: payload.body },
    data: payload.data ?? {},
    apns: { payload: { aps: { sound: 'default' } } },
  });

  const stale = response.responses
    .map((r, i) => (!r.success && r.error && STALE_TOKEN_CODES.has(r.error.code) ? targets[i] : null))
    .filter((d): d is Device & { fcmToken: string } => d !== null);

  await Promise.all(
    stale.map((d) =>
      db().collection('households').doc(code).collection('devices').doc(d.id).update({
        fcmToken: FieldValue.delete(),
      }),
    ),
  );

  logger.info('push sent', { code, success: response.successCount, failure: response.failureCount, stale: stale.length });
  return response.successCount;
}
