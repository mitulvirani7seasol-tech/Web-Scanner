//
//  RecentPlatformsView.swift
//  WebScanner
//
//

import SwiftUI

public struct RecentPlatformsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var accountManager = AccountManager.shared
    
    @Binding var navPath: NavigationPath
    
    @State private var accountToDelete: AppAccount? = nil
    @State private var showDeleteConfirmation: Bool = false
    @State private var showRenameSheet: Bool = false
    @State private var accountToRename: AppAccount? = nil
    @State private var newAccountName: String = ""
    @AppStorage(WS_SessionKeys.isPro) var isPro = false
    @State private var showPaywall: Bool = false
    @State private var showNoInternetAlert: Bool = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(navPath: Binding<NavigationPath>) {
        self._navPath = navPath
    }
    
    public var body: some View {
        GeometryReader { geo in
            let horizontalPadding: CGFloat = isIPad ? 28 : 16
            
            VStack(spacing: 0) {
                headerBar(horizontalPadding: horizontalPadding)
                
                if accountManager.accounts.isEmpty {
                    emptyStateView
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: isIPad ? 14 : 10.scaled) {
                            ForEach(accountManager.accounts) { account in
                                RecentPlatformRow(
                                    account: account,
                                    colorScheme: colorScheme,
                                    isIPad: isIPad,
                                    onTap: {
                                        HapticFeedback.generate(.light)
                                        guard NetworkMonitor.shared.isNetworkAvailable else {
                                            showNoInternetAlert = true
                                            return
                                        }
                                        if !isPro {
                                            showPaywall = true
                                            return
                                        }
                                        accountManager.touch(account)
                                        TR_AdCountViewModel.sharedd.registerTap {
                                            if account.platform == .whatsApp {
                                                if account.isSessionActive {
                                                    navPath.append(HomeDestination.clone(platform: .whatsApp, accountId: account.id))
                                                } else {
                                                    navPath.append(HomeDestination.webScanner(accountId: account.id))
                                                }
                                            } else {
                                                navPath.append(HomeDestination.clone(platform: account.platform, accountId: account.id))
                                            }
                                        }
                                    },
                                    onDelete: {
                                        accountToDelete = account
                                        showDeleteConfirmation = true
                                    },
                                    onRename: {
                                        accountToRename = account
                                        let raw = account.accountName.trimmingCharacters(in: .whitespacesAndNewlines)
                                        if raw.isEmpty || raw.starts(with: "-") || raw.contains("લૉગ ઇન") || raw.contains("સાઇન અપ") || raw.contains("Log in") || raw.contains("Sign in") {
                                            newAccountName = "\(account.platform.displayName) - 1"
                                        } else {
                                            newAccountName = account.accountName
                                        }
                                        showRenameSheet = true
                                    }
                                )
                            }
                            
                            if !isPro {
                                TR_NativeAd7()
                                    .padding(.top, 10)
                            }
                        }
                        .padding(.horizontal, horizontalPadding)
                        .padding(.top, isIPad ? 14 : 10.scaled)
                        .padding(.bottom, isIPad ? 60 : 40)
                    }
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
        .onDisappear {
            if navPath.isEmpty {
                TabBarManager.shared.isHidden = false
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PremiumPaywallView(isFromAppOpen: false) {
                showPaywall = false
            }
        }
        .alert(isPresented: $showDeleteConfirmation) {
            Alert(
                title: Text("Delete Platform".localized),
                message: Text("Are you sure you want to delete this account? You will be logged out.".localized),
                primaryButton: .destructive(Text("Delete".localized)) {
                    if let acc = accountToDelete {
                        HapticFeedback.generate(.medium)
                        accountManager.delete(id: acc.id)
                        if !accountManager.accounts.contains(where: { $0.platform == .whatsApp }) {
                            UserDefaults.standard.set(false, forKey: "is_whatsapp_web_logged_in")
                        }
                    }
                    accountToDelete = nil
                },
                secondaryButton: .cancel {
                    accountToDelete = nil
                }
            )
        }
        .alert("No Internet Connection".localized, isPresented: $showNoInternetAlert) {
            Button("OK".localized, role: .cancel) {}
        } message: {
            Text("Please check your internet connection and try again.".localized)
        }
        .sheet(isPresented: $showRenameSheet) {
            renameSheet
        }
    }
    
    // MARK: - Header Bar (< Recent Platforms)
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                if !navPath.isEmpty {
                    navPath.removeLast()
                } else {
                    dismiss()
                }
                TabBarManager.shared.isHidden = false
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .contentShape(Rectangle())
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Recent Platforms".localized)
                .font(.inter(.bold, size: isIPad ? 24 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 10 : 8)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: isIPad ? 14 : 10.scaled) {
            Spacer()
            
            Image("ic_No_Platforms_Yet")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: isIPad ? 100 : 80.scaled, height: isIPad ? 100 : 80.scaled)
            
            Text("No Platforms Yet".localized)
                .font(.inter(.medium, size: isIPad ? 16 : 14))
                .foregroundColor(AppColors.textSecondary(for: colorScheme))
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var isRenameValid: Bool {
        !newAccountName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Rename Sheet
    private var renameSheet: some View {
        VStack(spacing: 16) {
            Text("Rename Account".localized)
                .font(.inter(.bold, size: 18))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .padding(.top, 16)
            
            TextField("Account Name".localized, text: $newAccountName)
                .font(.inter(.medium, size: 16))
                .padding(12)
                .background(AppColors.cardBackground(for: colorScheme))
                .cornerRadius(12)
                .padding(.horizontal, 20)
            
            HStack(spacing: 14) {
                Button("Cancel".localized) {
                    showRenameSheet = false
                }
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .glassCard(cornerRadius: 12.scaled)
                
                Button("Update".localized) {
                    let trimmed = newAccountName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    if var acc = accountToRename {
                        acc.accountName = trimmed
                        accountManager.update(acc)
                    }
                    showRenameSheet = false
                }
                .font(.inter(.bold, size: 15))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isRenameValid ? AppColors.primaryGreen : AppColors.primaryGreen.opacity(0.4))
                .cornerRadius(12)
                .disabled(!isRenameValid)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
        }
        .background(
            AppColors.background(for: colorScheme)
                .ignoresSafeArea(edges: .bottom)
        )
        .presentationDetents([.height(isIPad ? 210 : 170)])
        .presentationDragIndicator(.hidden)
    }
}
