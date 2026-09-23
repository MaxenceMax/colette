/// Où en est une étape du calendrier.
enum MedicalStageStatus {
  done,

  /// RDV passé, visite pas encore marquée faite.
  appointmentPassed,
  scheduled,
  late,
  due,
  upcoming,
}
