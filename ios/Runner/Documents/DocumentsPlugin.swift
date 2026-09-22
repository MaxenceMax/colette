import Flutter
import UIKit

/// Canal `colette/documents` : dispatch des appels Flutter vers le store, le lister et le presenter.
final class DocumentsPlugin: NSObject {
  static let channelName = "colette/documents"

  private let store = DocumentsStore()
  private let presenter = DocumentsPresenter()

  /// Racine gardée ouverte pendant un aperçu (portée sécurisée).
  private var activeRoot: ScopedRoot?

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "DocumentsPlugin")?.messenger() else {
      return
    }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let plugin = DocumentsPlugin()
    channel.setMethodCallHandler { call, result in plugin.handle(call, result: result) }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    do {
      switch call.method {
      case "rootFolder":
        result(try rootFolder())
      case "forgetRootFolder":
        store.forget()
        result(nil)
      case "pickRootFolder":
        pickRootFolder(result)
      case "list":
        result(try list(path: try argument("path", of: call)))
      case "preview":
        try preview(path: try argument("path", of: call), result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as DocumentsError {
      result(error.flutterError)
    } catch {
      result(DocumentsError.io(error.localizedDescription).flutterError)
    }
  }

  func argument(_ name: String, of call: FlutterMethodCall) throws -> String {
    guard let args = call.arguments as? [String: Any], let value = args[name] as? String else {
      throw DocumentsError.io("Argument manquant : \(name)")
    }
    return value
  }

  private func rootFolder() throws -> [String: Any]? {
    guard store.hasRoot else { return nil }
    let root = try store.openRoot()
    defer { root.close() }
    return ["name": root.url.lastPathComponent]
  }

  private func pickRootFolder(_ result: @escaping FlutterResult) {
    presenter.pickFolder { [store = self.store] outcome in
      switch outcome {
      case .failure(let error):
        result(error.flutterError)
      case .success(let url):
        do {
          result(["name": try store.save(rootURL: url)])
        } catch let error as DocumentsError {
          result(error.flutterError)
        } catch {
          result(DocumentsError.io(error.localizedDescription).flutterError)
        }
      }
    }
  }

  private func list(path: String) throws -> [[String: Any]] {
    let root = try store.openRoot()
    defer { root.close() }
    let folder = try DocumentsStore.resolve(path, under: root.url)
    return try DocumentsLister.list(folder: folder, relativePath: path)
  }

  private func preview(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    activeRoot = root
    let located: URL
    do {
      located = try DocumentsLister.locate(path, under: root.url)
    } catch {
      activeRoot?.close()
      activeRoot = nil
      throw error
    }
    DocumentsLister.ensureDownloaded(located) { [weak self] outcome in
      switch outcome {
      case .failure(let error):
        self?.activeRoot?.close()
        self?.activeRoot = nil
        result(error.flutterError)
      case .success(let url):
        self?.presenter.preview(fileURL: url) {
          self?.activeRoot?.close()
          self?.activeRoot = nil
          result(nil)
        }
      }
    }
  }
}
