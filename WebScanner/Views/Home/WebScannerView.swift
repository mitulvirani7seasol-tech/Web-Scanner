//
//  WebScannerView.swift
//  WebScanner
//

import SwiftUI
import WebKit

public struct WebScannerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var sessionAccount: AppAccount
    @State private var qrImage: UIImage? = nil
    @State private var isLoggedIn: Bool = false
    @State private var isLoading: Bool = true
    @State private var webView: WKWebView? = nil
    @AppStorage(WS_SessionKeys.isPro) var isPro = false
    @State private var showPaywall: Bool = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(existingAccount: AppAccount? = nil) {
        if let existing = existingAccount {
            _sessionAccount = State(initialValue: existing)
        } else {
            let count = AccountManager.shared.accounts.filter { $0.platform == .whatsApp }.count
            let newAccount = AppAccount(platform: .whatsApp, accountName: "WhatsApp - \(count + 1)", isSessionActive: false)
            _sessionAccount = State(initialValue: newAccount)
        }
        _isLoggedIn = State(initialValue: false)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if isLoggedIn {
                // MARK: - Active WhatsApp Web Header (Positioned above WebView, so top is NEVER cut off)
                loggedInHeader
            }
            
            ZStack(alignment: .top) {
                // MARK: - Live WKWebView
                WebScannerWKWebViewRepresentable(
                    account: sessionAccount,
                    webViewRef: $webView,
                    qrImage: $qrImage,
                    isLoggedIn: $isLoggedIn,
                    isLoading: $isLoading,
                    showPaywall: $showPaywall,
                    isPro: isPro
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(isLoggedIn ? 1.0 : 0.001)
                .allowsHitTesting(isLoggedIn)
                
                if !isLoggedIn {
                    // Background Image over WKWebView while waiting for QR scan
                    Image(colorScheme == .dark ? "BG_Dark" : "BG")
                        .resizable()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .ignoresSafeArea()
                    
                    // Not logged in: Show Native QR Code & Instructions View immediately
                    VStack(spacing: 0) {
                        headerBar
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: isIPad ? 40 : 22.scaled) {
                                // 1. Central Card: Real WhatsApp QR Code filled to frame
                                qrCard
                                
                                // 2. Instructions: "Use WhatsApp on your computer"
                                instructionsSection
                                
                                Spacer(minLength: 40)
                            }
                            .padding(.horizontal, isIPad ? 40 : 20.scaled)
                            .padding(.top, isIPad ? 18 : 10.scaled)
                            .frame(maxWidth: isIPad ? 580 : .infinity)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(colorScheme == .dark ? Color(hex: "#1A1A1A") : Color.white)
        .ignoresSafeArea(edges: isLoggedIn ? .bottom : .all)
        .navigationBarBackButtonHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
        }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            if !isPro {
                dismiss()
            } else {
                withAnimation(.easeInOut(duration: 0.35)) {
                    isLoggedIn = true
                    isLoading = false
                }
            }
        }) {
            PremiumPaywallView(isFromAppOpen: false) {
                showPaywall = false
                if !isPro {
                    dismiss()
                } else {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        isLoggedIn = true
                        isLoading = false
                    }
                }
            }
        }
        .onDisappear {
            if !isLoggedIn {
                // If user left without scanning QR, only remove unlinked temporary data stores
                let isSavedAccount = AccountManager.shared.accounts.contains(where: { $0.id == sessionAccount.id })
                if !isSavedAccount {
                    if #available(iOS 17.0, *) {
                        if let uuid = UUID(uuidString: sessionAccount.webDataStoreID) {
                            WKWebsiteDataStore.remove(forIdentifier: uuid) { _ in }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Header Bar (< Web Scanner [↻])
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text("Web Scanner".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 22))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
            
            Button(action: {
                refreshQRCode()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: isIPad ? 20 : 17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, isIPad ? 32 : 16)
        .padding(.top, isIPad ? 60 : 60)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Logged In Header Bar (Extends to top safe area without overlapping WebView)
    private var loggedInHeader: some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text("Web Scanner".localized)
                .font(.inter(.bold, size: isIPad ? 22 : 22))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
            
            Button(action: {
                HapticFeedback.generate(.light)
                webView?.reload()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: isIPad ? 20 : 17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, isIPad ? 32 : 16)
        .padding(.vertical, isIPad ? 12 : 8)
        .frame(maxWidth: .infinity)
        .background(
            (colorScheme == .dark ? Color(hex: "#1A1A1A") : Color.white)
                .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - Central QR Code Card (Filled to Frame)
    private var qrCard: some View {
        let cardSize: CGFloat = isIPad ? 440 : 290.scaled
        let padding: CGFloat = isIPad ? 16 : 12.scaled
        let qrSize: CGFloat = cardSize - (padding * 2)
        
        return ZStack {
            if let image = qrImage {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: qrSize, height: qrSize)
                    .transition(.opacity)
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(isIPad ? 1.3 : 1.1)
                        .tint(AppColors.primaryGreen)
                    
                    Text("Generating QR Code...".localized)
                        .font(.inter(.medium, size: isIPad ? 14 : 12.scaled))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
                .frame(width: qrSize, height: qrSize)
            }
        }
        .padding(padding)
        .frame(width: cardSize, height: cardSize)
        .background(
            RoundedRectangle(cornerRadius: isIPad ? 28 : 24.scaled, style: .continuous)
                .fill(colorScheme == .dark ? Color(hex: "#1E1E1E") : Color.white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.35 : 0.08), radius: 18, x: 0, y: 6)
        )
    }
    
    // MARK: - Instructions Section (Matching Screenshot)
    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: isIPad ? 18 : 14.scaled) {
            Text("Use WhatsApp on your computer".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 17.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .padding(.bottom, 2)
            
            VStack(alignment: .leading, spacing: isIPad ? 20 : 12.scaled) {
                // Step 1: Open WhatsApp on your phone
                instructionStepRow(
                    step: 1,
                    part1: "Open ".localized,
                    highlight1: "WhatsApp",
                    part2: " on your phone".localized
                )
                
                // Step 2: Tap Menu on Android, or Settings on iPhone
                instructionStepRow(
                    step: 2,
                    part1: "Tap ".localized,
                    highlight1: "Menu",
                    part2: " on Android, or ".localized,
                    highlight2: "Settings",
                    part3: " on iPhone".localized
                )
                
                // Step 3: Tap Linked devices and then Link a device
                instructionStepRow(
                    step: 3,
                    part1: "Tap ".localized,
                    highlight1: "Linked devices",
                    part2: " and then ".localized,
                    highlight2: "Link a device"
                )
                
                // Step 4: Point your phone at this screen to capture the QR code
                HStack(alignment: .top, spacing: 12.scaled) {
                    stepBadge(4)
                    
                    Text("Point your phone at this screen to capture the QR code".localized)
                        .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Step Row Helpers
    private func stepBadge(_ number: Int) -> some View {
        ZStack {
            Circle()
                .fill(AppColors.primaryGreen)
                .frame(width: isIPad ? 26 : 22.scaled, height: isIPad ? 26 : 22.scaled)
            
            Text("\(number)")
                .font(.inter(.bold, size: isIPad ? 13 : 11.scaled))
                .foregroundColor(.white)
        }
    }
    
    private func instructionStepRow(
        step: Int,
        part1: String,
        highlight1: String,
        part2: String,
        highlight2: String = "",
        part3: String = ""
    ) -> some View {
        HStack(alignment: .top, spacing: 12.scaled) {
            stepBadge(step)
            
            (
                Text(part1)
                    .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                +
                Text(highlight1)
                    .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.primaryGreen)
                +
                Text(part2)
                    .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                +
                Text(highlight2)
                    .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.primaryGreen)
                +
                Text(part3)
                    .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
            )
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func refreshQRCode() {
        HapticFeedback.generate(.medium)
        qrImage = nil
        isLoading = true
        if !sessionAccount.isSessionActive {
            sessionAccount.webDataStoreID = UUID().uuidString
            AccountManager.shared.update(sessionAccount)
        }
        var request = URLRequest(url: URL(string: "https://web.whatsapp.com/")!)
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        webView?.load(request)
    }
    
    public static func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8) else { return nil }
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let outputImage = filter.outputImage else { return nil }
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let scaledImage = outputImage.transformed(by: transform)
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Background WKWebView for Live WhatsApp Web Sync & Scan Detection
struct WebScannerWKWebViewRepresentable: UIViewRepresentable {
    let account: AppAccount
    @Binding var webViewRef: WKWebView?
    @Binding var qrImage: UIImage?
    @Binding var isLoggedIn: Bool
    @Binding var isLoading: Bool
    @Binding var showPaywall: Bool
    let isPro: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.allowsAirPlayForMediaPlayback = false
        config.websiteDataStore = AccountManager.shared.dataStore(for: account)
        
        let defaultWebpagePreferences = WKWebpagePreferences()
        defaultWebpagePreferences.preferredContentMode = .desktop
        config.defaultWebpagePreferences = defaultWebpagePreferences
        
        // 1. desktopSpoofScript: Spoof desktop platform & touch properties to prevent WhatsApp from redirecting to the mobile download page
        let desktopSpoofScript = WKUserScript(
            source: """
            (function() {
                try {
                    Object.defineProperty(navigator, 'platform', {
                        get: function() { return 'MacIntel'; },
                        configurable: true
                    });
                    Object.defineProperty(navigator, 'maxTouchPoints', {
                        get: function() { return 0; },
                        configurable: true
                    });
                    Object.defineProperty(navigator, 'vendor', {
                        get: function() { return 'Google Inc.'; },
                        configurable: true
                    });
                    if (!window.chrome) {
                        window.chrome = {
                            app: { isInstalled: false, InstallState: { DISABLED: 'disabled', INSTALLED: 'installed', NOT_INSTALLED: 'not_installed' } },
                            runtime: { OnInstalledReason: {}, OnRestartRequiredReason: {}, PlatformArch: {}, PlatformNaclArch: {}, PlatformOs: {}, RequestUpdateCheckStatus: {} }
                        };
                    }
                    window.alert = function() {};
                    window.confirm = function() { return true; };
                    window.prompt = function(m, d) { return d || ''; };
                } catch(e) {}
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(desktopSpoofScript)
        
        // 2. inlineVideoScript (From CloneVC: play status video inline)
        let inlineVideoScript = WKUserScript(
            source: """
            document.addEventListener('DOMContentLoaded', function() {
                const videos = document.querySelectorAll('video');
                videos.forEach(v => {
                    v.setAttribute('playsinline', true);
                    v.setAttribute('webkit-playsinline', true);
                    v.removeAttribute('controls');
                });
            });
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(inlineVideoScript)
        
        // 3. statusButtonScript (Inject download button ONLY in status viewer)
        let statusButtonScript = WKUserScript(
            source: """
            const domObserver = new MutationObserver(() => {
              // Check if WhatsApp status viewer is currently active:
              // WhatsApp Status player always has Pause/Play, Volume/Mute, or x-viewer / close on top of media
              const pauseBtn = document.querySelector('span[data-icon="pause"], span[data-icon="play"]')?.closest('button, [role="button"]')
                            || document.querySelector('button[aria-label="Pause"], button[aria-label="Play"], div[role="button"][aria-label="Pause"], div[role="button"][aria-label="Play"]');
              const muteBtn = document.querySelector('span[data-icon*="volume"]')?.closest('button, [role="button"]')
                           || document.querySelector('button[aria-label="Mute"], button[aria-label="Unmute"], div[role="button"][aria-label="Mute"], div[role="button"][aria-label="Unmute"]');
              const xBtn = document.querySelector('span[data-icon="x"], span[data-icon="x-viewer"], span[data-icon="close"]')?.closest('button, [role="button"]')
                        || document.querySelector('button[aria-label="Close"], div[role="button"][aria-label="Close"]');

              // Status viewer is active if we see pause/play, volume control, or an X button outside the sidepane
              const hasMedia = !!(document.querySelector('video') || document.querySelector('img[src*="blob"]'));
              const isStatusViewer = !!(pauseBtn || muteBtn || document.querySelector('span[data-icon="x-viewer"]') || (xBtn && hasMedia && !xBtn.closest('#side, #pane-side, [data-testid="chat-list"]')));

              // If status viewer is not active, clean up download buttons and exit
              if (!isStatusViewer) {
                const existingButtons = document.querySelectorAll('.custom-download-btn');
                if (existingButtons.length > 0) {
                  existingButtons.forEach(btn => btn.remove());
                }
                return;
              }

              // Target button at top right: prefer xBtn (close), then pauseBtn or muteBtn
              const targetBtn = (xBtn && !xBtn.closest('#side, #pane-side, [data-testid="chat-list"]')) ? xBtn : (pauseBtn || muteBtn);

              if (targetBtn && !document.querySelector('.custom-download-btn')) {
                const containerElement = targetBtn.parentElement?.parentElement?.parentElement
                                      || targetBtn.parentElement?.parentElement
                                      || targetBtn.parentElement;

                const downloadButton = document.createElement('button');
                downloadButton.className = 'custom-download-btn';
                downloadButton.type = 'button';
                downloadButton.setAttribute('aria-label', 'Download Status');
                downloadButton.style.background = 'transparent';
                downloadButton.style.border = 'none';
                downloadButton.style.cursor = 'pointer';
                downloadButton.style.marginRight = '8px';
                downloadButton.style.padding = '6px';
                downloadButton.style.display = 'inline-flex';
                downloadButton.style.alignItems = 'center';
                downloadButton.style.justifyContent = 'center';
                downloadButton.style.zIndex = '99999';

                downloadButton.innerHTML = `
                  <svg fill="#FFF" height="18px" width="18px" viewBox="0 0 29.978 29.978" style="filter: drop-shadow(0px 1px 2px rgba(0,0,0,0.7));">
                    <g>
                      <path d="M25.462,19.105v6.848H4.515v-6.848H0.489v8.861c0,1.111,0.9,2.012,2.016,2.012h24.967c1.115,0,2.016-0.9,2.016-2.012 v-8.861H25.462z"/>
                      <path d="M14.62,18.426l-5.764-6.965c0,0-0.877-0.828,0.074-0.828s3.248,0,3.248,0s0-0.557,0-1.416c0-2.449,0-6.906,0-8.723 c0,0-0.129-0.494,0.615-0.494c0.75,0,4.035,0,4.572,0c0.536,0,0.524,0.416,0.524,0.416c0,1.762,0,6.373,0,8.742 c0,0.768,0,1.266,0,1.266s1.842,0,2.998,0c1.154,0,0.285,0.867,0.285,0.867s-4.904,6.51-5.588,7.193 C15.092,18.979,14.62,18.426,14.62,18.426z"/>
                    </g>
                  </svg>
                `;

                downloadButton.addEventListener('click', (e) => {
                  e.preventDefault();
                  e.stopPropagation();

                  function fetchBlobAndSendToSwift(blobUrl, fallbackType) {
                      fetch(blobUrl)
                          .then(response => response.blob())
                          .then(blob => {
                              const reader = new FileReader();
                              reader.onloadend = function() {
                                  const base64data = reader.result;
                                  if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.statusHandler) {
                                      window.webkit.messageHandlers.statusHandler.postMessage({
                                          mediaType: blob.type || fallbackType || 'image/jpeg',
                                          base64Data: (base64data || '').split(',')[1] || ''
                                      });
                                  }
                              };
                              reader.readAsDataURL(blob);
                          })
                          .catch(error => {
                              console.error('Fetching blob failed:', error);
                          });
                  }

                  const videoElement = document.querySelector('video[src^="blob:"]') || document.querySelector('video');
                  if (videoElement && videoElement.src) {
                      fetchBlobAndSendToSwift(videoElement.src, 'video/mp4');
                      return;
                  }

                  const images = Array.from(document.querySelectorAll('img[src^="blob:"], img[src*="blob"], div[data-animate-modal-body] img, div[role="dialog"] img, img'));
                  const imageElement = images.find(img => (img.naturalWidth > 150 || img.clientWidth > 150) && !img.closest('#side'))
                                    || images.find(img => img.src.includes('blob:'))
                                    || images[0];

                  if (imageElement && imageElement.src) {
                      fetchBlobAndSendToSwift(imageElement.src, 'image/jpeg');
                      return;
                  }

                  console.log('No blob media found');
                });

                if (targetBtn.parentElement && targetBtn.parentElement !== containerElement) {
                  targetBtn.parentElement.parentElement?.insertBefore(downloadButton, targetBtn.parentElement);
                } else if (targetBtn.parentNode) {
                  targetBtn.parentNode.insertBefore(downloadButton, targetBtn);
                } else if (containerElement) {
                  containerElement.prepend(downloadButton);
                }
              }
            });

            domObserver.observe(document.body || document.documentElement, {
              childList: true,
              subtree: true
            });
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        config.userContentController.addUserScript(statusButtonScript)
        config.userContentController.add(context.coordinator, name: "statusHandler")
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.configuration.allowsInlineMediaPlayback = true
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        // WhatsApp Desktop User Agent
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        webView.configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        
        context.coordinator.webView = webView
        
        // Load Selected Web immediately with desktop language headers
        var request = URLRequest(url: URL(string: "https://web.whatsapp.com/")!)
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        print("🚀 [WebScanner] Loading https://web.whatsapp.com/ for account: '\(account.accountName)' (id: \(account.id), storeID: \(account.webDataStoreID), isSessionActive: \(account.isSessionActive))")
        webView.load(request)
        
        // Start capturing QR and login check as done in CloneVC
        context.coordinator.startQRCodeCapture()
        context.coordinator.startLoginCheckTimer(webView: webView)
        
        DispatchQueue.main.async {
            self.webViewRef = webView
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.cleanup()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WebScannerWKWebViewRepresentable
        weak var webView: WKWebView?
        
        private var qrTimer: Timer?
        private var loginCheckTimer: Timer?
        private var lastQRString: String?
        private var qrPollAttemptCount: Int = 0
        
        init(parent: WebScannerWKWebViewRepresentable) {
            self.parent = parent
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "statusHandler" {
                StatusSaverHelper.handleStatusMedia(body: message.body)
            }
        }
        
        func cleanup() {
            print("🛑 [WebScanner] Cleaning up Coordinator, invalidating timers.")
            qrTimer?.invalidate()
            qrTimer = nil
            loginCheckTimer?.invalidate()
            loginCheckTimer = nil
            lastQRString = nil
            qrPollAttemptCount = 0
            webView?.stopLoading()
            webView?.navigationDelegate = nil
            webView?.uiDelegate = nil
        }
        
        // MARK: - WKUIDelegate (Prevents webview freeze on modal alerts or calls permission requests)
        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            completionHandler()
        }
        
        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            completionHandler(true)
        }
        
        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWith prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            completionHandler(defaultText)
        }
        
        @available(iOS 15.0, *)
        func webView(_ webView: WKWebView, requestMediaCapturePermissionFor origin: WKSecurityOrigin, initiatedByFrame frame: WKFrameInfo, type: WKMediaCaptureType, decisionHandler: @escaping (WKPermissionDecision) -> Void) {
            decisionHandler(.grant)
        }
        
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                let urlString = url.absoluteString.lowercased()
                // Block redirection to WhatsApp mobile download page or marketing page
                if urlString.contains("/download") || (urlString.contains("whatsapp.com") && !urlString.contains("web.whatsapp.com")) {
                    print("🚫 [WebScanner Navigation] Blocked redirection to mobile/download page: \(url.absoluteString). Re-routing to https://web.whatsapp.com/...")
                    decisionHandler(.cancel)
                    var req = URLRequest(url: URL(string: "https://web.whatsapp.com/")!)
                    req.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
                    webView.load(req)
                    return
                }
            }
            decisionHandler(.allow)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🌐 [WebScanner Navigation] Started loading: \(webView.url?.absoluteString ?? "https://web.whatsapp.com/")")
            DispatchQueue.main.async {
                self.lastQRString = nil
                self.qrPollAttemptCount = 0
                self.parent.isLoading = true
                self.startQRCodeCapture()
                self.startLoginCheckTimer(webView: webView)
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ [WebScanner Navigation] Page finished loading. Title: '\(webView.title ?? "")', URL: \(webView.url?.absoluteString ?? "")")
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            if !parent.isLoggedIn {
                startQRCodeCapture()
                startLoginCheckTimer(webView: webView)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ [WebScanner Navigation] Navigation failed: \(error.localizedDescription) (Code: \((error as NSError).code))")
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ [WebScanner Navigation] Provisional navigation failed: \(error.localizedDescription) (Code: \((error as NSError).code))")
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        // MARK: - Capture WhatsApp QRCode (From CloneVC)
        func startQRCodeCapture() {
            qrTimer?.invalidate()
            print("▶️ [WebScanner QR] Starting QR Code capture polling (interval: 1.0s)...")
            
            qrTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self = self, let webView = self.webView, !self.parent.isLoggedIn else {
                    self?.qrTimer?.invalidate()
                    self?.qrTimer = nil
                    return
                }
                
                self.qrPollAttemptCount += 1
                let attempt = self.qrPollAttemptCount
                
                let js = """
                (function() {
                    var out = {
                        success: false,
                        type: "none",
                        payload: null,
                        readyState: document.readyState || "",
                        title: document.title || "",
                        canvasFound: false,
                        canvasWidth: 0,
                        canvasHeight: 0,
                        dataRefFound: false,
                        dataRefLength: 0,
                        reloadNeeded: false,
                        snippet: "",
                        jsError: null
                    };
                    
                    try {
                        // Check if QR expired / reload button exists
                        var reloadBtn = document.querySelector('button[aria-label*="Reload"]') 
                                     || document.querySelector('[data-testid="reload-qr-button"]')
                                     || document.querySelector('button[aria-label*="Click to reload"]');
                        if (!reloadBtn) {
                            var buttons = document.querySelectorAll('button, div[role="button"]');
                            for (var b = 0; b < buttons.length; b++) {
                                var text = (buttons[b].innerText || buttons[b].textContent || '').toLowerCase();
                                if (text.includes('click to reload') || text.includes('reload qr')) {
                                    reloadBtn = buttons[b];
                                    break;
                                }
                            }
                        }
                        if (reloadBtn) {
                            out.reloadNeeded = true;
                            try { reloadBtn.click(); } catch(e) {}
                        }
                        
                        // 1. Try canvas
                        var canvas = document.querySelector('canvas');
                        if (canvas) {
                            out.canvasFound = true;
                            out.canvasWidth = canvas.width || 0;
                            out.canvasHeight = canvas.height || 0;
                            if (canvas.width > 20 && canvas.height > 20) {
                                try {
                                    var dataUrl = canvas.toDataURL("image/png");
                                    if (dataUrl && dataUrl.length > 100) {
                                        out.success = true;
                                        out.type = "canvas";
                                        out.payload = dataUrl;
                                        return JSON.stringify(out);
                                    }
                                } catch(cErr) {
                                    out.jsError = "Canvas toDataURL: " + cErr.message;
                                }
                            }
                        }
                        
                        // 2. Try data-ref attribute
                        var refEl = document.querySelector('[data-ref]');
                        if (refEl) {
                            var refVal = refEl.getAttribute('data-ref') || '';
                            out.dataRefFound = true;
                            out.dataRefLength = refVal.length;
                            if (refVal.length > 10) {
                                out.success = true;
                                out.type = "ref";
                                out.payload = refVal;
                                return JSON.stringify(out);
                            }
                        }
                        
                        // 3. Try img element
                        var img = document.querySelector('img[src^="data:image"]');
                        if (img && img.src && img.src.length > 100) {
                            out.success = true;
                            out.type = "img";
                            out.payload = img.src;
                            return JSON.stringify(out);
                        }
                        
                        // Check if page redirected to the mobile download page
                        var bodyLower = (document.body ? (document.body.innerText || '') : '').toLowerCase();
                        if (bodyLower.includes('download whatsapp') && (bodyLower.includes('app store') || bodyLower.includes('experience on your device'))) {
                            out.snippet = "REDIRECTED_TO_DOWNLOAD";
                            out.jsError = "Page redirected to Download WhatsApp. Auto-reloading web.whatsapp.com...";
                            window.location.replace("https://web.whatsapp.com/");
                            return JSON.stringify(out);
                        }
                        
                        // Page snippet for diagnostics
                        var bodyText = (document.body ? (document.body.innerText || '') : '').replace(/\\s+/g, ' ').trim();
                        if (bodyText.length > 100) {
                            out.snippet = bodyText.substring(0, 100) + "...";
                        } else {
                            out.snippet = bodyText;
                        }
                        
                        return JSON.stringify(out);
                    } catch(err) {
                        out.jsError = "Global JS Error: " + err.message;
                        return JSON.stringify(out);
                    }
                })();
                """
                
                webView.evaluateJavaScript(js) { [weak self] result, error in
                    guard let self = self else { return }
                    if let error = error {
                        print("❌ [WebScanner QR #\(attempt)] JS evaluation error: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let jsonString = result as? String,
                          let jsonData = jsonString.data(using: .utf8),
                          let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                        // Fallback in case raw string is returned
                        if let raw = result as? String, !raw.isEmpty {
                            print("ℹ️ [WebScanner QR #\(attempt)] Raw JS result: \(raw.prefix(80))...")
                        }
                        return
                    }
                    
                    let success = json["success"] as? Bool ?? false
                    let type = json["type"] as? String ?? "none"
                    let readyState = json["readyState"] as? String ?? ""
                    let title = json["title"] as? String ?? ""
                    let canvasFound = json["canvasFound"] as? Bool ?? false
                    let canvasWidth = json["canvasWidth"] as? Int ?? 0
                    let canvasHeight = json["canvasHeight"] as? Int ?? 0
                    let dataRefFound = json["dataRefFound"] as? Bool ?? false
                    let dataRefLength = json["dataRefLength"] as? Int ?? 0
                    let reloadNeeded = json["reloadNeeded"] as? Bool ?? false
                    let snippet = json["snippet"] as? String ?? ""
                    let jsError = json["jsError"] as? String
                    
                    if let jsError = jsError, !jsError.isEmpty {
                        print("⚠️ [WebScanner QR #\(attempt)] JS Warning: \(jsError)")
                    }
                    
                    if !success {
                        print("⏳ [WebScanner QR #\(attempt)] Waiting for QR Code... (ReadyState: '\(readyState)', Title: '\(title)', Canvas: \(canvasFound ? "\(canvasWidth)x\(canvasHeight)" : "None"), DataRef: \(dataRefFound ? "\(dataRefLength) chars" : "None")\(reloadNeeded ? ", ReloadBtnClicked: true" : "")\(snippet.isEmpty ? "" : ", PageText: '\(snippet)'"))")
                        return
                    }
                    
                    guard let payload = json["payload"] as? String, !payload.isEmpty else {
                        print("⚠️ [WebScanner QR #\(attempt)] Marked success but payload is empty!")
                        return
                    }
                    
                    if self.lastQRString == payload {
                        if attempt % 5 == 0 {
                            print("ℹ️ [WebScanner QR #\(attempt)] QR Code is active and displayed on screen (Type: \(type)).")
                        }
                        return
                    }
                    
                    print("🎯 [WebScanner QR #\(attempt)] New QR Code detected! Source: [\(type)], payload length: \(payload.count)")
                    self.lastQRString = payload
                    
                    if type == "canvas" || type == "img" {
                        let cleaned = payload
                            .replacingOccurrences(of: "data:image/png;base64,", with: "")
                            .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                        
                        if let data = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters),
                           let image = UIImage(data: data) {
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    self.parent.qrImage = image
                                    self.parent.isLoading = false
                                }
                                print("✅ [WebScanner QR #\(attempt)] SUCCESS: QR Code UIImage created and displayed on screen! (Size: \(Int(image.size.width))x\(Int(image.size.height)))")
                            }
                        } else {
                            print("❌ [WebScanner QR #\(attempt)] ERROR: Failed to decode Base64 data into UIImage (Cleaned length: \(cleaned.count))")
                        }
                    } else if type == "ref" {
                        print("⚙️ [WebScanner QR #\(attempt)] Generating native QR Code from data-ref: '\(payload.prefix(20))...'")
                        if let image = WebScannerView.generateQRCode(from: payload) {
                            DispatchQueue.main.async {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    self.parent.qrImage = image
                                    self.parent.isLoading = false
                                }
                                print("✅ [WebScanner QR #\(attempt)] SUCCESS: Native QR Code generated from data-ref and displayed! (Size: \(Int(image.size.width))x\(Int(image.size.height)))")
                            }
                        } else {
                            print("❌ [WebScanner QR #\(attempt)] ERROR: CIQRCodeGenerator failed to generate UIImage from data-ref!")
                        }
                    }
                }
            }
        }
        
        // MARK: - Login Check Timer (From CloneVC)
        func startLoginCheckTimer(webView: WKWebView) {
            loginCheckTimer?.invalidate()
            loginCheckTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
                guard let self = self, let webView = self.webView else {
                    self?.loginCheckTimer?.invalidate()
                    self?.loginCheckTimer = nil
                    return
                }
                self.checkAndSaveAccount(webView: webView)
            }
        }
        
        private func checkAndSaveAccount(webView: WKWebView) {
            let loginDetectJS = """
            (function() {
                var isQRPage = document.querySelector('[data-ref]') != null
                            || (document.querySelector('canvas') != null && document.querySelector('canvas').width > 10)
                            || document.querySelector('[data-testid="qrcode"]') != null;
                if (isQRPage) return JSON.stringify({loggedIn: false, isQR: true, name: ''});
                
                var chatList = document.querySelector('#pane-side')
                            || document.querySelector('div[aria-label="Chat list"]')
                            || document.querySelector('[data-testid="chat-list"]')
                            || document.querySelector('div[role="grid"]');
                
                if (chatList) {
                    var phone = '';
                    var pushName = '';
                    
                    try {
                        var wid = localStorage.getItem('last-wid-md') || localStorage.getItem('last-wid');
                        if (wid) {
                            var clean = wid.replace(/["']/g, '').split('@')[0].split(':')[0];
                            if (clean && clean.length >= 7 && !isNaN(clean)) {
                                phone = '+' + clean;
                            }
                        }
                    } catch(e) {}
                    
                    try {
                        for (var i = 0; i < localStorage.length; i++) {
                            var k = localStorage.key(i);
                            if (!k) continue;
                            var v = localStorage.getItem(k);
                            if (!v) continue;
                            
                            var lk = k.toLowerCase();
                            if (lk === 'pushname' || lk === 'user_pushname' || lk === '__fetched_user_name') {
                                var clean = v.replace(/["']/g, '').trim();
                                if (clean && clean.length >= 2 && !/^\\+?\\d+$/.test(clean) && clean !== 'null' && clean !== 'undefined') {
                                    pushName = clean;
                                    break;
                                }
                            }
                            
                            if (v.includes('pushname') || v.includes('notifyName') || v.includes('displayName')) {
                                var match = v.match(/"(?:pushname|notifyName|displayName)":\\s*"([^"]+)"/i);
                                if (match && match[1]) {
                                    var cand = match[1].replace(/\\\\"/g, '"').trim();
                                    if (cand && cand.length >= 2 && !/^\\+?\\d+$/.test(cand) && cand !== 'null' && cand !== 'undefined') {
                                        pushName = cand;
                                        break;
                                    }
                                }
                            }
                            
                            if (lk === 'me' || lk === 'user' || lk.includes('user_info')) {
                                try {
                                    var obj = JSON.parse(v);
                                    if (obj) {
                                        var cand = obj.pushname || obj.notifyName || obj.displayName || obj.name;
                                        if (cand && typeof cand === 'string' && !/^\\+?\\d+$/.test(cand.trim())) {
                                            pushName = cand.trim();
                                            break;
                                        }
                                    }
                                } catch(e) {}
                            }
                        }
                    } catch(e) {}
                    
                    try {
                        var header = document.querySelector('header');
                        if (header) {
                            var profileBtn = header.querySelector('button[aria-label*="profile" i]') 
                                          || header.querySelector('[data-testid="chat-list-header"] button')
                                          || header.querySelector('div[role="button"][aria-label*="profile" i]');
                            if (profileBtn) {
                                var aria = profileBtn.getAttribute('aria-label') || profileBtn.getAttribute('title') || '';
                                var cleanAria = aria.replace(/profile/gi, '').replace(/your/gi, '').replace(/photo/gi, '').replace(/picture/gi, '').replace(/[,:_ -]/g, '').trim();
                                if (cleanAria.length > 1 && !cleanAria.toLowerCase().includes('status') && !cleanAria.toLowerCase().includes('channels') && !cleanAria.toLowerCase().includes('communities') && !cleanAria.toLowerCase().includes('new chat') && !cleanAria.toLowerCase().includes('menu')) {
                                    if (!pushName) pushName = cleanAria;
                                }
                            }
                            var img = header.querySelector('img[alt]');
                            if (img && !pushName) {
                                var alt = (img.getAttribute('alt') || '').replace(/profile/gi, '').replace(/picture/gi, '').replace(/photo/gi, '').trim();
                                if (alt.length > 1 && !alt.toLowerCase().includes('status')) {
                                    pushName = alt;
                                }
                            }
                        }
                    } catch(e) {}
                    
                    var finalName = '';
                    if (pushName && !/^\\+?\\d+$/.test(pushName)) {
                        finalName = pushName;
                    }
                    
                    return JSON.stringify({loggedIn: true, isQR: false, name: finalName});
                }
                return JSON.stringify({loggedIn: false, isQR: false, name: ''});
            })()
            """
            
            webView.evaluateJavaScript(loginDetectJS) { [weak self] result, error in
                guard let self = self else { return }
                
                if let _ = error {
                    return
                }
                
                guard let jsonString = result as? String,
                      let jsonData = jsonString.data(using: .utf8),
                      let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
                    return
                }
                
                let isLoggedIn = json["loggedIn"] as? Bool ?? false
                let isQR = json["isQR"] as? Bool ?? false
                
                if isLoggedIn {
                    let rawName = (json["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    let displayName: String
                    if !rawName.isEmpty && !AccountManager.isPhoneNumber(rawName) {
                        displayName = rawName
                    } else {
                        let idx = AccountManager.shared.whatsappIndex(for: self.parent.account)
                        displayName = "WhatsApp - \(idx)"
                    }
                    
                    print("🎉 [WebScanner] Login detected for '\(displayName)'! Stopping QR capture.")
                    var savedAccount = self.parent.account
                    savedAccount.accountName = displayName
                    savedAccount.isSessionActive = true
                    AccountManager.shared.save(savedAccount)
                    
                    UserDefaults.standard.set(true, forKey: "is_whatsapp_web_logged_in")
                    
                    self.qrTimer?.invalidate()
                    self.qrTimer = nil
                    
                    DispatchQueue.main.async {
                        if !self.parent.isPro {
                            print("🔒 [WebScanner] Non-pro user logged in via QR -> Presenting Premium Paywall before revealing WhatsApp Web View")
                            self.parent.showPaywall = true
                        } else {
                            if !self.parent.isLoggedIn {
                                HapticFeedback.generate(.success)
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    self.parent.isLoggedIn = true
                                    self.parent.isLoading = false
                                }
                            }
                        }
                    }
                } else if isQR {
                    // Session is on QR code (not logged in or logged out)
                    if self.parent.isLoggedIn {
                        print("ℹ️ [WebScanner] Session logged out / returned to QR page. Resetting session.")
                        UserDefaults.standard.set(false, forKey: "is_whatsapp_web_logged_in")
                        var acc = self.parent.account
                        AccountManager.shared.resetWhatsAppSession(for: &acc)
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                self.parent.isLoggedIn = false
                            }
                        }
                        self.startQRCodeCapture()
                    }
                }
            }
        }
    }
}

#Preview {
    WebScannerView()
}
