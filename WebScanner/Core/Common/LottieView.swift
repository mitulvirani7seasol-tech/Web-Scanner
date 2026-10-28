//
//  LottieView.swift
//  WebScanner
//

import SwiftUI
import Lottie

public struct LottieView: UIViewRepresentable {
    public let animationName: String
    public var loopMode: LottieLoopMode = .loop
    public var contentMode: UIView.ContentMode = .scaleAspectFit
    public var isDarkMode: Bool = false
    
    public init(
        animationName: String,
        loopMode: LottieLoopMode = .loop,
        contentMode: UIView.ContentMode = .scaleAspectFit,
        isDarkMode: Bool = false
    ) {
        self.animationName = animationName
        self.loopMode = loopMode
        self.contentMode = contentMode
        self.isDarkMode = isDarkMode
    }
    
    public func makeUIView(context: Context) -> LottieContainerView {
        let container = LottieContainerView()
        
        let animationView = LottieAnimationView()
        animationView.contentMode = contentMode
        animationView.loopMode = loopMode
        animationView.backgroundBehavior = .pauseAndRestore
        animationView.configuration = LottieConfiguration(renderingEngine: .mainThread)
        
        var loadedAnimation: LottieAnimation? = nil
        if let direct = LottieAnimation.named(animationName, bundle: .main) {
            loadedAnimation = direct
        } else if let path = Bundle.main.path(forResource: animationName, ofType: "json"),
                  let fromPath = LottieAnimation.filepath(path) {
            loadedAnimation = fromPath
        } else if let url = Bundle.main.url(forResource: animationName, withExtension: "json"),
                  let data = try? Data(contentsOf: url),
                  let fromData = try? LottieAnimation.from(data: data) {
            loadedAnimation = fromData
        } else if let subUrl = Bundle.main.url(forResource: animationName, withExtension: "json", subdirectory: "Loading Json"),
                  let data = try? Data(contentsOf: subUrl),
                  let fromData = try? LottieAnimation.from(data: data) {
            loadedAnimation = fromData
        }
        
        if let anim = loadedAnimation {
            animationView.animation = anim
            if isDarkMode {
                let whiteProvider = ColorValueProvider(LottieColor(r: 1.0, g: 1.0, b: 1.0, a: 1.0))
                animationView.setValueProvider(whiteProvider, keypath: AnimationKeypath(keypath: "**.Fill 1.Color"))
                animationView.setValueProvider(whiteProvider, keypath: AnimationKeypath(keypath: "**.Stroke 1.Color"))
            }
            container.setup(animationView: animationView)
        } else {
            container.setupFallbackSpinner(isDarkMode: isDarkMode)
        }
        
        return container
    }
    
    public func updateUIView(_ uiView: LottieContainerView, context: Context) {
        if let animationView = uiView.animationView {
            if isDarkMode {
                let whiteProvider = ColorValueProvider(LottieColor(r: 1.0, g: 1.0, b: 1.0, a: 1.0))
                animationView.setValueProvider(whiteProvider, keypath: AnimationKeypath(keypath: "**.Fill 1.Color"))
                animationView.setValueProvider(whiteProvider, keypath: AnimationKeypath(keypath: "**.Stroke 1.Color"))
            } else {
                animationView.removeValueProvider(for: AnimationKeypath(keypath: "**.Fill 1.Color"))
                animationView.removeValueProvider(for: AnimationKeypath(keypath: "**.Stroke 1.Color"))
            }
        }
        uiView.playIfNeeded()
    }
}

public final class LottieContainerView: UIView {
    public private(set) var animationView: LottieAnimationView?
    private var fallbackSpinner: UIActivityIndicatorView?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setup(animationView: LottieAnimationView) {
        self.animationView = animationView
        animationView.backgroundColor = .clear
        addSubview(animationView)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: trailingAnchor),
            animationView.topAnchor.constraint(equalTo: topAnchor),
            animationView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        animationView.play()
    }
    
    public func setupFallbackSpinner(isDarkMode: Bool = false) {
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.color = isDarkMode ? .white : UIColor(red: 0.09, green: 0.68, blue: 0.38, alpha: 1.0)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        addSubview(spinner)
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        self.fallbackSpinner = spinner
    }
    
    public func playIfNeeded() {
        if let animationView = animationView, !animationView.isAnimationPlaying {
            animationView.play()
        }
        if let spinner = fallbackSpinner, !spinner.isAnimating {
            spinner.startAnimating()
        }
    }
    
    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            playIfNeeded()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        playIfNeeded()
    }
}
