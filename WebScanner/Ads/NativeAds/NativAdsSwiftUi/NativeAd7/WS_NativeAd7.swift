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
        VStack {
            if !isPro {
                if let _ = nativeViewModel.nativeAd {
                    WS_NativeAd7Container(nativeViewModel: nativeViewModel)
                        .frame(height: isIpad() ? 240 : 210)
                        .background(Color.white.opacity(0.50))
                        .cornerRadius(8)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.3), value: nativeViewModel.nativeAd)
                } else {
                    EmptyView()
                }
            }
        }
        .onAppear {
            if !hasLoadedOnce {
                nativeViewModel.refreshAd()
                hasLoadedOnce = true
            }
        }
    }
}

struct WS_ShimmerPlaceholderView: UIViewRepresentable {
    func makeUIView(context: Context) -> ShimmeringView {
        let shimmerView = ShimmeringView()
        shimmerView.frame = .zero
        shimmerView.isShimmering = true
        
        let content = UIView()
        content.backgroundColor = hexStringToUIColor(hex: "#BDBDBD")
        content.alpha = 0.5
        content.layer.cornerRadius = 8
        
        shimmerView.contentView = content
        
        return shimmerView
    }

    func updateUIView(_ uiView: ShimmeringView, context: Context) {
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

