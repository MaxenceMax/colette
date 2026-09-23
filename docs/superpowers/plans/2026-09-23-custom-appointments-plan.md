# Plan — RDV libres, onglet Santé, Aujourd'hui centré

Spec : `docs/superpowers/specs/2026-09-23-custom-appointments-design.md`. Branche `feat/custom-appointments`. Chaque tâche : test rouge → implémentation → `dart run build_runner build -d` si annoté → tests verts → commit.

## Tâche 1 — Entités et validation (domaine)

- `domain/entities/custom_vaccine.dart` : freezed `CustomVaccine(code?, name?, givenAt, brand?, lot?)`, `isKnown`.
- `domain/entities/custom_appointment.dart` : freezed `CustomAppointment(id, title, appointmentAt, practitioner?, doneAt?, note?, vaccines, updatedAt, updatedByDeviceId)`.
- `domain/use_cases/compute_custom_appointment_status.dart`.
- `domain/use_cases/validate_custom_appointment.dart` ; `ValidationReason.medicalTitleRequired`, `medicalVaccineNameRequired` ; `failure_message.dart` ; clés arb `errorMedicalTitleRequired`, `errorMedicalVaccineNameRequired`.
- Tests : `test/features/health/domain/compute_custom_appointment_status_test.dart`, `validate_custom_appointment_test.dart` ; fabrique `makeAppointment` dans `health_factories.dart`.

## Tâche 2 — Frise unifiée

- `domain/entities/medical_timeline.dart` : `MedicalTimelineItem` sealed (`StageItem`, `AppointmentItem`), `MedicalTimeline(entries, appointments)`, `items`, `next` sur items.
- `ComputeMedicalTimeline` : paramètre `appointments`.
- Tests : `compute_medical_timeline_test.dart` (insertion, fin, égalité, deux RDV même jour, next).

## Tâche 3 — Réconciliation calendrier

- `ReconcileCalendar` : `appointments`, `titleOfAppointment`, `customUrlOf`, brouillon.
- Tests : `reconcile_calendar_test.dart` (création, mise à jour, fait, retiré, coexistence).

## Tâche 4 — Données

- `FirestorePaths.medicalAppointments` ; `data/dtos/custom_appointment_dto.dart` ; `MedicalRepository` + `FirestoreMedicalRepository` : `watchAppointments`, `fetchAppointmentsFromServer`, `saveAppointment`, `deleteAppointment` ; commentaire `firestore.rules`.
- Tests : `custom_appointment_dto_test.dart`, `firestore_medical_repository_test.dart`.

## Tâche 5 — Providers, contrôleur, sync

- `medicalAppointmentsProvider` ; `medicalTimelineProvider` attend les deux ; `CustomAppointmentController.save/delete` ; `FirestoreHealthSync` lit les RDV libres serveur et les passe à la frise et à la réconciliation ; `HealthSyncGate` écoute les RDV libres.
- Tests : `custom_appointment_controller_test.dart`, `health_sync_test.dart`, `health_sync_gate_test.dart`, `health_providers_test.dart`.

## Tâche 6 — UI Santé

- `health_status_text.dart` factorisé (`healthAppointmentStatusText`) ; `widgets/custom_appointment_tile.dart` ; `widgets/custom_appointment_sheet.dart` (+ `custom_vaccine_fields.dart`) ; `HealthPage` : bouton « + », sections sur `items`, listen du contrôleur. Clés arb : `healthAddAppointment`, `healthChipCustom`, `healthSheetTitle`, `healthSheetOtherVaccine`, `healthSheetAddOtherVaccine`, `healthSheetVaccineName`, `healthDeleteAppointmentTitle`, `healthDeleteAppointmentBody`.
- Tests : `health_page_test.dart`, `custom_appointment_sheet_test.dart`, `health_status_text_test.dart`.

## Tâche 7 — Navigation

- `AppRoutes.health = '/health'`, cinq branches (Journal, Assiette, Aujourd'hui, Santé, Réglages) ; `lib/app/widgets/colette_tab_bar.dart` ; `MainShell` ; retrait de `HealthCard` (+ test) du dashboard ; `notifications_gate` (liste des routes) ; clé arb `tabHealth`.
- Tests : `test/app/colette_tab_bar_test.dart`, `app_router_test.dart`, `dashboard_page_test.dart`.

## Tâche 8 — Vérification

`flutter gen-l10n`, `dart format lib test`, `dart analyze`, `flutter test`, vérification sur simulateur en clair et sombre. README si nécessaire.
