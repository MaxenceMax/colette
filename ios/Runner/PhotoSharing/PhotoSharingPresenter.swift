import ContactsUI
import MessageUI
import PhotosUI
import UIKit

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
    while let presented = controller?.presentedViewController { controller = presented }
    return controller
  }

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
    host.present(picker, animated: true)
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
    host.present(picker, animated: true)
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
    host.present(picker, animated: true)
  }

  /// Encode hors du thread principal, répond sur le thread principal.
  private func write(_ images: [UIImage]) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      let outcome: Result<[String], PhotoSharingError>
      do {
        outcome = .success(try images.map(PhotoSharingImages.write))
      } catch let error as PhotoSharingError {
        outcome = .failure(error)
      } catch {
        outcome = .failure(.io(error.localizedDescription))
      }
      DispatchQueue.main.async { self?.finishImages(outcome) }
    }
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
    if MFMessageComposeViewController.canSendAttachments() {
      for (index, data) in attachments.enumerated() {
        _ = composer.addAttachmentData(
          data, typeIdentifier: "public.jpeg", filename: "photo-\(index + 1).jpg")
      }
    }
    host.present(composer, animated: true)
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
    // Ordre de sélection conservé ; chaque chargement répond sur le thread principal.
    var images = [UIImage?](repeating: nil, count: results.count)
    let group = DispatchGroup()
    for (index, result) in results.enumerated()
    where result.itemProvider.canLoadObject(ofClass: UIImage.self) {
      group.enter()
      result.itemProvider.loadObject(ofClass: UIImage.self) { object, _ in
        DispatchQueue.main.async {
          images[index] = object as? UIImage
          group.leave()
        }
      }
    }
    group.notify(queue: .main) { [weak self] in self?.write(images.compactMap { $0 }) }
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
