import ContactsUI
import MessageUI
import PhotosUI
import UIKit
import UniformTypeIdentifiers
import os.log

/// Présente les écrans système du partage de photos : contacts, appareil photo,
/// galerie, feuilles Messages successives. Thread principal uniquement.
final class PhotoSharingPresenter: NSObject {
  private struct Tally {
    var sent = 0
    var cancelled = 0
    var failed = 0
  }

  private var contactCompletion: ((Result<[String: String]?, PhotoSharingError>) -> Void)?
  private var imagesCompletion: ((Result<[String], PhotoSharingError>) -> Void)?
  private var messagesCompletion: ((Result<[String: Int], PhotoSharingError>) -> Void)?
  private var pendingPhones: [String] = []
  private var attachments: [Data] = []
  private var messageBody = ""
  private var tally = Tally()

  /// Contrôleur au sommet de la scène active, seul capable de présenter un écran système.
  private var host: UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window =
      scenes.first { $0.activationState == .foregroundActive }?.keyWindow
      ?? scenes.compactMap(\.keyWindow).first
    var controller = window?.rootViewController
    while let presented = controller?.presentedViewController, !presented.isBeingDismissed {
      controller = presented
    }
    return controller
  }

  /// Présente l'écran et signale l'échec si la présentation n'a pas eu lieu.
  private func present(
    _ controller: UIViewController, from host: UIViewController,
    onFailure: @escaping () -> Void
  ) {
    host.present(controller, animated: true) {
      guard controller.presentingViewController == nil else { return }
      onFailure()
    }
  }

  private static let presentationFailure = "Présentation impossible"

  // MARK: - Contacts

  /// Sélecteur de contacts ; un contact à plusieurs numéros fait choisir le numéro.
  func pickContact(completion: @escaping (Result<[String: String]?, PhotoSharingError>) -> Void) {
    guard let host else {
      completion(.failure(.io("Aucune fenêtre")))
      return
    }
    contactCompletion = completion
    let picker = CNContactPickerViewController()
    picker.delegate = self
    picker.displayedPropertyKeys = [CNContactPhoneNumbersKey]
    picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
    picker.predicateForSelectionOfContact = NSPredicate(format: "phoneNumbers.@count == 1")
    picker.predicateForSelectionOfProperty = NSPredicate(
      format: "key == %@", CNContactPhoneNumbersKey)
    // Pas de fermeture par glissement : « Annuler » appelle toujours le délégué.
    picker.isModalInPresentation = true
    present(picker, from: host) { [weak self] in
      guard let self else { return }
      let pending = contactCompletion
      contactCompletion = nil
      pending?(.failure(.io(Self.presentationFailure)))
    }
  }

  private func finishContact(_ contact: CNContact, phone: String?) {
    let completion = contactCompletion
    contactCompletion = nil
    guard let phone, !phone.isEmpty else {
      completion?(.success(nil))
      return
    }
    let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
    completion?(.success(["name": name.isEmpty ? phone : name, "phone": phone]))
  }

  // MARK: - Photos

  func takePhoto(completion: @escaping (Result<[String], PhotoSharingError>) -> Void) {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      completion(.failure(.cameraUnavailable))
      return
    }
    guard let host else {
      completion(.failure(.io("Aucune fenêtre")))
      return
    }
    imagesCompletion = completion
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = self
    present(picker, from: host) { [weak self] in
      self?.finishImages(.failure(.io(Self.presentationFailure)))
    }
  }

  func pickPhotos(completion: @escaping (Result<[String], PhotoSharingError>) -> Void) {
    guard let host else {
      completion(.failure(.io("Aucune fenêtre")))
      return
    }
    imagesCompletion = completion
    var configuration = PHPickerConfiguration()
    configuration.filter = .images
    configuration.selectionLimit = 10
    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = self
    picker.isModalInPresentation = true
    present(picker, from: host) { [weak self] in
      self?.finishImages(.failure(.io(Self.presentationFailure)))
    }
  }

  /// Encode hors du thread principal, répond sur le thread principal. Tout ou rien :
  /// si une écriture échoue, les JPEG déjà écrits sont supprimés.
  private func write(_ images: [UIImage]) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      var paths: [String] = []
      let outcome: Result<[String], PhotoSharingError>
      do {
        for image in images { paths.append(try PhotoSharingImages.write(image)) }
        outcome = .success(paths)
      } catch {
        PhotoSharingImages.discard(paths)
        outcome = .failure(Self.failure(error))
      }
      DispatchQueue.main.async { self?.finishImages(outcome) }
    }
  }

  private static func failure(_ error: Error) -> PhotoSharingError {
    error as? PhotoSharingError ?? .io(error.localizedDescription)
  }

  private func finishImages(_ outcome: Result<[String], PhotoSharingError>) {
    let completion = imagesCompletion
    imagesCompletion = nil
    completion?(outcome)
  }

  // MARK: - Messages

  /// Une feuille Messages par numéro, la suivante après la fermeture de la précédente.
  func sendMessages(
    phones: [String], photoPaths: [String], body: String,
    completion: @escaping (Result<[String: Int], PhotoSharingError>) -> Void
  ) {
    guard MFMessageComposeViewController.canSendText() else {
      completion(.failure(.messagesUnavailable))
      return
    }
    do {
      attachments = try photoPaths.map { try Data(contentsOf: URL(fileURLWithPath: $0)) }
    } catch {
      completion(.failure(.io(error.localizedDescription)))
      return
    }
    pendingPhones = phones
    messageBody = body
    tally = Tally()
    messagesCompletion = completion
    presentNextMessage()
  }

  private func presentNextMessage() {
    guard !pendingPhones.isEmpty else {
      finishMessages()
      return
    }
    guard let host else {
      tally.failed += pendingPhones.count
      pendingPhones = []
      finishMessages()
      return
    }
    let composer = MFMessageComposeViewController()
    composer.messageComposeDelegate = self
    composer.recipients = [pendingPhones.removeFirst()]
    composer.body = messageBody.isEmpty ? nil : messageBody
    composer.isModalInPresentation = true
    if MFMessageComposeViewController.canSendAttachments() {
      for (index, data) in attachments.enumerated() {
        let attached = composer.addAttachmentData(
          data, typeIdentifier: UTType.jpeg.identifier, filename: "photo-\(index + 1).jpg")
        if !attached {
          os_log("Photo %ld non jointe au message", type: .error, index + 1)
        }
      }
    } else if !attachments.isEmpty {
      os_log("Messages refuse les pièces jointes : photos non jointes", type: .error)
    }
    present(composer, from: host) { [weak self] in
      guard let self else { return }
      // La personne courante et les suivantes ne recevront rien.
      tally.failed += 1 + pendingPhones.count
      pendingPhones = []
      finishMessages()
    }
  }

  private func finishMessages() {
    let completion = messagesCompletion
    messagesCompletion = nil
    attachments = []
    completion?(
      .success(["sent": tally.sent, "cancelled": tally.cancelled, "failed": tally.failed]))
  }
}

