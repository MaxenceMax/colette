import Flutter

/// Erreurs du pont de partage de photos, mappées sur les codes attendus par Flutter.
enum PhotoSharingError: Error {
  case messagesUnavailable
  case cameraUnavailable
  case busy
  case io(String)

  var flutterError: FlutterError {
    switch self {
    case .messagesUnavailable:
      return FlutterError(code: "messagesUnavailable", message: nil, details: nil)
    case .cameraUnavailable:
      return FlutterError(code: "cameraUnavailable", message: nil, details: nil)
    case .busy:
      return FlutterError(code: "busy", message: nil, details: nil)
    case .io(let message):
      return FlutterError(code: "io", message: message, details: nil)
    }
  }
}
