//
//  ChatMainView.swift
//  WebScanner
//
//

import SwiftUI

public struct ChatMainView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var navPath: Binding<NavigationPath>?
    @State private var navigateToQuickReply: Bool = false
    @State private var navigateToFunnyMessages: Bool = false
    @State private var navigateToScanQRCode: Bool = false
    @State private var navigateToGenerateQRCode: Bool = false
    @AppStorage(WS_SessionKeys.isPro) var isPro = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(navPath: Binding<NavigationPath>? = nil) {
        self.navPath = navPath
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 48 : 32) : 18
            
            VStack(spacing: 0) {
                headerBar(horizontalPadding: horizontalPadding)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isIPad ? 18 : 14.scaled) {
                        
                        if !isPro {
                            TR_NativeAd7()
                                .padding(.top, 10)
                        }
                        
                        chatCard(
                            title: "Quick Replay".localized,
                            subtitle: "Reply instantly with just one tap".localized,
                            iconName: "fi_18611672",
                            gradient: LinearGradient(
                                colors: [Color(hex: "#2F95FA"), Color(hex: "#1A74E8")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            shadowColor: Color(hex: "#1A74E8")
                        ) {
                            TR_AdCountViewModel.sharedd.registerTap {
                                if let nav = navPath {
                                    nav.wrappedValue.append(HomeDestination.quickReply)
                                } else {
                                    navigateToQuickReply = true
                                }
                            }
                        }
                        
                        chatCard(
                            title: "Funny Messages".localized,
                            subtitle: "Create funny messages for every mood".localized,
                            iconName: "fi_3634463",
                            gradient: LinearGradient(
                                colors: [Color(hex: "#EE64F2"), Color(hex: "#BE22C3")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            shadowColor: Color(hex: "#BE22C3")
                        ) {
                            TR_AdCountViewModel.sharedd.registerTap {
                                if let nav = navPath {
                                    nav.wrappedValue.append(HomeDestination.funnyMessages)
                                } else {
                                    navigateToFunnyMessages = true
                                }
                            }
                        }
                        
                        chatCard(
                            title: "Scan QR Code".localized,
                            subtitle: "Scan codes instantly with one tap".localized,
                            iconName: "fi_7463730",
                            gradient: LinearGradient(
                                colors: [Color(hex: "#3BC04B"), Color(hex: "#1D9E33")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            shadowColor: Color(hex: "#1D9E33")
                        ) {
                            TR_AdCountViewModel.sharedd.registerTap {
                                if let nav = navPath {
                                    nav.wrappedValue.append(HomeDestination.scanQRCode)
                                } else {
                                    navigateToScanQRCode = true
                                }
                            }
                        }
                        
                        chatCard(
                            title: "Generate QR Code".localized,
                            subtitle: "Create custom QR codes instantly".localized,
                            iconName: "fi_10326589",
                            gradient: LinearGradient(
                                colors: [Color(hex: "#8B47F6"), Color(hex: "#7522EB")],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            shadowColor: Color(hex: "#7522EB")
                        ) {
                            TR_AdCountViewModel.sharedd.registerTap {
                                GenerateQRTabManager.shared.selectedTab = .qrCode
                                if let nav = navPath {
                                    nav.wrappedValue.append(HomeDestination.generateQRCode)
                                } else {
                                    navigateToGenerateQRCode = true
                                }
                            }
                        }
                        
                       
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? 16 : 14.scaled)
                    .padding(.bottom, 32)
                    .frame(maxWidth: isIPad ? .infinity : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(
            Image(colorScheme == .dark ? "BG_Dark" : "BG")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
        )
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
        }
        .navigationDestination(isPresented: $navigateToQuickReply) {
            QuickReplyView(navPath: navPath)
        }
        .navigationDestination(isPresented: $navigateToFunnyMessages) {
            FunnyMessagesView(navPath: navPath)
        }
        .navigationDestination(isPresented: $navigateToScanQRCode) {
            ScanQRCodeView(navPath: navPath)
        }
        .navigationDestination(isPresented: $navigateToGenerateQRCode) {
            GenerateQRCodeMainView(navPath: navPath)
        }
    }
    
    // MARK: - Header Bar (< Chat)
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 24 : 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 48 : 36, height: isIPad ? 48 : 36)
                    .contentShape(Rectangle())
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Chat".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 6)
    }
    
    // MARK: - Chat Feature Card Component
    private func chatCard(
        title: String,
        subtitle: String,
        iconName: String,
        gradient: LinearGradient,
        shadowColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: {
            HapticFeedback.generate(.medium)
            action()
        }) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: isIPad ? 8 : 6.scaled) {
                    Text(title)
                        .font(.inter(.bold, size: isIPad ? 22 : 18))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.inter(.regular, size: isIPad ? 15 : 13))
                        .foregroundColor(.white.opacity(0.88))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer(minLength: 8)
                
                Image(iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: isIPad ? 90 : 56.scaled, height: isIPad ? 90 : 56.scaled)
                    .padding(.trailing, isIPad ? -25 : -20)
                    .padding(.bottom, isIPad ? -50 : -40)
            }
            .padding(.horizontal, isIPad ? 22 : 18.scaled)
            .padding(.vertical, isIPad ? 18 : 14.scaled)
            .frame(maxWidth: .infinity)
            .frame(height: isIPad ? 140 : 94.scaled)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: isIPad ? 22 : 18.scaled, style: .continuous))
            .shadow(color: shadowColor.opacity(0.35), radius: 8, x: 0, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: isIPad ? 22 : 18.scaled, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ChatMainView()
}
