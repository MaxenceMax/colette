import Flutter

/// Erreurs du pont Calendrier, mappées sur les codes attendus par Flutter.
enum CalendarError: Error {
  case accessDenied
  case calendarNotFound
  case io(String)

  var flutterError: FlutterError {
    switch self {
    case .accessDenied:
      return FlutterError(code: "accessDenied", message: nil, details: nil)
    case .calendarNotFound:
      return FlutterError(code: "calendarNotFound", message: nil, details: nil)
    case .io(let message):
      return FlutterError(code: "io", message: message, details: nil)
    }
  }
}
