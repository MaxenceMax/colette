import { setGlobalOptions } from 'firebase-functions/v2';
import { initializeApp } from 'firebase-admin/app';

setGlobalOptions({ region: 'europe-west1', maxInstances: 5 });
initializeApp();

export { onEventCreated } from './on-event-created';
