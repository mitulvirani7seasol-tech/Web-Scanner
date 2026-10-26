//
//  WS_NativeAd5.swift
//  WebScanner
//
//

import Foundation
import SwiftUI

typealias SM_NativeAd5 = WS_NativeAd5
typealias TR_NativeAd5 = WS_NativeAd5

struct WS_NativeAd5: View {
    @StateObject private var nativeViewModel = WS_NativeAdViewModel()
    @AppStorage(WSAPP_SessionKeys.isPro) var isPro = false
    @State var hasLoadedOnce = false

    
    var body: some View {
        VStack {
            if !isPro {
                if let _ = nativeViewModel.secondSmallNativeAd {
                    WS_NativeAd5Container(nativeViewModel: nativeViewModel)
                        .frame(height: isIpad() ? 110 : 82)
                        .background(Color.white.opacity(0.50))
                        .cornerRadius(8)
                } else if nativeViewModel.didFailToSmallNativeLoad {
                    Color.clear
                        .frame(height: 0)
                        .animation(.easeOut(duration: 0.3), value: nativeViewModel.didFailToSmallNativeLoad)
                } else {
                    WS_ShimmerPlaceholderView()
                        .frame(height: isIpad() ? 110 : 82)
                        .padding(.horizontal, 8)
                }
            }
        }
        .onAppear {
            if !hasLoadedOnce {
                nativeViewModel.refreshSecondSmallNative()
                hasLoadedOnce = true
            }
        }
    }
    
    private func refreshAd() {
        nativeViewModel.refreshSecondSmallNative()
    }
}

private struct WS_NativeAd5Container: UIViewRepresentable {
    typealias UIViewType = WS_GoogleNativeAdsCustomView5
    
    @ObservedObject var nativeViewModel: WS_NativeAdViewModel
    
    func makeUIView(context: Context) -> WS_GoogleNativeAdsCustomView5 {
        return WS_GoogleNativeAdsCustomView5.instanceFromNib()
    }
    
    func updateUIView(_ nativeAdView: WS_GoogleNativeAdsCustomView5, context: Context) {
        guard let nativeAd = nativeViewModel.secondSmallNativeAd else { return }
        
        nativeAdView.nativeAd = nativeAd
        nativeAdView.setup()
    }
}
