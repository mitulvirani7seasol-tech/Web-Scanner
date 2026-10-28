//
//  WS_NativeAd6.swift
//  WebScanner
//
//

import Foundation
import SwiftUI

typealias SM_NativeAd6 = WS_NativeAd6
typealias TR_NativeAd6 = WS_NativeAd6

struct WS_NativeAd6: View {
    @StateObject private var nativeViewModel = WS_NativeAdViewModel()
    @AppStorage(WSAPP_SessionKeys.isPro) var isPro = false
    @State var hasLoadedOnce = false

    var body: some View {
        let isUserPro = isPro || UserDefaults.standard.bool(forKey: WS_SessionKeys.isPro)
        VStack(spacing: 0) {
            if !isUserPro {
                if let _ = nativeViewModel.smallNativeAd {
                    WS_NativeAd6Container(nativeViewModel: nativeViewModel)
                        .frame(height: isIpad() ? 110 : 95)
                        .background(Color.white.opacity(0.50))
                        .cornerRadius(8)
                        .transition(.opacity)
                } else if nativeViewModel.didFailToSmallLoad {
                    Color.clear
                        .frame(height: 0)
                } else {
                    WS_ShimmerPlaceholderView()
                        .frame(height: isIpad() ? 110 : 95)
                        .padding(.horizontal, 8)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.35), value: nativeViewModel.smallNativeAd != nil)
        .animation(.easeOut(duration: 0.3), value: nativeViewModel.didFailToSmallLoad)
        .onAppear {
            let isUserPro = isPro || UserDefaults.standard.bool(forKey: WS_SessionKeys.isPro)
            guard !isUserPro else { return }
            if !hasLoadedOnce {
                nativeViewModel.refreshSmallNative()
                hasLoadedOnce = true
            }
        }
    }
    
    private func refreshAd() {
        nativeViewModel.refreshSmallNative()
    }
}

private struct WS_NativeAd6Container: UIViewRepresentable {
    typealias UIViewType = WS_GoogleNativeAdsCustomView6
    
    @ObservedObject var nativeViewModel: WS_NativeAdViewModel
    
    func makeUIView(context: Context) -> WS_GoogleNativeAdsCustomView6 {
        return WS_GoogleNativeAdsCustomView6.instanceFromNib()
    }
    
    func updateUIView(_ nativeAdView: WS_GoogleNativeAdsCustomView6, context: Context) {
        guard let nativeAd = nativeViewModel.smallNativeAd else { return }
        
        nativeAdView.nativeAd = nativeAd
        nativeAdView.setup()
    }
}
