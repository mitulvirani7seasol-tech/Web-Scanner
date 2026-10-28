//
//  LanguageSelectionView.swift
//  WebScanner
//

import SwiftUI

public struct AppLanguage: Identifiable, Equatable {
    public var id: String { code }
    public let name: String
    public let nativeName: String
    public let code: String
    public let flagImage: String
}

public struct LanguageSelectionView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @ObservedObject private var localizationHelper = LocalizationHelper.shared
    @AppStorage("appLanguage") private var selectedLanguageCode: String = "en"
    @AppStorage(WS_SessionKeys.isPro) private var isPro: Bool = false
    @State private var tempSelectedCode: String = "en"
    
    public var isInitialFlow: Bool
    public var onConfirm: (() -> Void)?
    
    public static let availableLanguages: [AppLanguage] = [
        AppLanguage(name: "English", nativeName: "English", code: "en", flagImage: "FlagEnglish"),
        AppLanguage(name: "Hindi", nativeName: "हिन्दी", code: "hi", flagImage: "FlagHindi"),
        AppLanguage(name: "German", nativeName: "Deutsch", code: "de", flagImage: "FlagGerman"),
        AppLanguage(name: "Chinese", nativeName: "中国人", code: "zh", flagImage: "FlagChinese"),
        AppLanguage(name: "Danish", nativeName: "Nederlands", code: "da", flagImage: "FlagDanish"),
        AppLanguage(name: "French", nativeName: "Français", code: "fr", flagImage: "FlagFrench"),
        AppLanguage(name: "Italian", nativeName: "Italiana", code: "it", flagImage: "FlagItalian"),
        AppLanguage(name: "Portuguese", nativeName: "Português", code: "pt", flagImage: "FlagPortuguese"),
        AppLanguage(name: "Spanish", nativeName: "Española", code: "es", flagImage: "FlagSpanish"),
        AppLanguage(name: "Russian", nativeName: "Русский", code: "ru", flagImage: "FlagRussian"),
        AppLanguage(name: "Turkish", nativeName: "Türkçe", code: "tr", flagImage: "FlagTurkish"),
        AppLanguage(name: "Japanese", nativeName: "日本語", code: "ja", flagImage: "FlagJapanese"),
        AppLanguage(name: "Korean", nativeName: "한국인", code: "ko", flagImage: "FlagKorean"),
        AppLanguage(name: "Dutch", nativeName: "Nederlands", code: "nl", flagImage: "FlagDutch")
    ]
    
    public init(isInitialFlow: Bool = false, onConfirm: (() -> Void)? = nil) {
        self.isInitialFlow = isInitialFlow
        self.onConfirm = onConfirm
        let current = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        self._tempSelectedCode = State(initialValue: current)
    }
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var currentSelectedLanguage: AppLanguage {
        LanguageSelectionView.availableLanguages.first { $0.code == tempSelectedCode }
            ?? LanguageSelectionView.availableLanguages[0]
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack {
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                
                VStack(spacing: 0) {
                    headerView
                        .padding(.horizontal, isIPad ? 32 : 20)
                        .padding(.top, max(geo.safeAreaInsets.top, 20) + (isIPad ? 40 : 40))
                        .padding(.bottom, isIPad ? 18 : 12)
                        .frame(maxWidth: .infinity)
                        
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: isIPad ? 24 : 18) {
                            
                            // MARK: - Section 1: Select Language
                            VStack(alignment: .leading, spacing: isIPad ? 12 : 8) {
                                Text("Select Language".localized)
                                    .font(.inter(.semiBold, size: isIPad ? 18 : 17))
                                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                                    .padding(.horizontal, 4)
                                
                                selectedLanguageCard(currentSelectedLanguage)
                            }
                            
                            // MARK: - Section 2: All Language
                            VStack(alignment: .leading, spacing: isIPad ? 12 : 8) {
                                Text("All Language".localized)
                                    .font(.inter(.semiBold, size: isIPad ? 18 : 17))
                                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                                    .padding(.horizontal, 4)
                                
                                LazyVStack(spacing: isIPad ? 14 : 10) {
                                    ForEach(LanguageSelectionView.availableLanguages.filter { $0.code != currentSelectedLanguage.code }) { lang in
                                        languageRow(lang)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, isIPad ? 32 : 20)
                        .padding(.bottom, 16)
                        .frame(maxWidth: .infinity)
                    }
                    
                    if !isPro {
                        TR_NativeAd6()
                            .padding(.horizontal, isIPad ? 32 : 20)
                            .padding(.top, 4)
                            .padding(.bottom, max(geo.safeAreaInsets.bottom, 12))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea(.all, edges: .all)
        .navigationBarBackButtonHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            tempSelectedCode = selectedLanguageCode
            TabBarManager.shared.isHidden = true
        }
        .onDisappear {
            TabBarManager.shared.isHidden = false
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack(alignment: .center) {
            Text("Your Language".localized)
                .font(.inter(.bold, size: isIPad ? 28 : 24))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
            
            Button(action: {
                HapticFeedback.generate(.medium)
                selectedLanguageCode = tempSelectedCode
                LocalizationHelper.shared.setLanguage(code: tempSelectedCode)
                TR_AdCountViewModel.sharedd.registerTap {
                    if isInitialFlow {
                        onConfirm?()
                    } else {
                        dismiss()
                    }
                }
            }) {
                ZStack {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "#17AE60"), Color(hex: "#007C36")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Image("ic_select_checkmark")
                        .resizable()
                        .renderingMode(.template)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: isIPad ? 22 : 18, height: isIPad ? 22 : 18)
                        .foregroundColor(.white)
                }
                .frame(width: isIPad ? 68 : 58, height: isIPad ? 44 : 38)
                .shadow(color: Color(hex: "#17AE60").opacity(0.38), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Selected Language Hero Card (Liquid Glass, Whole Card Clickable)
    private func selectedLanguageCard(_ lang: AppLanguage) -> some View {
        Button(action: {
            HapticFeedback.generate(.selection)
            withAnimation(.easeInOut(duration: 0.2)) {
                tempSelectedCode = lang.code
            }
        }) {
            HStack(spacing: 14.scaled) {
                Image(lang.flagImage)
                    .resizable()
                    .scaledSquare(34)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                
                Text("\(lang.name) - (\(lang.nativeName))")
                    .font(.inter(.semiBold, size: 15))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color(hex: "#17AE60"))
                        .frame(width: 22.scaled, height: 22.scaled)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 11.scaled, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 16.scaled)
            .padding(.vertical, 14.scaled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .glassCard(
            cornerRadius: 16.scaled,
            color: colorScheme == .dark ? Color.clear : Color.clear
        )
        .contentShape(RoundedRectangle(cornerRadius: 16.scaled))
    }
    
    // MARK: - All Language Row (Liquid Glass, Whole Card Clickable)
    private func languageRow(_ lang: AppLanguage) -> some View {
        let isSelected = (tempSelectedCode == lang.code)
        
        return Button(action: {
            HapticFeedback.generate(.selection)
            withAnimation(.easeInOut(duration: 0.2)) {
                tempSelectedCode = lang.code
            }
        }) {   
            HStack(spacing: 14.scaled) {
                Image(lang.flagImage)
                    .resizable()
                    .scaledSquare(34)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                
                Text("\(lang.name) - (\(lang.nativeName))")
                    .font(.inter(.medium, size: 15))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Spacer()
                
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#17AE60"))
                            .frame(width: 22.scaled, height: 22.scaled)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 11.scaled, weight: .bold))
                            .foregroundColor(.white)
                    }
                } else {
                    Circle()
                        .stroke(colorScheme == .dark ? Color.white.opacity(0.3) : Color(hex: "#C5CCD6"), lineWidth: 1.5)
                        .frame(width: 22.scaled, height: 22.scaled)
                }
            }
            .padding(.horizontal, 16.scaled)
            .padding(.vertical, 14.scaled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .glassCard(
            cornerRadius: 16.scaled,
            color: colorScheme == .dark ? Color.clear : Color.clear
        )
        .contentShape(RoundedRectangle(cornerRadius: 16.scaled))
    }
}

#Preview {
    LanguageSelectionView(isInitialFlow: true)
}
