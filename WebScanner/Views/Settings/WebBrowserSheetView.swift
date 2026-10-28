//
//  WebBrowserSheetView.swift
//  WebScanner
//
//

import SwiftUI
import WebKit

public struct WebBrowserSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    public let title: String
    public let url: URL
    
    @State private var isLoading: Bool = true
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(title: String, url: URL) {
        self.title = title
        self.url = url
    }
    
    public var body: some View {
        GeometryReader { geo in
            let horizontalPadding: CGFloat = isIPad ? 28 : 18.scaled
            
            VStack(spacing: 0) {
                HStack {
                    Text(title)
                        .font(.inter(.bold, size: isIPad ? 20 : 17.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button(action: {
                        HapticFeedback.generate(.light)
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: isIPad ? 17 : 14.scaled, weight: .bold))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            .frame(width: isIPad ? 36 : 30.scaled, height: isIPad ? 36 : 30.scaled)
                            .background(
                                Circle()
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.top, isIPad ? 18 : 14.scaled)
                .padding(.bottom, isIPad ? 14 : 10.scaled)
                .background(AppColors.background(for: colorScheme))
                
                Divider()
                    .opacity(0.5)
                
                ZStack {
                    WebBrowserRepresentable(url: url, isLoading: $isLoading)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    if isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(isIPad ? 1.4 : 1.1)
                            
                            Text("Loading...".localized)
                                .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                                .foregroundColor(AppColors.textSecondary(for: colorScheme))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(AppColors.background(for: colorScheme).opacity(0.9))
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .background(AppColors.background(for: colorScheme))
        }
    }
}

// MARK: - WKWebView Representable
private struct WebBrowserRepresentable: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let makeUI = WKWebViewConfiguration()
        makeUI.allowsInlineMediaPlayback = true
        
        let webView = WKWebView(frame: .zero, configuration: makeUI)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 12)
        webView.load(request)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebBrowserRepresentable
        private var hasLoadedFallback: Bool = false
        
        init(_ parent: WebBrowserRepresentable) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleFailure(webView: webView)
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleFailure(webView: webView)
        }
        
        private func handleFailure(webView: WKWebView) {
            DispatchQueue.main.async {
                if !self.hasLoadedFallback,
                   self.parent.url.absoluteString.contains("eula") {
                    self.hasLoadedFallback = true
                    if let fallbackURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        webView.load(URLRequest(url: fallbackURL))
                        return
                    }
                }
                self.parent.isLoading = false
            }
        }
    }
}
