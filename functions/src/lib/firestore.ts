import { DocumentReference, getFirestore } from 'firebase-admin/firestore';
import type { Device, DeviceDoc } from './types';

export const db = () => getFirestore();

export async function loadDevices(household: DocumentReference): Promise<Device[]> {
  const snap = await household.collection('devices').get();
  return snap.docs.map((d) => ({ id: d.id, ...(d.data() as DeviceDoc) }));
}
