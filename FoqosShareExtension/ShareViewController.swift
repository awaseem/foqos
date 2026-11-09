import UIKit
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
  private var hasHandledShare = false

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    guard !hasHandledShare else { return }
    hasHandledShare = true

    Task { @MainActor in
      guard let domain = await sharedDomain() else {
        showMessage(title: "No website found", message: "Share a web page to add it to Foqos.")
        return
      }
      chooseProfile(for: domain)
    }
  }

  private func sharedDomain() async -> String? {
    let providers =
      (extensionContext?.inputItems as? [NSExtensionItem])?
      .flatMap { $0.attachments ?? [] } ?? []

    for provider in providers
    where provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
      if let item = try? await provider.loadItem(forTypeIdentifier: UTType.url.identifier),
        let url = item as? URL,
        let domain = SharedDomainQueue.domain(from: url)
      {
        return domain
      }
    }

    for provider in providers
    where provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
      if let item = try? await provider.loadItem(forTypeIdentifier: UTType.plainText.identifier),
        let text = item as? String,
        let domain = SharedDomainQueue.domain(fromText: text)
      {
        return domain
      }
    }

    return nil
  }

  private func chooseProfile(for domain: String) {
    let choices = SharedDomainQueue.choices

    guard !choices.isEmpty else {
      showMessage(
        title: "Open Foqos first",
        message: "Open Foqos once so it can list profiles that accept shared websites.")
      return
    }

    if let activeId = SharedDomainQueue.activeProfileId,
      let active = choices.first(where: { $0.id == activeId })
    {
      add(domain, to: active)
      return
    }

    if choices.count == 1, let only = choices.first {
      add(domain, to: only)
      return
    }

    let sheet = UIAlertController(
      title: "Block \(domain)",
      message: "Choose a profile",
      preferredStyle: .actionSheet
    )
    for choice in choices {
      sheet.addAction(
        UIAlertAction(title: choice.name, style: .default) { _ in
          self.add(domain, to: choice)
        })
    }
    sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in self.finish() })
    sheet.popoverPresentationController?.sourceView = view
    sheet.popoverPresentationController?.sourceRect = CGRect(
      x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
    present(sheet, animated: true)
  }

  private func add(_ domain: String, to choice: ShareProfileChoice) {
    SharedDomainQueue.enqueue(domain: domain, profileId: choice.id)
    showMessage(
      title: "Added \(domain)",
      message: "It will be blocked in \(choice.name) next time Foqos opens.")
  }

  private func showMessage(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in self.finish() })
    present(alert, animated: true)
  }

  private func finish() {
    extensionContext?.completeRequest(returningItems: nil)
  }
}