extension PhotoSharingPresenter: CNContactPickerDelegate {
  func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    finishContact(contact, phone: contact.phoneNumbers.first?.value.stringValue)
  }

  func contactPicker(
    _ picker: CNContactPickerViewController, didSelect contactProperty: CNContactProperty
  ) {
    finishContact(
      contactProperty.contact, phone: (contactProperty.value as? CNPhoneNumber)?.stringValue)
  }

  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    let completion = contactCompletion
    contactCompletion = nil
    completion?(.success(nil))
  }
}

extension PhotoSharingPresenter: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    let image = info[.originalImage] as? UIImage
    picker.dismiss(animated: true) { [weak self] in
      guard let image else {
        self?.finishImages(.success([]))
        return
      }
      self?.write([image])
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true) { [weak self] in self?.finishImages(.success([])) }
  }
}

extension PhotoSharingPresenter: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true)
    guard !results.isEmpty else {
      finishImages(.success([]))
      return
    }
    // Fichier réduit à la lecture (ImageIO), jamais d'image pleine résolution en mémoire.
    // Ordre de sélection conservé ; chemins et erreurs rangés sur le thread principal.
    let type = UTType.image.identifier
    var paths = [String?](repeating: nil, count: results.count)
    var errors: [PhotoSharingError] = []
    let group = DispatchGroup()
    for (index, result) in results.enumerated() {
      guard result.itemProvider.hasItemConformingToTypeIdentifier(type) else {
        errors.append(.io("Format non pris en charge"))
        continue
      }
      group.enter()
      result.itemProvider.loadFileRepresentation(forTypeIdentifier: type) { url, error in
        // Synchrone : le fichier temporaire est supprimé au retour du bloc.
        let outcome: Result<String, PhotoSharingError>
        if let url {
          do {
            outcome = .success(try PhotoSharingImages.write(fileAt: url))
          } catch {
            outcome = .failure(Self.failure(error))
          }
        } else {
          outcome = .failure(.io(error?.localizedDescription ?? "Photo illisible"))
        }
        DispatchQueue.main.async {
          switch outcome {
          case .success(let path): paths[index] = path
          case .failure(let error): errors.append(error)
          }
          group.leave()
        }
      }
    }
    group.notify(queue: .main) { [weak self] in
      let written = paths.compactMap { $0 }
      if written.isEmpty, let error = errors.first {
        self?.finishImages(.failure(error))
      } else {
        self?.finishImages(.success(written))
      }
    }
  }
}

extension PhotoSharingPresenter: MFMessageComposeViewControllerDelegate {
  func messageComposeViewController(
    _ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult
  ) {
    switch result {
    case .sent: tally.sent += 1
    case .cancelled: tally.cancelled += 1
    default: tally.failed += 1
    }
    controller.dismiss(animated: true) { [weak self] in self?.presentNextMessage() }
  }
}
