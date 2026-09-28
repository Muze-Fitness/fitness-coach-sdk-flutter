import UIKit
import DesignSystem
import ZingCoachSDK

struct FlutterTheme {
    let arguments: [String: Any]

    func build() -> DesignSystem.Theme {
        DesignSystem.Theme.default.byApplying(
            colorsTransform: colorsTransform(),
            cornersRoundingTransform: cornersRoundingTransform(),
            typographyTransform: typographyTransform(),
            assetsTransform: assetsTransform(),
            blurStyleTransform: blurStyleTransform()
        )
    }

    private func colorsTransform() -> Transform<ColorToken, UIColor>? {
        guard let rawColors = arguments["colors"] as? [String: Any] else {
            return nil
        }

        let colors = rawColors
            .filter { ColorToken(token: $0.key) != nil }
            .compactMapValues { ($0 as? Int).map(UIColor.init(argb:)) }

        guard !colors.isEmpty else { return nil }

        return { token, color in
            colors[token.token] ?? color
        }
    }

    private func cornersRoundingTransform() -> Transform<RadiusToken, RadiusAttribute>? {
        guard let rawCornersRounding = arguments["cornersRounding"] as? [String: Any] else {
            return nil
        }

        let cornersRounding = rawCornersRounding
            .compactMapValues { $0 as? [String: Any] }
            .filter { RadiusToken(token: $0.key) != nil }
            .compactMapValues(RadiusAttribute.init(entry:))

        guard !cornersRounding.isEmpty else { return nil }

        return { token, radius in
            cornersRounding[token.token] ?? radius
        }
    }

    private func typographyTransform() -> Transform<TypographyToken, TypographyAttributes>? {
        guard let rawTypography = arguments["typography"] as? [String: Any] else {
            return nil
        }

        let system = rawTypography["system"] as? String
        let brand = rawTypography["brand"] as? String
        guard system != nil || brand != nil else { return nil }

        return { token, attributes in
            let family: String? = switch token {
            case .heading(.h1),
                 .heading(.h2),
                 .heading(.h3),
                 .bodyBrand,
                 .counter,
                 .coach(.name):
                brand
            case .heading(.h4),
                 .heading(.h4Semi),
                 .bodySystem,
                 .coach(.chat),
                 .coach(.remark),
                 .ui:
                system
            }

            guard let family else { return attributes }
            var updated = attributes
            updated.fontFamily = family
            return updated
        }
    }

    private func assetsTransform() -> Transform<AssetToken, UIImage> {
        { token, image in
            UIImage(named: token.token) ?? image
        }
    }

    private func blurStyleTransform() -> Transform<BlurToken, UIBlurEffect.Style>? {
        guard
            let rawStyle = arguments["blurStyle"] as? String,
            let style = UIBlurEffect.Style(flutterName: rawStyle)
        else {
            return nil
        }

        return { _, _ in style }
    }
}

private extension UIBlurEffect.Style {
    init?(flutterName: String) {
        switch flutterName {
        case "extraLight":
            self = .extraLight
        case "light":
            self = .light
        case "dark":
            self = .dark
        case "regular":
            self = .regular
        case "prominent":
            self = .prominent
        case "systemUltraThinMaterial":
            self = .systemUltraThinMaterial
        case "systemThinMaterial":
            self = .systemThinMaterial
        case "systemMaterial":
            self = .systemMaterial
        case "systemThickMaterial":
            self = .systemThickMaterial
        case "systemChromeMaterial":
            self = .systemChromeMaterial
        case "systemUltraThinMaterialLight":
            self = .systemUltraThinMaterialLight
        case "systemThinMaterialLight":
            self = .systemThinMaterialLight
        case "systemMaterialLight":
            self = .systemMaterialLight
        case "systemThickMaterialLight":
            self = .systemThickMaterialLight
        case "systemChromeMaterialLight":
            self = .systemChromeMaterialLight
        case "systemUltraThinMaterialDark":
            self = .systemUltraThinMaterialDark
        case "systemThinMaterialDark":
            self = .systemThinMaterialDark
        case "systemMaterialDark":
            self = .systemMaterialDark
        case "systemThickMaterialDark":
            self = .systemThickMaterialDark
        case "systemChromeMaterialDark":
            self = .systemChromeMaterialDark
        default:
            return nil
        }
    }
}

private extension UIColor {
    convenience init(argb: Int) {
        let a = CGFloat((argb >> 24) & 0xFF) / 255.0
        let r = CGFloat((argb >> 16) & 0xFF) / 255.0
        let g = CGFloat((argb >> 8) & 0xFF) / 255.0
        let b = CGFloat(argb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
