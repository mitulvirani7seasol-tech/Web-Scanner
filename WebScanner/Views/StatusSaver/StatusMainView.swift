//
//  StatusMainView.swift
//  WebScanner
//
//

import SwiftUI

public struct StatusMainView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var navPath: Binding<NavigationPath>?
    
    @State private var navigateToHowToDownload: Bool = false
    @State private var navigateToSavedStatus: Bool = false
    @State private var navigateToSplitLongVideo: Bool = false
    @State private var navigateToCaptionStatus: Bool = false
    @State private var showComingSoonAlert: Bool = false
    @State private var comingSoonFeature: String = ""
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
                        
                        statusCard(
                            title: "WhatsApp Status".localized,
                            subtitle: "Save status videos and photos".localized,
                            iconName: "ic_WhatsApp_Status",
                            gradient: LinearGradient(
                                colors: [Color(hex: "#44D355"), Color(hex: "#26B23C")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            shadowColor: Color(hex: "#26B23C")
                        ) {
                            TR_AdCountViewModel.sharedd.registerTap {
                                if let navPath = navPath {
                                    navPath.wrappedValue.append(HomeDestination.howToDownloadStatus)
                                } else {
                                    navigateToHowToDownload = true
                                }
                            }
                        }
                        
                        statusCard(
                            title: "Saved Status".localized,
                            subtitle: "Save your favorite status moments".localized,
                            iconName: "ic_Saved_Status",
                            gradient: LinearGradient(
                                colors: [Color(hex: "#4DA9F9"), Color(hex: "#2585F5")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            shadowColor: Color(hex: "#2585F5")
                        ) {
                            TR_AdCountViewModel.sharedd.registerTap {
                                if let navPath = navPath {
                                    navPath.wrappedValue.append(HomeDestination.statusSaver)
                                } else {
                                    navigateToSavedStatus = true
                                }
                            }
                        }
                        
                        statusCard(
                            title: "Split Long Video".localized,
                            subtitle: "Split long videos into status".localized,
                            iconName: "ic_Split_Long_Video",
                            gradient: LinearGradient(
                                colors: [Color(hex: "#9E5CF6"), Color(hex: "#8742F0")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            shadowColor: Color(hex: "#8742F0")
                        ) {
                            TR_AdCountViewModel.sharedd.registerTap {
                                if let navPath = navPath {
                                    navPath.wrappedValue.append(HomeDestination.splitLongVideo)
                                } else {
                                    navigateToSplitLongVideo = true
                                }
                            }
                        }
                        
                        statusCard(
                            title: "Caption Status".localized,
                            subtitle: "Find perfect captions for posts".localized,
                            iconName: "ic_Caption_Status",
                            gradient: LinearGradient(
                                colors: [Color(hex: "#EE69F2"), Color(hex: "#D942EB")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            shadowColor: Color(hex: "#D942EB")
                        ) {
                            TR_AdCountViewModel.sharedd.registerTap {
                                if let nav = navPath {
                                    nav.wrappedValue.append(HomeDestination.captionStatus)
                                } else {
                                    navigateToCaptionStatus = true
                                }
                            }
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? 16 : 12.scaled)
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
        .navigationDestination(isPresented: $navigateToHowToDownload) {
            HowToDownloadStatusView()
        }
        .navigationDestination(isPresented: $navigateToSavedStatus) {
            StatusSaverView()
        }
        .navigationDestination(isPresented: $navigateToSplitLongVideo) {
            SplitLongVideoView()
        }
        .navigationDestination(isPresented: $navigateToCaptionStatus) {
            CaptionStatusListView()
        }
        .alert(comingSoonFeature, isPresented: $showComingSoonAlert) {
            Button("OK".localized, role: .cancel) {}
        } message: {
            Text("Coming soon in the next update!".localized)
        }
    }
    
    // MARK: - Header Bar
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 12) {
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
            
            Text("Status".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 8 : 6)
    }
    
    // MARK: - Status Card Component
    private func statusCard(
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
            .padding(.horizontal, isIPad ? 24 : 18.scaled)
            .padding(.vertical, isIPad ? 20 : 16.scaled)
            .frame(maxWidth: .infinity)
            .frame(height: isIPad ? 140 : 94.scaled)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: isIPad ? 22 : 18.scaled, style: .continuous))
            .shadow(color: shadowColor.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.98))
    }
}

#Preview {
    StatusMainView()
}
