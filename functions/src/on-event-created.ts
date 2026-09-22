import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { loadDevices } from './lib/firestore';
import { sendToDevices } from './lib/push';
import { summarizeEvent } from './lib/summary';
import { toCareEvent, type Device, type EventDoc } from './lib/types';

/** Appareils à notifier : ni l'auteur, ni ceux ayant désactivé les notifications des autres événements. */
export function selectRecipients(devices: Device[], createdByDeviceId: string | undefined): Device[] {
  return devices.filter((d) => d.id !== createdByDeviceId && d.notifyOnOthersEvents !== false);
}

export const onEventCreated = onDocumentCreated('households/{code}/events/{eventId}', async (event) => {
  const snap = event.data;
  if (!snap) return;
  const data = snap.data() as EventDoc;
  const code = event.params.code;

  const devices = await loadDevices(snap.ref.parent.parent!);
  const author = devices.find((d) => d.id === data.createdByDeviceId);
  const targets = selectRecipients(devices, data.createdByDeviceId);
  if (targets.length === 0) return;

  await sendToDevices(code, targets, {
    title: `${author?.label ?? 'L\'autre iPhone'} a ajouté un événement`,
    body: summarizeEvent(toCareEvent(data)),
    data: { route: '/journal' },
  });
});
