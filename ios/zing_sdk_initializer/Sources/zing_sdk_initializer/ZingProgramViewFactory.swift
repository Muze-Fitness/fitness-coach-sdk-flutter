import Flutter
import UIKit
import ZingCoachSDK

final class ZingProgramViewFactory: NSObject, FlutterPlatformViewFactory {
    static let viewType = "zing_sdk_initializer/program_view"

    private weak var plugin: ZingSdkInitializerPlugin?

    init(plugin: ZingSdkInitializerPlugin) {
        self.plugin = plugin
        super.init()
    }

    func createArgsCodec() -> (any FlutterMessageCodec & NSObjectProtocol) {
        FlutterStandardMessageCodec.sharedInstance()
    }

    @MainActor
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> any FlutterPlatformView {
        ZingProgramPlatformView(
            frame: frame,
            viewController: plugin.flatMap {
                try? $0.makeProgramViewController(configuration: .init(arguments: args))
            }
        )
    }
}

final class ZingProgramPlatformView: NSObject, FlutterPlatformView {
    private let containerView: UIView
    private let viewController: UIViewController?

    @MainActor
    init(frame: CGRect, viewController: UIViewController?) {
        self.containerView = UIView(frame: frame)
        self.viewController = viewController
        super.init()

        guard
            let viewController,
            let parent = UIApplication.shared.currentScene?.keyWindow?.rootViewController
        else {
            return
        }

        parent.addChild(viewController)
        viewController.view.frame = containerView.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        containerView.addSubview(viewController.view)
        viewController.didMove(toParent: parent)
    }

    deinit {
        guard
            let viewController,
            viewController.parent != nil
        else {
            return
        }
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }

    func view() -> UIView {
        containerView
    }
}

extension ZingSDK.ProgramScreenConfiguration {
    init(arguments: Any?) {
        let args = arguments as? [String: Any] ?? [:]
        self.init(
            showCloseButton: args["showCloseButton"] as? Bool ?? false,
            showAskCoachButton: args["showAskCoachButton"] as? Bool ?? true
        )
    }
}
