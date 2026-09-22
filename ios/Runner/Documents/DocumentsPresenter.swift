import QuickLook
import UIKit
import UniformTypeIdentifiers

/// Présente les écrans système : sélecteur de dossier, aperçu Quick Look.
final class DocumentsPresenter: NSObject {
  private var pickerCompletion: ((Result<URL, DocumentsError>) -> Void)?
  private var previewURL: URL?
  private var previewCompletion: (() -> Void)?

  private var host: UIViewController? {
    UIApplication.shared.connectedScenes
      .compactMap { ($0 as? UIWindowScene)?.keyWindow }
      .first?.rootViewController
  }

  func pickFolder(completion: @escaping (Result<URL, DocumentsError>) -> Void) {
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

  func preview(fileURL: URL, completion: @escaping () -> Void) {
    guard let host else {
      completion()
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
    completion?()
  }
}
