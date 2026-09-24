import Flutter

/// Erreurs du pont documents, mappées sur les codes attendus par Flutter.
enum DocumentsError: Error {
  case noFolder
  case accessDenied
  case cancelled
  case nameTaken
  case io(String)

  var code: String {
    switch self {
    case .noFolder: return "noFolder"
    case .accessDenied: return "accessDenied"
    case .cancelled: return "cancelled"
    case .nameTaken: return "nameTaken"
    case .io: return "io"
    }
  }

  var flutterError: FlutterError {
    switch self {
    case .io(let message):
      return FlutterError(code: code, message: message, details: nil)
    default:
      return FlutterError(code: code, message: nil, details: nil)
    }
  }
}
