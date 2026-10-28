//
//  WS_NativeAd7.swift
//  WebScanner
//
//

import Foundation
import ShimmerSwift
import SwiftUI

typealias SM_NativeAd7 = WS_NativeAd7
typealias TR_NativeAd7 = WS_NativeAd7
typealias SM_ShimmerPlaceholderView = WS_ShimmerPlaceholderView
typealias TR_ShimmerPlaceholderView = WS_ShimmerPlaceholderView

struct WS_NativeAd7: View {
    @StateObject private var nativeViewModel = WS_NativeAdViewModel()
    @AppStorage(WSAPP_SessionKeys.isPro) var isPro = false
    @State var hasLoadedOnce = false

    var body: some View {
        let isUserPro = isPro || UserDefaults.standard.bool(forKey: WS_SessionKeys.isPro)
        VStack(spacing: 0) {
            if !isUserPro {
                if let _ = nativeViewModel.nativeAd {
                    WS_NativeAd7Container(nativeViewModel: nativeViewModel)
                        .frame(height: isIpad() ? 240 : 210)
                        .background(Color.white.opacity(0.50))
                        .cornerRadius(8)
                        .transition(.opacity)
                } else if nativeViewModel.didFailToLoad {
                    Color.clear
                        .frame(height: 0)
                } else {
                    WS_ShimmerPlaceholderView()
                        .frame(height: isIpad() ? 240 : 210)
                        .padding(.horizontal, 8)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: nativeViewModel.nativeAd != nil)
        .animation(.easeOut(duration: 0.3), value: nativeViewModel.didFailToLoad)
        .onAppear {
            let isUserPro = isPro || UserDefaults.standard.bool(forKey: WS_SessionKeys.isPro)
            guard !isUserPro else { return }
            if !hasLoadedOnce {
                nativeViewModel.refreshAd()
                hasLoadedOnce = true
            }
        }
    }
}

final class WS_AdSkeletonContentView: UIView {
    private let cardBackground = UIView()
    private let iconPlaceholder = UIView()
    private let badgePlaceholder = UIView()
    private let headlinePlaceholder = UIView()
    private let bodyPlaceholder = UIView()
    private let bodyPlaceholder2 = UIView()
    private let mediaPlaceholder = UIView()
    private let ctaPlaceholder = UIView()
    
    private let itemColor = hexStringToUIColor(hex: "#D1D5DB")
    private let cardBgColor = hexStringToUIColor(hex: "#F3F4F6")
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        backgroundColor = .clear
        
        cardBackground.backgroundColor = cardBgColor
        cardBackground.layer.cornerRadius = 10
        cardBackground.clipsToBounds = true
        addSubview(cardBackground)
        
        let subviews = [iconPlaceholder, badgePlaceholder, headlinePlaceholder, bodyPlaceholder, bodyPlaceholder2, mediaPlaceholder, ctaPlaceholder]
        for v in subviews {
            v.backgroundColor = itemColor
            cardBackground.addSubview(v)
        }
        
        iconPlaceholder.layer.cornerRadius = 8
        badgePlaceholder.layer.cornerRadius = 3
        headlinePlaceholder.layer.cornerRadius = 4
        bodyPlaceholder.layer.cornerRadius = 3
        bodyPlaceholder2.layer.cornerRadius = 3
        mediaPlaceholder.layer.cornerRadius = 8
        ctaPlaceholder.layer.cornerRadius = 8
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cardBackground.frame = bounds
        let pad: CGFloat = 10
        let w = bounds.width - (pad * 2)
        let h = bounds.height
        
        guard w > 0, h > 0 else { return }
        
        if h > 150 {
            // Large Native Ad Layout (e.g. ~210 - 240pt)
            let iconSize: CGFloat = 40
            iconPlaceholder.frame = CGRect(x: pad, y: pad, width: iconSize, height: iconSize)
            
            let textX = iconPlaceholder.frame.maxX + 10
            let badgeW: CGFloat = 26
            let badgeH: CGFloat = 14
            badgePlaceholder.frame = CGRect(x: textX, y: pad + 2, width: badgeW, height: badgeH)
            
            let headW = max(60, (bounds.width - textX - badgeW - pad - 12) * 0.75)
            headlinePlaceholder.frame = CGRect(x: badgePlaceholder.frame.maxX + 6, y: pad + 2, width: headW, height: 14)
            
            let bodyW = max(80, (bounds.width - textX - pad) * 0.85)
            bodyPlaceholder.frame = CGRect(x: textX, y: headlinePlaceholder.frame.maxY + 8, width: bodyW, height: 10)
            bodyPlaceholder2.isHidden = true
            
            let ctaHeight: CGFloat = 36
            let mediaY = iconPlaceholder.frame.maxY + 10
            let mediaH = max(20, h - mediaY - ctaHeight - (pad * 2))
            mediaPlaceholder.isHidden = false
            mediaPlaceholder.frame = CGRect(x: pad, y: mediaY, width: w, height: mediaH)
            
            let ctaY = mediaPlaceholder.frame.maxY + 8
            ctaPlaceholder.frame = CGRect(x: pad, y: ctaY, width: w, height: ctaHeight)
            
        } else {
            // Small Native Ad Layout (e.g. ~82 - 110pt)
            mediaPlaceholder.isHidden = true
            
            let iconSize = min(60, max(44, h - (pad * 2)))
            iconPlaceholder.frame = CGRect(x: pad, y: (h - iconSize) / 2, width: iconSize, height: iconSize)
            
            let textX = iconPlaceholder.frame.maxX + 10
            let textW = max(50, bounds.width - textX - pad)
            
            let badgeW: CGFloat = 24
            let badgeH: CGFloat = 13
            badgePlaceholder.frame = CGRect(x: textX, y: pad + 2, width: badgeW, height: badgeH)
            
            let headW = max(40, textW - badgeW - 8) * 0.7
            headlinePlaceholder.frame = CGRect(x: badgePlaceholder.frame.maxX + 6, y: pad + 2, width: headW, height: 13)
            
            bodyPlaceholder.frame = CGRect(x: textX, y: headlinePlaceholder.frame.maxY + 6, width: textW * 0.85, height: 10)
            
            bodyPlaceholder2.isHidden = false
            bodyPlaceholder2.frame = CGRect(x: textX, y: bodyPlaceholder.frame.maxY + 4, width: textW * 0.5, height: 10)
            
            let ctaHeight: CGFloat = 24
            let ctaW: CGFloat = min(90, textW * 0.45)
            ctaPlaceholder.frame = CGRect(x: bounds.width - pad - ctaW, y: h - pad - ctaHeight, width: ctaW, height: ctaHeight)
            ctaPlaceholder.layer.cornerRadius = 6
        }
    }
}

struct WS_ShimmerPlaceholderView: UIViewRepresentable {
    func makeUIView(context: Context) -> ShimmeringView {
        let shimmerView = ShimmeringView()
        shimmerView.frame = .zero
        shimmerView.isShimmering = true
        shimmerView.shimmerSpeed = 260
        shimmerView.shimmerAnimationOpacity = 0.4
        shimmerView.shimmerOpacity = 1.0
        shimmerView.shimmerPauseDuration = 0.2
        
        let content = WS_AdSkeletonContentView()
        shimmerView.contentView = content
        
        return shimmerView
    }

    func updateUIView(_ uiView: ShimmeringView, context: Context) {
        uiView.isShimmering = true
    }
}

private struct WS_NativeAd7Container: UIViewRepresentable {
    typealias UIViewType = WS_GoogleNativeAdsCustomView7
    
    @ObservedObject var nativeViewModel: WS_NativeAdViewModel
    
    func makeUIView(context: Context) -> WS_GoogleNativeAdsCustomView7 {
        return WS_GoogleNativeAdsCustomView7.instanceFromNib()
    }
    
    func updateUIView(_ nativeAdView: WS_GoogleNativeAdsCustomView7, context: Context) {
        guard let nativeAd = nativeViewModel.nativeAd else { return }
        
        nativeAdView.nativeAd = nativeAd
        nativeAdView.setup()
    }
}

