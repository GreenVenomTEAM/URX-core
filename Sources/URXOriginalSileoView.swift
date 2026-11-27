import SwiftUI
import UIKit
import Sileo

/// Hosts the upstream Sileo storyboard inside URX Core.
/// The Sileo source is compiled as an embedded framework; no second app is launched.
struct URXOriginalSileoView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        guard let rootController = storyboard.instantiateInitialViewController() else {
            return SileoUnavailableViewController()
        }

        SileoEmbedBootstrap.prepare(rootController: rootController)
        return rootController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

private final class SileoUnavailableViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Sileo interface resources could not be loaded."
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            label.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
