import Flutter
import UIKit
import os.log

/// Canal `colette/documents` : dispatch des appels Flutter vers le store, le lister et le presenter.
final class DocumentsPlugin: NSObject {
  static let channelName = "colette/documents"

  private let store = DocumentsStore()
  private let presenter = DocumentsPresenter()

  /// Verrou global : une seule opération système à la fois (`pickRootFolder`, `preview`,
  /// `scan`, `importFile`), attente de téléchargement d'un aperçu comprise. Lu et écrit
  /// uniquement sur le thread principal, seul thread où Flutter appelle le handler et où
  /// les complétions du presenter et du lister reviennent.
  ///
  /// Libéré par la réponse unique fabriquée par `release(_:)`, sur chacun de ces chemins :
  /// 1. argument manquant ou `openRoot` / `resolve` / `locate` en échec (`exclusive` répond) ;
  /// 2. opération concurrente refusée par un garde du presenter (`cancelled`) ;
  /// 3. aucune fenêtre hôte, ou scanner indisponible (`io`) ;
  /// 4. présentation impossible de l'écran système (`io`) ;
  /// 5. annulation par l'utilisateur dans le sélecteur ou le scanner (`cancelled`) ;
  /// 6. échec du scanner VisionKit (`io`) ;
  /// 7. téléchargement iCloud en échec ou trop long (`io`) ;
  /// 8. fermeture de l'aperçu Quick Look (succès) ;
  /// 9. écriture terminée hors thread principal, réussie ou en échec (`offMainThread`) ;
  /// 10. `self` détruit pendant l'attente du téléchargement (`cancelled`).
  ///
  /// Aucune branche de `pickRootFolder`, `preview`, `scan` ou `importFile` ne revient sans
  /// appeler sa réponse : les seuls `return` anticipés sont ceux qui viennent de répondre.
  private var busy = false

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "DocumentsPlugin")?.messenger() else {
      os_log("DocumentsPlugin : registrar indisponible, canal non enregistré", type: .error)
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
      case "list":
        try list(path: try argument("path", of: call), result: result)
      case "pickRootFolder", "preview", "scan", "importFile":
        exclusive(call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch let error as DocumentsError {
      result(error.flutterError)
    } catch {
      result(DocumentsError.io(error.localizedDescription).flutterError)
    }
  }

  /// Opérations qui présentent un écran système ou attendent iCloud : une seule à la fois.
  /// Une deuxième est refusée avec `cancelled` sans toucher au presenter ni au store.
  private func exclusive(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard !busy else {
      result(DocumentsError.cancelled.flutterError)
      return
    }
    busy = true
    let reply = release(result)
    do {
      switch call.method {
      case "preview":
        try preview(path: try argument("path", of: call), result: reply)
      case "scan":
        try scan(
          path: try argument("path", of: call),
          fileName: try argument("fileName", of: call),
          result: reply)
      case "importFile":
        try importFile(path: try argument("path", of: call), result: reply)
      default:
        pickRootFolder(reply)
      }
    } catch let error as DocumentsError {
      reply(error.flutterError)
    } catch {
      reply(DocumentsError.io(error.localizedDescription).flutterError)
    }
  }

  /// Réponse unique d'une opération exclusive : libère le verrou, sur le thread principal.
  /// Les appels suivants sont ignorés, pour qu'un double rappel ne réponde jamais deux fois.
  private func release(_ result: @escaping FlutterResult) -> FlutterResult {
    var replied = false
    return { [weak self] value in
      let answer = {
        guard !replied else { return }
        replied = true
        self?.busy = false
        result(value)
      }
      if Thread.isMainThread {
        answer()
      } else {
        DispatchQueue.main.async(execute: answer)
      }
    }
  }

  /// Argument `String` obligatoire d'un appel de méthode.
  private func argument(_ name: String, of call: FlutterMethodCall) throws -> String {
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

  private func list(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let folder = try resolve(path, under: root)
    Self.offMainThread(root: root, result: result) {
      try DocumentsLister.list(folder: folder, relativePath: path)
    }
  }

  private func scan(path: String, fileName: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let folder = try resolve(path, under: root)
    presenter.scan { outcome in
      switch outcome {
      case .failure(let error):
        root.close()
        result(error.flutterError)
      case .success(let pages):
        Self.offMainThread(root: root, result: result) {
          ["name": try DocumentsWriter.writePDF(pages: pages, named: fileName, in: folder)]
        }
      }
    }
  }

  private func importFile(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let folder = try resolve(path, under: root)
    presenter.pickFile { outcome in
      switch outcome {
      case .failure(let error):
        root.close()
        result(error.flutterError)
      case .success(let source):
        Self.offMainThread(root: root, result: result) {
          defer { try? FileManager.default.removeItem(at: source) }
          let name = source.lastPathComponent
          return ["name": try DocumentsWriter.copy(source, named: name, in: folder)]
        }
      }
    }
  }

  /// Travaille sur le disque hors du thread principal, puis referme la portée sécurisée
  /// et répond sur le thread principal, que le travail ait réussi ou échoué.
  private static func offMainThread(
    root: ScopedRoot, result: @escaping FlutterResult, _ work: @escaping () throws -> Any?
  ) {
    DispatchQueue.global(qos: .userInitiated).async {
      let outcome = Self.outcome(work)
      DispatchQueue.main.async {
        root.close()
        result(outcome)
      }
    }
  }

  /// Valeur du travail, ou l'erreur du canal ; la portée sécurisée reste ouverte autour.
  private static func outcome(_ work: () throws -> Any?) -> Any? {
    do {
      return try work()
    } catch let error as DocumentsError {
      return error.flutterError
    } catch {
      return DocumentsError.io(error.localizedDescription).flutterError
    }
  }

  /// Dossier sous la racine ; ferme la portée sécurisée si le chemin est refusé.
  private func resolve(_ path: String, under root: ScopedRoot) throws -> URL {
    do {
      return try DocumentsStore.resolve(path, under: root.url)
    } catch {
      root.close()
      throw error
    }
  }

  private func preview(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let located: URL
    do {
      located = try DocumentsLister.locate(path, under: root.url)
    } catch {
      root.close()
      throw error
    }
    DocumentsLister.ensureDownloaded(located) { [weak self] outcome in
      switch outcome {
      case .failure(let error):
        root.close()
        result(error.flutterError)
      case .success(let url):
        guard let self else {
          root.close()
          result(DocumentsError.cancelled.flutterError)
          return
        }
        presenter.preview(fileURL: url) { previewOutcome in
          root.close()
          switch previewOutcome {
          case .failure(let error):
            result(error.flutterError)
          case .success:
            result(nil)
          }
        }
      }
    }
  }
}
