//
//  WS_NativeAd9.swift
//  WebScanner
//
//  Created by Parthiv Akbari on 17/10/25.
//

import Foundation
import ShimmerSwift
import SwiftUI

typealias SM_NativeAd9 = WS_NativeAd9
typealias TR_NativeAd9 = WS_NativeAd9

struct WS_NativeAd9: View {
    @StateObject private var nativeViewModel = WS_NativeAdViewModel()
    @AppStorage(WSAPP_SessionKeys.isPro) var isPro = false
    @State var hasLoadedOnce = false
    
    var body: some View {
        VStack {
            if !isPro {
                if let _ = nativeViewModel.secondNativeAd {
                    WS_NativeAd9Container(nativeViewModel: nativeViewModel)
                        .frame(height: isIpad() ? 240 : 210)
                        .background(Color.white.opacity(0.50))
                        .cornerRadius(8)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.3), value: nativeViewModel.secondNativeAd)
                } else if nativeViewModel.didFailToSecondLoad {
                    Color.clear
                        .frame(height: 0)
                        .animation(.easeOut(duration: 0.3), value: nativeViewModel.didFailToSecondLoad)
                } else {
                    WS_ShimmerPlaceholderView()
                        .frame(height: isIpad() ? 240 : 210)
                        .padding(.horizontal, 8)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: nativeViewModel.secondNativeAd)
                }
            }
        }
        .onAppear {
            if !hasLoadedOnce {
                nativeViewModel.refreshSecondNative()
                hasLoadedOnce = true
            }
        }
    }
}

private struct WS_NativeAd9Container: UIViewRepresentable {
    typealias UIViewType = WS_GoogleNativeAdsCustomView9
    
    @ObservedObject var nativeViewModel: WS_NativeAdViewModel
    
    func makeUIView(context: Context) -> WS_GoogleNativeAdsCustomView9 {
        return WS_GoogleNativeAdsCustomView9.instanceFromNib() as! WS_GoogleNativeAdsCustomView9
    }
    
    func updateUIView(_ nativeAdView: WS_GoogleNativeAdsCustomView9, context: Context) {
        guard let nativeAd = nativeViewModel.secondNativeAd else { return }
        
        nativeAdView.nativeAd = nativeAd
        nativeAdView.setup()
    }
}

