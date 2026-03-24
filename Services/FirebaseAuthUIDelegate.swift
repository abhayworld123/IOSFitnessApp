import Foundation
import UIKit
import FirebaseAuth

/// Presents Firebase Auth UI (e.g. reCAPTCHA) for phone verification when needed.
final class FirebaseAuthUIDelegate: NSObject, AuthUIDelegate {
    private weak var viewController: UIViewController?

    init(viewController: UIViewController?) {
        self.viewController = viewController
    }

    func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        viewController?.present(viewControllerToPresent, animated: flag, completion: completion)
    }

    func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        viewController?.dismiss(animated: flag, completion: completion)
    }
}
