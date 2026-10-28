//
//  GlassCardModifier.swift
//  WebScanner
//

import SwiftUI
import UIKit
import LinkPresentation

// MARK: - Custom Rounded Corners Shape
public struct CustomRoundedCorners: Shape {
    public var radius: CGFloat = 30
    public var corners: UIRectCorner = [.topLeft, .topRight]

    public init(radius: CGFloat = 30, corners: UIRectCorner = [.topLeft, .topRight]) {
        self.radius = radius
        self.corners = corners
    }

    public func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - View Extensions
extension View {
    func glassModifier(
        cornerRadius: CGFloat = 30,
        color: Color = Color(.clear)
    ) -> some View {
        modifier(
            GlassModifier(
                cornerRadius: cornerRadius,
                color: color
            )
        )
    }
    
    func glassCard(
        cornerRadius: CGFloat = 30,
        color: Color = Color(.clear),
        isInteractive: Bool = true
    ) -> some View {
        modifier(
            GlassModifier(
                cornerRadius: cornerRadius,
                color: color
            )
        )
    }
    
    func glassTabBarModifier(
        cornerRadius: CGFloat = 30,
        color: Color = Color.clear
    ) -> some View {
        modifier(
            GlassTabBarModifier(
                cornerRadius: cornerRadius,
                color: color
            )
        )
    }
    
    func glassShape<S: Shape>(
        _ shape: S,
        color: Color = Color.clear,
        isInteractive: Bool = true
    ) -> some View {
        modifier(
            GlassShapeModifier(
                shape: shape,
                color: color,
                isInteractive: isInteractive
            )
        )
    }
}

// MARK: - iOS Default Liquid Glass TR_Tab Bar Modifier (Apple Native Ultra Thin Material)
public struct GlassTabBarModifier: ViewModifier {
    var cornerRadius: CGFloat = 30
    var color: Color = Color.clear
    
    public init(cornerRadius: CGFloat = 30, color: Color = Color.clear) {
        self.cornerRadius = cornerRadius
        self.color = color
    }
    
    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(color)
                .glassEffect(
                    .clear.interactive(),
                    in: RoundedRectangle(cornerRadius: cornerRadius)
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.65), location: 0.0),
                                    .init(color: Color.white.opacity(0.15), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
        } else {
            content
                .background(color)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.70),
                                    Color.white.opacity(0.20)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Glass Back Button Component
public struct GlassBackButton: View {
    public var size: CGFloat
    public var iconSize: CGFloat
    public var action: () -> Void
    
    public init(
        size: CGFloat = 40,
        iconSize: CGFloat = 16,
        action: @escaping () -> Void
    ) {
        self.size = size
        self.iconSize = iconSize
        self.action = action
    }
    
    public init(
        isIPad: Bool,
        action: @escaping () -> Void
    ) {
        self.size = isIPad ? 46 : 40
        self.iconSize = isIPad ? 19 : 16
        self.action = action
    }
    
    public init(
        size: CGFloat,
        isIPad: Bool,
        action: @escaping () -> Void
    ) {
        self.size = size
        self.iconSize = isIPad ? 20 : 16
        self.action = action
    }
    
    public var body: some View {
        Button(action: {
            HapticFeedback.generate(.light)
            action()
        }) {
            ZStack {
                Image(systemName: "arrow.left")
                    .font(.system(size: iconSize, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "8E03A1"), Color(hex: "E25F89")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .frame(width: size, height: size)
            .glassModifier(cornerRadius: size / 2)
            .overlay(
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.85), Color.white.opacity(0.35)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.92))
        .contentShape(Circle())
    }
}

// MARK: - Interactive Scale Button Style (Scale + Liquid Glass Brightness + Haptic on Press)
struct ScaleButtonStyle: ButtonStyle {
    var scaleAmount: CGFloat = 0.94
    var opacityAmount: CGFloat = 0.88
    var brightnessAmount: Double = 0.08

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .opacity(configuration.isPressed ? opacityAmount : 1.0)
            .brightness(configuration.isPressed ? brightnessAmount : 0.0)
            .animation(.spring(response: 0.20, dampingFraction: 0.68), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { isPressed in
                if isPressed {
                    HapticFeedback.generate(.light)
                }
            }
    }
}

// MARK: - Glass Modifier
struct GlassModifier: ViewModifier {
    var cornerRadius: CGFloat = 30
    var color: Color = Color(.clear)

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(color)
                .cornerRadius(cornerRadius)
                .glassEffect(
                    .clear.interactive(),
                    in: RoundedRectangle(cornerRadius: cornerRadius)
                )
        } else {
            content
                .background(color)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color.white.opacity(0.18))
                )
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.70),
                                    Color.white.opacity(0.20)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        }
    }
}

