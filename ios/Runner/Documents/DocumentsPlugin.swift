import Flutter
import UIKit
import os.log

/// Relie un canal de dossier (`colette/documents/folder/{n}`) à son observateur.
final class DocumentsFolderStreamHandler: NSObject, FlutterStreamHandler {
  private let listen: (@escaping FlutterEventSink) -> Void
  private let cancel: () -> Void

  init(onListen: @escaping (@escaping FlutterEventSink) -> Void, onCancel: @escaping () -> Void) {
    listen = onListen
    cancel = onCancel
  }

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    listen(events)
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    cancel()
    return nil
  }
}

/// Canal `colette/documents` : dispatch des appels Flutter vers le store, le lister,
/// le writer, le presenter et les observateurs de dossier.
final class DocumentsPlugin: NSObject {
  static let channelName = "colette/documents"
  static let folderChannelPrefix = "colette/documents/folder/"

  private let messenger: FlutterBinaryMessenger
  private let store = DocumentsStore()
  private let presenter = DocumentsPresenter()

  /// Observateurs et canaux de dossier vivants, par nom de canal.
  private var watchers: [String: DocumentsFolderWatcher] = [:]
  private var folderChannels: [String: FlutterEventChannel] = [:]
  private var nextFolderChannel = 0

  /// Verrou global : une seule opération qui présente un écran système à la fois
  /// (`pickRootFolder`, `preview`, `scan`, `importFile`), le temps où l'écran est
  /// affiché. Lu et écrit uniquement sur le thread principal.
  ///
  /// Libéré par la réponse unique fabriquée par `release(_:)`, sur chacun de ces chemins :
  /// 1. argument manquant, `openRoot` / `resolve` / `locate` en échec, fichier non
  ///    téléchargé pour un aperçu (`exclusive` répond) ;
  /// 2. opération concurrente refusée par un garde du presenter (`cancelled`) ;
  /// 3. aucune fenêtre hôte, ou scanner indisponible (`io`) ;
  /// 4. présentation impossible de l'écran système (`io`) ;
  /// 5. annulation par l'utilisateur dans le sélecteur ou le scanner (`cancelled`) ;
  /// 6. échec du scanner VisionKit (`io`) ;
  /// 7. fermeture de l'aperçu Quick Look (succès) ;
  /// 8. écriture terminée hors thread principal, réussie ou en échec (`offMainThread`).
  ///
  /// `rootFolder`, `forgetRootFolder`, `openFolderStream`, `download`, `delete` et
  /// `openInFiles` ne prennent pas le verrou.
  private var busy = false

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
  }

  static func register(with registry: FlutterPluginRegistry) {
    guard let messenger = registry.registrar(forPlugin: "DocumentsPlugin")?.messenger() else {
      os_log("DocumentsPlugin : registrar indisponible, canal non enregistré", type: .error)
      return
    }
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    let plugin = DocumentsPlugin(messenger: messenger)
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
      case "openFolderStream":
        result(try openFolderStream(path: try argument("path", of: call)))
      case "download":
        try download(path: try argument("path", of: call))
        result(nil)
      case "delete":
        try delete(path: try argument("path", of: call), result: result)
      case "openInFiles":
        try openInFiles(path: try argument("path", of: call), result: result)
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

  /// Opérations qui présentent un écran système : une seule à la fois.
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

  // MARK: - Flux d'un dossier

  /// Crée un canal d'événements dédié et son observateur ; l'observateur démarre à
  /// l'abonnement Flutter et s'arrête (portée refermée) au désabonnement.
  private func openFolderStream(path: String) throws -> [String: Any] {
    let root = try store.openRoot()
    let folder = try resolve(path, under: root)
    nextFolderChannel += 1
    let name = Self.folderChannelPrefix + String(nextFolderChannel)
    let watcher = DocumentsFolderWatcher(root: root, folder: folder, relativePath: path)
    let channel = FlutterEventChannel(name: name, binaryMessenger: messenger)
    channel.setStreamHandler(
      DocumentsFolderStreamHandler(
        onListen: { sink in watcher.start(sink: sink) },
        onCancel: { [weak self] in self?.closeFolderStream(name) }))
    watchers[name] = watcher
    folderChannels[name] = channel
    return ["channel": name]
  }

  /// Sans effet si le canal est déjà fermé (Flutter annule aussi après une erreur ou une fin).
  private func closeFolderStream(_ name: String) {
    watchers.removeValue(forKey: name)?.stop()
    folderChannels.removeValue(forKey: name)?.setStreamHandler(nil)
  }

  /// Relistage forcé de tous les abonnements au dossier `path`.
  private func refreshWatchers(of path: String) {
    for watcher in watchers.values where watcher.relativePath == path {
      watcher.refresh()
    }
  }

  /// `Ordonnances/2026/a.pdf` → `Ordonnances/2026` ; `a.pdf` → `""`.
  private static func parent(of path: String) -> String {
    path.split(separator: "/").dropLast().joined(separator: "/")
  }

  // MARK: - Téléchargement, suppression, Fichiers

  private func download(path: String) throws {
    let root = try store.openRoot()
    defer { root.close() }
    let located = try DocumentsLister.locate(path, under: root.url)
    try DocumentsLister.startDownload(located)
  }

  private func delete(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let located: URL
    do {
      located = try DocumentsLister.locate(path, under: root.url)
    } catch {
      root.close()
      throw error
    }
    var isDirectory: ObjCBool = false
    if FileManager.default.fileExists(atPath: located.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    {
      root.close()
      throw DocumentsError.io("Un dossier ne peut pas être supprimé")
    }
    let folderPath = Self.parent(of: path)
    Self.offMainThread(
      root: root,
      result: { [weak self] value in
        if !(value is FlutterError) { self?.refreshWatchers(of: folderPath) }
        result(value)
      }
    ) {
      try DocumentsWriter.delete(DocumentsLister.realURL(for: located))
      return nil
    }
  }

  /// Ouvre l'app Fichiers sur le dossier. La portée sécurisée est refermée avant l'ouverture :
  /// le chemin absolu reste valable pour le lien, et Fichiers a ses propres droits.
  private func openInFiles(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let folder = try resolve(path, under: root)
    root.close()
    var components = URLComponents()
    components.scheme = "shareddocuments"
    // Hôte vide : `shareddocuments:///chemin`, forme attendue par Fichiers.
    components.host = ""
    components.path = folder.path
    guard let url = components.url else { throw DocumentsError.io("Lien Fichiers invalide") }
    UIApplication.shared.open(url, options: [:]) { opened in
      result(opened ? nil : DocumentsError.io("Fichiers ne s'est pas ouvert").flutterError)
    }
  }

  // MARK: - Écriture

  private func scan(path: String, fileName: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let folder = try resolve(path, under: root)
    presenter.scan { [weak self] outcome in
      switch outcome {
      case .failure(let error):
        root.close()
        result(error.flutterError)
      case .success(let pages):
        Self.offMainThread(
          root: root,
          result: { value in
            if !(value is FlutterError) { self?.refreshWatchers(of: path) }
            result(value)
          }
        ) {
          ["name": try DocumentsWriter.writePDF(pages: pages, named: fileName, in: folder)]
        }
      }
    }
  }

  private func importFile(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let folder = try resolve(path, under: root)
    presenter.pickFile { [weak self] outcome in
      switch outcome {
      case .failure(let error):
        root.close()
        result(error.flutterError)
      case .success(let source):
        Self.offMainThread(
          root: root,
          result: { value in
            if !(value is FlutterError) { self?.refreshWatchers(of: path) }
            result(value)
          }
        ) {
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

  // MARK: - Aperçu

  /// Aperçu sans attente : le fichier doit déjà être lisible localement.
  private func preview(path: String, result: @escaping FlutterResult) throws {
    let root = try store.openRoot()
    let real: URL
    do {
      real = DocumentsLister.realURL(for: try DocumentsLister.locate(path, under: root.url))
    } catch {
      root.close()
      throw error
    }
    guard DocumentsLister.isAvailable(real) else {
      root.close()
      throw DocumentsError.io("Fichier non téléchargé")
    }
    presenter.preview(fileURL: real) { previewOutcome in
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
