//
//  FunnyMessagesView.swift
//  WebScanner
//
//

import SwiftUI

public enum FunnyMessageTab: Int, CaseIterable {
    case stylish = 0
    case flipIt = 1
    case repeatText = 2
    
    var title: String {
        switch self {
        case .stylish: return "Stylish"
        case .flipIt: return "Flip it"
        case .repeatText: return "Repeat Text"
        }
    }
}

public struct FunnyMessagesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isInputFocused: Bool
    
    @State private var currentTab: FunnyMessageTab = .stylish
    @State private var inputText: String = ""
    @State private var resultText: String = ""
    @State private var repeatCount: Int = 5
    @State private var isCopied: Bool = false
    @State private var showShareSheet: Bool = false
    
    private let maxCharacters = 500
    private var navPath: Binding<NavigationPath>?
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var canConvert: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public init(navPath: Binding<NavigationPath>? = nil) {
        self.navPath = navPath
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            let horizontalPadding: CGFloat = isIPad ? (isLandscape ? 48 : 32) : 18.scaled
            
            Image(colorScheme == .dark ? "BG_Dark" : "BG")
                .resizable()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerBar(horizontalPadding: horizontalPadding)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isIPad ? 20 : 16.scaled) {
                        segmentedTabsBar
                        
                        typeHereCard
                        
                        resultCard
                        
                        convertButton
                            .padding(.top, isIPad ? 14 : 10)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? 14 : 10)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 24) + 16)
                    .frame(maxWidth: isIPad ? .infinity : .infinity)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .navigationBarHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
        }
        .sheet(isPresented: $showShareSheet) {
            if !resultText.isEmpty {
                ActivityView(activityItems: [resultText])
            }
        }
        .simultaneousGesture(
            TapGesture().onEnded {
                dismissKeyboard()
            }
        )
    }
    
    // MARK: - Header Bar (< Funny Messages)
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismissKeyboard()
                if let nav = navPath, !nav.wrappedValue.isEmpty {
                    nav.wrappedValue.removeLast()
                } else {
                    dismiss()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                    .glassCard(cornerRadius: 12)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Funny Messages".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 10 : 6)
    }
    
    // MARK: - Segmented Tabs (Stylish | Flip it | Repeat Text)
    private var segmentedTabsBar: some View {
        HStack(spacing: 0) {
            ForEach(FunnyMessageTab.allCases, id: \.self) { tab in
                let isSelected = currentTab == tab
                
                Button(action: {
                    if currentTab != tab {
                        HapticFeedback.generate(.selection)
                        TR_AdCountViewModel.sharedd.registerTap()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            currentTab = tab
                        }
                        if !inputText.isEmpty {
                            performConversion()
                        }
                    }
                }) {
                    Text(tab.title.localized)
                        .font(.inter(isSelected ? .bold : .medium, size: isIPad ? 15 : 13.scaled))
                        .foregroundColor(
                            isSelected
                                ? .white
                                : AppColors.textPrimary(for: colorScheme).opacity(0.7)
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: isIPad ? 44 : 36)
                        .background(
                            Group {
                                if isSelected {
                                    Capsule()
                                        .fill(Color(hex: "#16A34A"))
                                } else {
                                    Color.clear
                                }
                            }
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                if tab.rawValue < FunnyMessageTab.allCases.count - 1 {
                    let nextTab = FunnyMessageTab(rawValue: tab.rawValue + 1)
                    if !isSelected && currentTab != nextTab {
                        Rectangle()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.1))
                            .frame(width: 0.8, height: 18)
                    }
                }
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color.clear : Color.clear)
        )
        .overlay(
            Capsule()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.35 : 0.85),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .glassModifier(cornerRadius: 26)
    }
    
    // MARK: - Card 1: Type Here Card
    private var typeHereCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Type Here".localized)
                    .font(.inter(.bold, size: isIPad ? 17 : 15.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Spacer()
                
                Text("\(inputText.count)/\(maxCharacters)")
                    .font(.inter(.regular, size: isIPad ? 13 : 11.scaled))
                    .foregroundColor(AppColors.SaticColor(for: colorScheme))
            }
            
            ZStack(alignment: .topTrailing) {
                ZStack(alignment: .topLeading) {
                    Text(inputText.isEmpty ? " " : (inputText + "\n "))
                        .font(.inter(.regular, size: isIPad ? 15 : 13.5.scaled))
                        .lineSpacing(3)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .padding(.trailing, 28)
                        .opacity(0)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    
                    TextEditor(text: Binding(
                        get: { inputText },
                        set: { newValue in
                            if newValue.count <= maxCharacters {
                                inputText = newValue
                            } else {
                                inputText = String(newValue.prefix(maxCharacters))
                            }
                        }
                    ))
                    .focused($isInputFocused)
                    .scrollContentBackground(.hidden)
                    .font(.inter(.regular, size: isIPad ? 15 : 13.5.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .padding(.trailing, 28)
                    
                    if inputText.isEmpty {
                        Text("Enter Your text here...".localized)
                            .font(.inter(.regular, size: isIPad ? 15 : 13.5.scaled))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme).opacity(0.6))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)
                            .allowsHitTesting(false)
                    }
                }
                
                if !inputText.isEmpty {
                    Button(action: {
                        HapticFeedback.generate(.light)
                        inputText = ""
                        resultText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: isIPad ? 20 : 15))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme).opacity(0.6))
                            .padding(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: isIPad ? 140 : 116.scaled, alignment: inputText.isEmpty ? .center : .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            )
            
            if currentTab == .repeatText {
                HStack(alignment: .center) {
                    Text("Repeat Times".localized)
                        .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            if repeatCount > 1 {
                                HapticFeedback.generate(.light)
                                TR_AdCountViewModel.sharedd.registerTap()
                                repeatCount -= 1
                                if !inputText.isEmpty {
                                    performConversion()
                                }
                            }
                        }) {
                            Image(systemName: "minus")
                                .font(.system(size: isIPad ? 14 : 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: isIPad ? 34 : 28, height: isIPad ? 34 : 28)
                                .background(
                                    Circle()
                                        .fill(repeatCount > 1 ? Color(hex: "#16A34A") : Color.gray.opacity(0.35))
                                )
                        }
                        .disabled(repeatCount <= 1)
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("\(repeatCount)")
                            .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            .frame(minWidth: 20)
                        
                        Button(action: {
                            if repeatCount < 10 {
                                HapticFeedback.generate(.light)
                                TR_AdCountViewModel.sharedd.registerTap()
                                repeatCount += 1
                                if !inputText.isEmpty {
                                    performConversion()
                                }
                            }
                        }) {
                            Image(systemName: "plus")
                                .font(.system(size: isIPad ? 14 : 12, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: isIPad ? 34 : 28, height: isIPad ? 34 : 28)
                                .background(
                                    Circle()
                                        .fill(repeatCount < 10 ? Color(hex: "#16A34A") : Color.gray.opacity(0.35))
                                )
                        }
                        .disabled(repeatCount >= 10)
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
                    )
                }
                .padding(.top, 4)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, isIPad ? 20 : 16.scaled)
        .padding(.vertical, isIPad ? 18 : 14.scaled)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.35 : 0.85),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .glassModifier(cornerRadius: 18)
    }
    
    // MARK: - Card 2: Result Output Card
    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Result".localized)
                    .font(.inter(.bold, size: isIPad ? 17 : 15.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Spacer()
                
                HStack(spacing: 14) {
                    Button(action: {
                        TR_AdCountViewModel.sharedd.registerTap()
                        copyResult()
                    }) {
                        if isCopied {
                            Image(systemName: "checkmark")
                                .font(.system(size: isIPad ? 16 : 14, weight: .bold))
                                .foregroundColor(AppColors.primaryGreen)
                        } else {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
                                .foregroundColor(resultText.isEmpty ? AppColors.textSecondary(for: colorScheme).opacity(0.4) : AppColors.textPrimary(for: colorScheme))
                        }
                    }
                    .disabled(resultText.isEmpty)
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: {
                        TR_AdCountViewModel.sharedd.registerTap()
                        shareResult()
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
                            .foregroundColor(resultText.isEmpty ? AppColors.textSecondary(for: colorScheme).opacity(0.4) : AppColors.textPrimary(for: colorScheme))
                    }
                    .disabled(resultText.isEmpty)
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Group {
                if resultText.isEmpty {
                    VStack(spacing: 8) {
                        Image("ic_convert_massage")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isIPad ? 56 : 44.scaled, height: isIPad ? 56 : 44.scaled)
                            .opacity(0.7)
                        
                        Text("Your converted message appears here".localized)
                            .font(.inter(.regular, size: isIPad ? 14 : 12.scaled))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme).opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                } else {
                    Text(resultText)
                        .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .lineSpacing(4)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: isIPad ? 160 : 130.scaled, alignment: resultText.isEmpty ? .center : .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.04))
            )
        }
        .padding(.horizontal, isIPad ? 20 : 16.scaled)
        .padding(.vertical, isIPad ? 18 : 14.scaled)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(colorScheme == .dark ? 0.35 : 0.85),
                            Color.white.opacity(colorScheme == .dark ? 0.08 : 0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .glassModifier(cornerRadius: 14)
    }
    
    // MARK: - Convert Action Button
    private var convertButton: some View {
        Button(action: {
            guard canConvert else { return }
            HapticFeedback.generate(.medium)
            TR_AdCountViewModel.sharedd.registerTap()
            dismissKeyboard()
            performConversion()
        }) {
            Text("Convert".localized)
                .font(.inter(.bold, size: isIPad ? 18 : 16.scaled))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 56 : 48.scaled)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(canConvert ? Color(hex: "#16A34A") : Color(hex: "#16A34A").opacity(0.5))
                )
                .shadow(
                    color: canConvert ? Color(hex: "#16A34A").opacity(0.35) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .disabled(!canConvert)
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Conversion Logic
    private func performConversion() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            resultText = ""
            return
        }
        
        switch currentTab {
        case .stylish:
            resultText = toStylish(inputText)
        case .flipIt:
            resultText = toFlipIt(inputText)
        case .repeatText:
            let count = max(1, min(10, repeatCount))
            resultText = Array(repeating: inputText, count: count).joined(separator: "\n")
        }
    }
    
    private func toStylish(_ input: String) -> String {
        var output = ""
        for scalar in input.unicodeScalars {
            let val = scalar.value
            if val >= 65 && val <= 90 {
                if let s = UnicodeScalar(0x1D400 + (val - 65)) {
                    output.append(Character(s))
                    continue
                }
            }
            else if val >= 97 && val <= 122 {
                if let s = UnicodeScalar(0x1D41A + (val - 97)) {
                    output.append(Character(s))
                    continue
                }
            }
            else if val >= 48 && val <= 57 {
                if let s = UnicodeScalar(0x1D7CE + (val - 48)) {
                    output.append(Character(s))
                    continue
                }
            }
            output.append(Character(scalar))
        }
        return output
    }
    
    private func toFlipIt(_ input: String) -> String {
        let flipDict: [Character: Character] = [
            "a": "ɐ", "b": "q", "c": "ɔ", "d": "p", "e": "ǝ", "f": "ɟ", "g": "ƃ", "h": "ɥ",
            "i": "ᴉ", "j": "ɾ", "k": "ʞ", "l": "l", "m": "ɯ", "n": "u", "o": "o", "p": "d",
            "q": "b", "r": "ɹ", "s": "s", "t": "ʇ", "u": "n", "v": "ʌ", "w": "ʍ", "x": "x",
            "y": "ʎ", "z": "z",
            "A": "∀", "B": "ꓭ", "C": "Ɔ", "D": "ᗡ", "E": "Ǝ", "F": "Ⅎ", "G": "פ", "H": "H",
            "I": "I", "J": "ſ", "K": "ʞ", "L": "˥", "M": "W", "N": "N", "O": "O", "P": "Ԁ",
            "Q": "Ό", "R": "ᴚ", "S": "S", "T": "⊥", "U": "∩", "V": "Λ", "W": "M", "X": "X",
            "Y": "⅄", "Z": "Z",
            "0": "0", "1": "Ɩ", "2": "ᄅ", "3": "Ɛ", "4": "ㄣ", "5": "ϛ", "6": "9", "7": "ㄥ",
            "8": "8", "9": "6",
            "?": "¿", "!": "¡", ".": "˙", ",": "'", "'": ",", "\"": "„",
            "(": ")", ")": "(", "[": "]", "]": "[", "{": "}", "}": "{",
            "<": ">", ">": "<", "&": "⅋", "_": "‾"
        ]
        
        let reversed = input.reversed()
        var output = ""
        for char in reversed {
            output.append(flipDict[char] ?? char)
        }
        return output
    }
    
    // MARK: - Actions
    private func copyResult() {
        guard !resultText.isEmpty else { return }
        HapticFeedback.generate(.light)
        UIPasteboard.general.string = resultText
        withAnimation(.easeInOut(duration: 0.2)) {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopied = false
            }
        }
    }
    
    private func shareResult() {
        guard !resultText.isEmpty else { return }
        HapticFeedback.generate(.light)
        showShareSheet = true
    }
    
    private func openInWhatsApp() {
        guard !resultText.isEmpty else { return }
        HapticFeedback.generate(.medium)
        guard let encoded = resultText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        if let whatsappURL = URL(string: "whatsapp://send?text=\(encoded)"),
           UIApplication.shared.canOpenURL(whatsappURL) {
            UIApplication.shared.open(whatsappURL, options: [:], completionHandler: nil)
        } else if let webURL = URL(string: "https://api.whatsapp.com/send?text=\(encoded)") {
            UIApplication.shared.open(webURL, options: [:], completionHandler: nil)
        }
    }
    
    private func dismissKeyboard() {
        isInputFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    FunnyMessagesView()
}