// MARK: - Glass Shape Modifier
public struct GlassShapeModifier<S: Shape>: ViewModifier {
    var shape: S
    var color: Color = Color.clear
    var isInteractive: Bool = true

    public init(shape: S, color: Color = Color.clear, isInteractive: Bool = true) {
        self.shape = shape
        self.color = color
        self.isInteractive = isInteractive
    }

    public func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .background(color)
                .glassEffect(
                    isInteractive ? .clear.interactive() : .clear,
                    in: shape
                )
                .clipShape(shape)
                .overlay(
                    shape.stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.85),
                                Color.white.opacity(0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
                )
        } else {
            content
                .background(color)
                .background(
                    shape.fill(Color.white.opacity(0.18))
                )
                .clipShape(shape)
                .overlay(
                    shape.stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.70),
                                Color.white.opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
                )
        }
    }
}

// MARK: - Backward Compatibility Alias
typealias WS_GlassCardModifier = GlassModifier

// MARK: - TR_Blur Component
struct TR_Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemMaterialLight
    func makeUIView(context: Context) -> UIVisualEffectView {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: style))
        view.isUserInteractionEnabled = false
        return view
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

// MARK: - Reusable Share Sheet Component
public struct ShareTextItem: Identifiable {
    public let id = UUID()
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
}

// MARK: - Activity Item Source with Instant LinkPresentation Metadata
public final class StatusShareActivityItemSource: NSObject, UIActivityItemSource {
    public let item: Any
    public let title: String
    public let thumbnail: UIImage?

    public init(item: Any, title: String = "Status", thumbnail: UIImage? = nil) {
        self.item = item
        self.title = title
        self.thumbnail = thumbnail
        super.init()
    }

    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return item
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return item
    }

    public func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = title
        if let thumb = thumbnail {
            metadata.imageProvider = NSItemProvider(object: thumb)
            metadata.iconProvider = NSItemProvider(object: thumb)
        } else if let img = item as? UIImage {
            metadata.imageProvider = NSItemProvider(object: img)
            metadata.iconProvider = NSItemProvider(object: img)
        }
        return metadata
    }
}

public struct ShareHelper {
    public static func share(items: [Any], from sourceView: UIView? = nil) {
        guard !items.isEmpty else { return }
        
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive })
                ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first else {
                return
            }
            
            guard let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first,
                  let rootVC = keyWindow.rootViewController else {
                return
            }
            
            var topVC = rootVC
            while let presented = topVC.presentedViewController, !presented.isBeingDismissed {
                topVC = presented
            }
            
            let preparedItems: [Any] = items.map { item in
                if item is UIActivityItemSource {
                    return item
                } else if let image = item as? UIImage {
                    return StatusShareActivityItemSource(item: image, title: "Status Photo", thumbnail: image)
                } else if let url = item as? URL {
                    let isVideo = url.pathExtension.lowercased() == "mp4" || url.pathExtension.lowercased() == "mov"
                    return StatusShareActivityItemSource(item: url, title: isVideo ? "Status Video" : "Status Media")
                } else {
                    return item
                }
            }
            
            let activityVC = UIActivityViewController(activityItems: preparedItems, applicationActivities: nil)
            
            if let popover = activityVC.popoverPresentationController {
                let targetView = sourceView ?? topVC.view ?? keyWindow
                popover.sourceView = targetView
                let bounds = targetView.bounds
                if let source = sourceView {
                    popover.sourceRect = source.bounds
                    popover.permittedArrowDirections = .any
                } else {
                    // Position in center with non-zero dimensions to avoid blank popover bug on iPad
                    popover.sourceRect = CGRect(x: bounds.midX - 50, y: bounds.midY - 50, width: 100, height: 100)
                    popover.permittedArrowDirections = []
                }
            }
            
            topVC.present(activityVC, animated: true)
        }
    }
}

