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
        VStack {
            if !isPro {
                if let _ = nativeViewModel.smallNativeAd {
                    WS_NativeAd6Container(nativeViewModel: nativeViewModel)
                        .frame(height: isIpad() ? 110 : 95)
                        .background(Color.white.opacity(0.50))
                        .cornerRadius(8)
                } else if nativeViewModel.didFailToSmallLoad {
                    Color.clear
                        .frame(height: 0)
                        .animation(.easeOut(duration: 0.3), value: nativeViewModel.didFailToSmallLoad)
                } else {
                    WS_ShimmerPlaceholderView()
                        .frame(height: isIpad() ? 110 : 82)
                        .padding(.horizontal, 8)
                }
            }
        }
        .onAppear {
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
