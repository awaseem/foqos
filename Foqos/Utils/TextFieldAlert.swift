import SwiftUI
import UIKit

struct TextFieldAlert: UIViewControllerRepresentable {
  @Binding var isPresented: Bool
  var title: String
  var message: String?
  @Binding var text: String
  var placeholder: String
  var confirmTitle: String = "Create"
  var cancelTitle: String = "Cancel"
  var onConfirm: (String) -> Void

  func makeUIViewController(context: Context) -> UIViewController {
    UIViewController()
  }

  func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    guard isPresented, uiViewController.presentedViewController == nil else { return }

    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addTextField { textField in
      textField.placeholder = placeholder
      textField.text = text
      textField.clearButtonMode = .whileEditing
      textField.returnKeyType = .done
    }

    let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel) { _ in
      isPresented = false
    }
    alert.addAction(cancelAction)

    let confirmAction = UIAlertAction(title: confirmTitle, style: .default) { _ in
      let value = alert.textFields?.first?.text ?? ""
      text = value
      onConfirm(value)
      isPresented = false
    }
    alert.addAction(confirmAction)

    uiViewController.present(alert, animated: true)
  }
}
