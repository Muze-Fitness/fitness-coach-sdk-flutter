import UIKit

extension UIViewController {
    var topPresentedViewController: UIViewController {
        presentedViewController.flatMap { $0.topPresentedViewController } ?? self
    }

    var topInNavigationController: UIViewController {
        (self as? UINavigationController)?.topViewController ?? self
    }
}

extension UIApplication {
    var currentScene: UIWindowScene? {
        connectedScenes.first { $0.activationState == .foregroundActive } as? UIWindowScene
    }
}
