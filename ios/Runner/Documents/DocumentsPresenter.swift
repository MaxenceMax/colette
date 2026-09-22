import QuickLook
import UIKit
import UniformTypeIdentifiers
import VisionKit

/// Présente les écrans système : sélecteur de dossier, aperçu Quick Look.
final class DocumentsPresenter: NSObject {
  private var pickerCompletion: ((Result<URL, DocumentsError>) -> Void)?
  private var previewURL: URL?
  private var previewCompletion: ((Result<Void, DocumentsError>) -> Void)?
  private var scanCompletion: ((Result<[UIImage], DocumentsError>) -> Void)?

  /// Contrôleur au sommet de la scène active, seul capable de présenter un écran système.
  private var host: UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window =
      scenes.first { $0.activationState == .foregroundActive }?.keyWindow
      ?? scenes.compactMap(\.keyWindow).first
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController { controller = presented }
    return controller
  }

  /// Sélecteur de dossier ; `cancelled` si un sélecteur est déjà ouvert.
  func pickFolder(completion: @escaping (Result<URL, DocumentsError>) -> Void) {
    guard pickerCompletion == nil else {
      completion(.failure(.cancelled))
      return
    }
    guard let host else {
      completion(.failure(.io("Aucune fenêtre")))
      return
    }
    pickerCompletion = completion
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.allowsMultipleSelection = false
    picker.delegate = self
    host.present(picker, animated: true)
  }

  /// Sélecteur de fichier (copie locale) ; `cancelled` si un sélecteur est déjà ouvert.
  func pickFile(completion: @escaping (Result<URL, DocumentsError>) -> Void) {
    guard pickerCompletion == nil else {
      completion(.failure(.cancelled))
      return
    }
    guard let host else {
      completion(.failure(.io("Aucune fenêtre")))
      return
    }
    pickerCompletion = completion
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
    picker.allowsMultipleSelection = false
    picker.delegate = self
    host.present(picker, animated: true)
  }

  /// Scanner VisionKit ; `cancelled` si un scan est déjà en cours.
  func scan(completion: @escaping (Result<[UIImage], DocumentsError>) -> Void) {
    guard scanCompletion == nil else {
      completion(.failure(.cancelled))
      return
    }
    guard VNDocumentCameraViewController.isSupported, let host else {
      completion(.failure(.io("Scanner indisponible")))
      return
    }
    scanCompletion = completion
    let scanner = VNDocumentCameraViewController()
    scanner.delegate = self
    host.present(scanner, animated: true)
  }

  /// Aperçu Quick Look ; échoue si aucune fenêtre ne peut présenter l'aperçu.
  func preview(fileURL: URL, completion: @escaping (Result<Void, DocumentsError>) -> Void) {
    guard let host else {
      completion(.failure(.io("Aucune fenêtre")))
      return
    }
    previewURL = fileURL
    previewCompletion = completion
    let controller = QLPreviewController()
    controller.dataSource = self
    controller.delegate = self
    host.present(controller, animated: true)
  }
}

extension DocumentsPresenter: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    let completion = pickerCompletion
    pickerCompletion = nil
    guard let url = urls.first else {
      completion?(.failure(.cancelled))
      return
    }
    completion?(.success(url))
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    let completion = pickerCompletion
    pickerCompletion = nil
    completion?(.failure(.cancelled))
  }
}

extension DocumentsPresenter: VNDocumentCameraViewControllerDelegate {
  private func finishScan(
    _ controller: UIViewController, _ outcome: Result<[UIImage], DocumentsError>
  ) {
    let completion = scanCompletion
    scanCompletion = nil
    controller.dismiss(animated: true) { completion?(outcome) }
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan
  ) {
    let pages = (0..<scan.pageCount).map { scan.imageOfPage(at: $0) }
    finishScan(controller, .success(pages))
  }

  func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
    finishScan(controller, .failure(.cancelled))
  }

  func documentCameraViewController(
    _ controller: VNDocumentCameraViewController, didFailWithError error: Error
  ) {
    finishScan(controller, .failure(.io(error.localizedDescription)))
  }
}

extension DocumentsPresenter: QLPreviewControllerDataSource, QLPreviewControllerDelegate {
  func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
    previewURL == nil ? 0 : 1
  }

  func previewController(_ controller: QLPreviewController, previewItemAt index: Int)
    -> QLPreviewItem
  {
    (previewURL ?? URL(fileURLWithPath: "")) as NSURL
  }

  func previewControllerDidDismiss(_ controller: QLPreviewController) {
    let completion = previewCompletion
    previewCompletion = nil
    previewURL = nil
    completion?(.success(()))
  }
}