public struct WS_ShareSheet: UIViewControllerRepresentable {
    public var activityItems: [Any]
    public var applicationActivities: [UIActivity]? = nil
    public var excludedActivityTypes: [UIActivity.ActivityType]? = nil
    public var callback: UIActivityViewController.CompletionWithItemsHandler? = nil

    public init(
        activityItems: [Any],
        applicationActivities: [UIActivity]? = nil,
        excludedActivityTypes: [UIActivity.ActivityType]? = nil,
        callback: UIActivityViewController.CompletionWithItemsHandler? = nil
    ) {
        self.activityItems = activityItems
        self.applicationActivities = applicationActivities
        self.excludedActivityTypes = excludedActivityTypes
        self.callback = callback
    }

    public func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        controller.excludedActivityTypes = excludedActivityTypes
        controller.completionWithItemsHandler = callback
        return controller
    }

    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Sheet Helper Extension
extension View {
    @ViewBuilder
    public func sheetCornerRadius(_ radius: CGFloat) -> some View {
        if #available(iOS 16.4, *) {
            self.presentationCornerRadius(radius)
        } else {
            self
        }
    }
}

// MARK: - Haptic Feedback Helper
public struct HapticFeedback {
    public enum FeedbackType {
        case light
        case medium
        case heavy
        case selection
        case success
        case warning
        case error
    }
    
    public static func generate(_ type: FeedbackType) {
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.prepare()
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.prepare()
            generator.impactOccurred()
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
            generator.selectionChanged()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
            generator.notificationOccurred(.error)
        }
    }
}

// MARK: - Native Swipe Back Extension
public struct EnableSwipeBackModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(SwipeBackEnablerView())
    }
}

private struct SwipeBackEnablerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            if let nav = vc.navigationController {
                nav.interactivePopGestureRecognizer?.isEnabled = true
                nav.interactivePopGestureRecognizer?.delegate = nav
            }
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        DispatchQueue.main.async {
            if let nav = uiViewController.navigationController {
                nav.interactivePopGestureRecognizer?.isEnabled = true
                nav.interactivePopGestureRecognizer?.delegate = nav
            }
        }
    }
}

extension View {
    public func enableNativeSwipeBack() -> some View {
        self.modifier(EnableSwipeBackModifier())
    }
}

extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return viewControllers.count > 1
    }
}

// MARK: - Dismiss Keyboard On Outside Tap
extension View {
    public func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    public func dismissKeyboardOnOutsideTap() -> some View {
        self.background(
            DismissKeyboardOverlayView()
        )
    }
}

public struct DismissKeyboardOverlayView: UIViewRepresentable {
    public init() {}
    
    public func makeUIView(context: Context) -> UIView {
        let view = DismissKeyboardUIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        return view
    }
    
    public func updateUIView(_ uiView: UIView, context: Context) {}
}

final class DismissKeyboardUIView: UIView, UIGestureRecognizerDelegate {
    private weak var activeWindow: UIWindow?
    private var tapGesture: UITapGestureRecognizer?
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window = window {
            if tapGesture == nil {
                let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
                tap.cancelsTouchesInView = false
                tap.delegate = self
                window.addGestureRecognizer(tap)
                self.tapGesture = tap
                self.activeWindow = window
            }
        } else {
            removeTapGesture()
        }
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        removeTapGesture()
    }
    
    private func removeTapGesture() {
        if let tap = tapGesture {
            activeWindow?.removeGestureRecognizer(tap)
            tapGesture = nil
            activeWindow = nil
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var current: UIView? = touch.view
        while let c = current {
            if c is UITextField || c is UITextView {
                return false
            }
            current = c.superview
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}


