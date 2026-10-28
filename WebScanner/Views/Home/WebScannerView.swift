//
//  WebScannerView.swift
//  WebScanner
//

import SwiftUI
import WebKit

public struct WebScannerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localizationHelper = LocalizationHelper.shared
    
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
            let defaultName = AccountManager.shared.defaultAccountName(for: .whatsApp)
            let newAccount = AppAccount(platform: .whatsApp, accountName: defaultName, isSessionActive: false)
            _sessionAccount = State(initialValue: newAccount)
        }
        _isLoggedIn = State(initialValue: existingAccount?.isSessionActive ?? false)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if isLoggedIn {
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
                    Image(colorScheme == .dark ? "BG_Dark" : "BG")
                        .resizable()
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 0) {
                        headerBar
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: isIPad ? 40 : 22.scaled) {
                                qrCard
                                
                                instructionsSection
                                
                                if !isPro {
                                    TR_NativeAd6()
                                }
                                
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
        .id(localizationHelper.refreshID)
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
                instructionStepRow(
                    step: 1,
                    text: "Open WhatsApp on your phone".localized,
                    highlightWords: ["WhatsApp"]
                )
                
                instructionStepRow(
                    step: 2,
                    text: "Tap Menu on Android, or Settings on iPhone".localized,
                    highlightWords: [
                        "Menu", "Menü", "Menú", "Меню", "मेनू", "メニュー", "메뉴", "菜单",
                        "Settings", "Indstillinger", "Einstellungen", "Ajustes", "Réglages",
                        "सेटिंग्स", "Impostazioni", "設定", "设置", "설정", "Instellingen", "Definições",
                        "Configurações", "Настройки", "Ayarlar"
                    ]
                )
                
                instructionStepRow(
                    step: 3,
                    text: "Tap Linked devices and then Link a device".localized,
                    highlightWords: [
                        "Linked devices", "Forbundne enheder", "Verknüpfte Geräte",
                        "Dispositivos vinculados", "Appareils connectés", "लिंक किए गए डिवाइस",
                        "Dispositivi collegati", "リンクされたデバイス", "연결된 기기",
                        "Gekoppelde apparaten", "Dispositivos associados", "Aparelhos conectados",
                        "Связанные устройства", "Bağlı cihazlar", "已关联的设备",
                        "Link a device", "Forbind en enhed", "Gerät verknüpfen",
                        "Vincular un dispositivo", "Connecter un appareil", "डिवाइस लिंक करें",
                        "Collega un dispositivo", "デバイスをリンク", "기기 연결",
                        "Een apparaat koppelen", "Associar um dispositivo", "Conectar um aparelho",
                        "Привязать устройство", "Cihaz bağla", "关联设备"
                    ]
                )
                
                instructionStepRow(
                    step: 4,
                    text: "Point your phone at this screen to capture the QR code".localized,
                    highlightWords: []
                )
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
        text: String,
        highlightWords: [String] = []
    ) -> some View {
        HStack(alignment: .top, spacing: 12.scaled) {
            stepBadge(step)
            
            buildHighlightedText(fullText: text, highlightWords: highlightWords)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func buildHighlightedText(fullText: String, highlightWords: [String]) -> Text {
        guard !highlightWords.isEmpty else {
            return Text(fullText)
                .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
        }
        
        var matches: [Range<String.Index>] = []
        for word in highlightWords {
            guard !word.isEmpty else { continue }
            var searchStart = fullText.startIndex
            while searchStart < fullText.endIndex,
                  let range = fullText.range(of: word, options: .caseInsensitive, range: searchStart..<fullText.endIndex) {
                matches.append(range)
                searchStart = range.upperBound
            }
        }
        
        matches.sort { $0.lowerBound < $1.lowerBound }
        
        var merged: [Range<String.Index>] = []
        for r in matches {
            if let last = merged.last {
                if r.lowerBound <= last.upperBound {
                    let newRange = last.lowerBound..<max(last.upperBound, r.upperBound)
                    merged[merged.count - 1] = newRange
                } else {
                    merged.append(r)
                }
            } else {
                merged.append(r)
            }
        }
        
        if merged.isEmpty {
            return Text(fullText)
                .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
        }
        
        var segments: [(text: String, isHighlighted: Bool)] = []
        var currentIndex = fullText.startIndex
        for r in merged {
            if currentIndex < r.lowerBound {
                segments.append((String(fullText[currentIndex..<r.lowerBound]), false))
            }
            segments.append((String(fullText[r]), true))
            currentIndex = r.upperBound
        }
        if currentIndex < fullText.endIndex {
            segments.append((String(fullText[currentIndex..<fullText.endIndex]), false))
        }
        
        guard let first = segments.first else {
            return Text("")
        }
        
        func styledText(_ seg: (text: String, isHighlighted: Bool)) -> Text {
            if seg.isHighlighted {
                return Text(seg.text)
                    .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.primaryGreen)
            } else {
                return Text(seg.text)
                    .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
            }
        }
        
        var result = styledText(first)
        for seg in segments.dropFirst() {
            result = result + styledText(seg)
        }
        return result
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
        let makeUI = WKWebViewConfiguration()
        makeUI.allowsInlineMediaPlayback = true
        makeUI.mediaTypesRequiringUserActionForPlayback = []
        makeUI.allowsAirPlayForMediaPlayback = false
        makeUI.preferences.javaScriptCanOpenWindowsAutomatically = true
        makeUI.websiteDataStore = AccountManager.shared.dataStore(for: account)
        
        let defaultWebpagePreferences = WKWebpagePreferences()
        defaultWebpagePreferences.preferredContentMode = .desktop
        defaultWebpagePreferences.allowsContentJavaScript = true
        makeUI.defaultWebpagePreferences = defaultWebpagePreferences
        
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
        makeUI.userContentController.addUserScript(desktopSpoofScript)
        
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
        makeUI.userContentController.addUserScript(inlineVideoScript)
        
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

                  function sendDataToSwift(mediaType, base64Data) {
                      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.statusHandler) {
                          window.webkit.messageHandlers.statusHandler.postMessage({
                              mediaType: mediaType,
                              base64Data: base64Data
                          });
                      }
                  }

                  function fetchBlobAndSendToSwift(blobUrl, fallbackType) {
                      if (blobUrl.startsWith('data:')) {
                          const parts = blobUrl.split(',');
                          const mimeMatch = parts[0].match(/:(.*?);/);
                          const mimeType = mimeMatch ? mimeMatch[1] : (fallbackType || 'image/jpeg');
                          sendDataToSwift(mimeType, parts[1] || '');
                          return;
                      }

                      fetch(blobUrl)
                          .then(response => response.blob())
                          .then(blob => {
                              const reader = new FileReader();
                              reader.onloadend = function() {
                                  const base64data = reader.result;
                                  sendDataToSwift(blob.type || fallbackType || 'image/jpeg', (base64data || '').split(',')[1] || '');
                              };
                              reader.readAsDataURL(blob);
                          })
                          .catch(error => {
                              console.error('Fetching blob failed:', error);
                          });
                  }

                  function extractAndSendMedia(retriesLeft) {
                      // 1. Check video
                      const videos = Array.from(document.querySelectorAll('video')).filter(v => !v.closest('#side, #pane-side, [data-testid="chat-list"]'));
                      const videoElement = videos.find(v => v.src && v.src.startsWith('blob:')) || videos.find(v => v.src);
                      if (videoElement && videoElement.src) {
                          fetchBlobAndSendToSwift(videoElement.src, 'video/mp4');
                          return;
                      }

                      // 2. Candidate images outside side-pane, chat-list, header
                      const allImages = Array.from(document.querySelectorAll('img')).filter(img => {
                          if (img.closest('#side, #pane-side, [data-testid="chat-list"], header')) return false;
                          if (img.src && (img.src.includes('emoji') || img.src.includes('data:image/svg+xml'))) return false;
                          return true;
                      });

                      // 2a. Priority 1: blob images sorted by resolution
                      const blobImages = allImages.filter(img => img.src && img.src.includes('blob:'));
                      if (blobImages.length > 0) {
                          blobImages.sort((a, b) => ((b.naturalWidth * b.naturalHeight) || (b.clientWidth * b.clientHeight)) - ((a.naturalWidth * a.naturalHeight) || (a.clientWidth * a.clientHeight)));
                          fetchBlobAndSendToSwift(blobImages[0].src, 'image/jpeg');
                          return;
                      }

                      // 2b. Priority 2: Canvas in viewer
                      const canvases = Array.from(document.querySelectorAll('canvas')).filter(c => {
                          return !c.closest('#side, #pane-side, [data-testid="chat-list"], header') && c.width > 200 && c.height > 200;
                      });
                      if (canvases.length > 0) {
                          canvases.sort((a, b) => (b.width * b.height) - (a.width * a.height));
                          try {
                              const dataUrl = canvases[0].toDataURL('image/jpeg', 0.95);
                              if (dataUrl && dataUrl.startsWith('data:')) {
                                  sendDataToSwift('image/jpeg', dataUrl.split(',')[1] || '');
                                  return;
                              }
                          } catch (err) {
                              console.error('Canvas export failed:', err);
                          }
                      }

                      // 2c. Priority 3: Non-blob images with high natural resolution
                      if (allImages.length > 0) {
                          allImages.sort((a, b) => (b.naturalWidth * b.naturalHeight) - (a.naturalWidth * a.naturalHeight));
                          const bestImage = allImages[0];
                          if (bestImage.naturalWidth >= 300 || (bestImage.naturalWidth * bestImage.naturalHeight) >= 60000) {
                              fetchBlobAndSendToSwift(bestImage.src, 'image/jpeg');
                              return;
                          }
                      }

                      // If only low-res thumbnail is found and retries remain, wait for high-res blob
                      if (retriesLeft > 0) {
                          setTimeout(() => extractAndSendMedia(retriesLeft - 1), 350);
                          return;
                      }

                      // Fallback: send whatever image was found
                      if (allImages.length > 0) {
                          fetchBlobAndSendToSwift(allImages[0].src, 'image/jpeg');
                          return;
                      }

                      console.log('No media found to download');
                  }

                  extractAndSendMedia(2);
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
        makeUI.userContentController.addUserScript(statusButtonScript)
        makeUI.userContentController.add(context.coordinator, name: "statusHandler")
        
        let whatsAppTouchMenuScript = WKUserScript(
            source: """
            (function() {
                try {
                    var style = document.createElement('style');
                    style.innerHTML = `
                        * {
                            -webkit-tap-highlight-color: rgba(0,0,0,0) !important;
                        }
                        #pane-side, #pane-side *, header, header * {
                            touch-action: manipulation !important;
                        }
                    `;
                    (document.head || document.documentElement).appendChild(style);
                } catch(e) {}

                var startX = 0;
                var startY = 0;
                var startTime = 0;
                var activeTouch = false;
                var isMenuJustOpened = false;

                function isEditable(el) {
                    if (!el || !(el instanceof Element)) return false;
                    if (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') return true;
                    if (el.isContentEditable) return true;
                    if (el.closest('[contenteditable="true"], input, textarea')) return true;
                    return false;
                }

                function isChatHeaderMenuButton(el) {
                    if (!el || !(el instanceof Element)) return false;
                    var menuMatch = el.closest('[data-icon="menu"], [data-testid="menu"], [aria-label="Menu"], [title="Menu"], [aria-label="Options"], [title="Options"]');
                    if (menuMatch && menuMatch.closest('#main header, header')) {
                        return true;
                    }
                    var header = el.closest('#main header, header');
                    if (header) {
                        var actionBtns = header.querySelectorAll('button, [role="button"], div[tabindex="0"]');
                        if (actionBtns && actionBtns.length > 0) {
                            var lastBtn = actionBtns[actionBtns.length - 1];
                            if (lastBtn.contains(el) || el === lastBtn) {
                                return true;
                            }
                        }
                    }
                    return false;
                }

                function clickElement(el, clientX, clientY) {
                    if (!el) return;
                    var htmlEl = (el instanceof HTMLElement) ? el : (el.closest('button, [role="button"], div') || el.parentElement || el);
                    var rect = htmlEl.getBoundingClientRect();
                    var cx = (typeof clientX === 'number' && clientX > 0) ? clientX : (rect.left + rect.width / 2);
                    var cy = (typeof clientY === 'number' && clientY > 0) ? clientY : (rect.top + rect.height / 2);

                    var eventProps = {
                        bubbles: true,
                        cancelable: true,
                        view: window,
                        clientX: cx,
                        clientY: cy,
                        screenX: cx,
                        screenY: cy,
                        button: 0,
                        buttons: 1
                    };

                    try {
                        if (window.PointerEvent) {
                            htmlEl.dispatchEvent(new PointerEvent('pointerdown', Object.assign({ pointerType: 'mouse', isPrimary: true }, eventProps)));
                            htmlEl.dispatchEvent(new PointerEvent('pointerup', Object.assign({ pointerType: 'mouse', isPrimary: true }, eventProps)));
                        }
                    } catch(e) {}

                    try {
                        htmlEl.dispatchEvent(new MouseEvent('mousedown', eventProps));
                        htmlEl.dispatchEvent(new MouseEvent('mouseup', eventProps));
                        htmlEl.dispatchEvent(new MouseEvent('click', eventProps));
                    } catch(e) {}

                    try {
                        if (typeof htmlEl.click === 'function') {
                            htmlEl.click();
                        }
                    } catch(e) {}
                }

                // Protect newly opened dropdown menu from instant outside-click dismissal
                document.addEventListener('mousedown', function(e) {
                    if (isMenuJustOpened) {
                        var inDropdown = e.target && e.target.closest && e.target.closest('[role="application"], [data-testid="dropdown-menu"], [role="menu"], ul[role="menu"]');
                        if (!inDropdown) {
                            e.stopPropagation();
                            e.stopImmediatePropagation();
                        }
                    }
                }, true);

                document.addEventListener('click', function(e) {
                    if (isMenuJustOpened) {
                        var inDropdown = e.target && e.target.closest && e.target.closest('[role="application"], [data-testid="dropdown-menu"], [role="menu"], ul[role="menu"]');
                        if (!inDropdown) {
                            e.stopPropagation();
                            e.stopImmediatePropagation();
                        }
                    }
                }, true);

                document.addEventListener('touchstart', function(e) {
                    if (e.touches && e.touches.length === 1) {
                        startX = e.touches[0].clientX;
                        startY = e.touches[0].clientY;
                        startTime = Date.now();
                        activeTouch = true;
                    } else {
                        activeTouch = false;
                    }
                }, { passive: true, capture: true });

                document.addEventListener('touchend', function(e) {
                    if (!activeTouch) return;
                    activeTouch = false;

                    if (!e.changedTouches || e.changedTouches.length !== 1) return;

                    var endX = e.changedTouches[0].clientX;
                    var endY = e.changedTouches[0].clientY;
                    var dx = Math.abs(endX - startX);
                    var dy = Math.abs(endY - startY);
                    var dt = Date.now() - startTime;

                    if (dx > 10 || dy > 10 || dt > 400) {
                        return;
                    }

                    var target = e.target;
                    if (!target || !(target instanceof Element)) return;

                    if (isEditable(target)) {
                        return;
                    }

                    if (target.closest('.custom-download-btn')) {
                        return;
                    }

                    // 1. SPECIFIC HANDLING: 3-Dot Menu in Chat Screen Header or Main Header
                    if (isChatHeaderMenuButton(target)) {
                        e.preventDefault();
                        e.stopPropagation();

                        isMenuJustOpened = true;
                        setTimeout(function() { isMenuJustOpened = false; }, 400);

                        var header = target.closest('#main header, header');
                        var btn = target.closest('button, [role="button"], div[tabindex="0"]');
                        if (!btn && header) {
                            var allBtns = header.querySelectorAll('button, [role="button"], div[tabindex="0"]');
                            if (allBtns && allBtns.length > 0) {
                                btn = allBtns[allBtns.length - 1];
                            }
                        }
                        if (!btn) btn = target;

                        clickElement(btn, endX, endY);
                        if (target !== btn) {
                            clickElement(target, endX, endY);
                        }

                        setTimeout(function() {
                            var menuOpen = document.querySelector('[role="application"], [data-testid="dropdown-menu"], [role="menu"], ul[role="menu"]');
                            if (!menuOpen) {
                                try { btn.click(); } catch(e) {}
                                try { target.click(); } catch(e) {}
                            }
                        }, 60);

                        return;
                    }

                    // 2. GENERAL HANDLING: Chat rows, buttons, tabs, options
                    var isChatRow = target.closest('#pane-side [role="listitem"], #pane-side [data-testid^="list-item"], #pane-side [role="row"], #pane-side [data-testid="cell-frame-container"]');
                    var isInsidePaneSide = target.closest('#pane-side');
                    var isHeaderButton = target.closest('header button, header [role="button"], #main header [role="button"], #side header [role="button"], header [tabindex="0"]');
                    var isInteractive = target.closest('button, [role="button"], [role="menuitem"], [role="tab"], [role="option"], a[href]');

                    if (isChatRow || isInsidePaneSide || isHeaderButton || isInteractive) {
                        e.preventDefault();

                        var clickTarget = null;
                        if (isHeaderButton) {
                            clickTarget = target.closest('button, [role="button"], [tabindex="0"]') || target;
                        } else if (isInteractive) {
                            clickTarget = target.closest('button, [role="button"], [role="menuitem"], [role="tab"], [role="option"], a[href]') || target;
                        } else if (isChatRow) {
                            clickTarget = isChatRow;
                        } else {
                            clickTarget = (target instanceof SVGElement) ? (target.parentElement || target) : target;
                        }

                        clickElement(clickTarget, endX, endY);
                    }
                }, { passive: false, capture: true });
            })();
            """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: false
        )
        makeUI.userContentController.addUserScript(whatsAppTouchMenuScript)
        
        let webView = WKWebView(frame: .zero, configuration: makeUI)
        webView.configuration.allowsInlineMediaPlayback = true
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
        webView.configuration.defaultWebpagePreferences.preferredContentMode = .desktop
        
        context.coordinator.webView = webView
        
        var request = URLRequest(url: URL(string: "https://web.whatsapp.com/")!)
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        print("🚀 [WebScanner] Loading https://web.whatsapp.com/ for account: '\(account.accountName)' (id: \(account.id), storeID: \(account.webDataStoreID), isSessionActive: \(account.isSessionActive))")
        webView.load(request)
        
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
                if let url = navigationAction.request.url, !url.absoluteString.isEmpty, url.absoluteString != "about:blank" {
                    webView.load(navigationAction.request)
                }
            }
            return nil
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let url = navigationAction.request.url {
                let urlString = url.absoluteString.lowercased()
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
                        let currentName = self.parent.account.accountName.trimmingCharacters(in: .whitespacesAndNewlines)
                        if currentName.starts(with: "WhatsApp - ") || currentName.starts(with: "WT Scan - ") {
                            displayName = currentName
                        } else {
                            let idx = AccountManager.shared.whatsappIndex(for: self.parent.account)
                            displayName = "WhatsApp - \(idx)"
                        }
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
