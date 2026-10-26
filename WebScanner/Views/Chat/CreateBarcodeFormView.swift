//
//  CreateBarcodeFormView.swift
//  WebScanner
//
//

import SwiftUI

public struct CreateBarcodeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFieldFocused: Bool
    
    public let category: BarcodeCategory
    private var navPath: Binding<NavigationPath>?
    
    @State private var barcodeInput: String = ""
    @State private var generatedBarcodeToPresent: String? = nil
    @State private var hasNavigatedToDetails: Bool = false
    
    // Validation alert state
    @State private var showValidationAlert: Bool = false
    @State private var validationAlertTitle: String = ""
    @State private var validationAlertMessage: String = ""
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var isFormFulfilled: Bool {
        !barcodeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public init(category: BarcodeCategory, navPath: Binding<NavigationPath>? = nil) {
        self.category = category
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
                // 1. Top Custom Navigation Header: < Create Barcode
                headerBar(horizontalPadding: horizontalPadding)
                
                // 2. Main Scrollable Form Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isIPad ? 22 : 18.scaled) {
                        // Category Header Summary Card (Matches Screenshots 1-4)
                        categorySummaryCard
                        
                        // Input Field Card
                        inputFieldSection
                        
                        // Generate Barcode Action Button
                        generateButton
                            .padding(.top, isIPad ? 14 : 10)
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, isIPad ? 14 : 10)
                    .padding(.bottom, max(geo.safeAreaInsets.bottom, 24) + 20)
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
            if hasNavigatedToDetails {
                resetFormFields()
                hasNavigatedToDetails = false
                GenerateQRTabManager.shared.selectedTab = .barcode
                if let nav = navPath, !nav.wrappedValue.isEmpty {
                    nav.wrappedValue.removeLast()
                } else {
                    dismiss()
                }
            }
        }
        .onChange(of: generatedBarcodeToPresent) { payload in
            if payload == nil && hasNavigatedToDetails {
                resetFormFields()
                hasNavigatedToDetails = false
                GenerateQRTabManager.shared.selectedTab = .barcode
                dismiss()
            }
        }
        .alert(validationAlertTitle, isPresented: $showValidationAlert) {
            Button("OK".localized, role: .cancel) {}
        } message: {
            Text(validationAlertMessage)
        }
        // Fallback navigation when navPath is nil
        .navigationDestination(isPresented: Binding(
            get: { generatedBarcodeToPresent != nil && navPath == nil },
            set: { if !$0 { generatedBarcodeToPresent = nil } }
        )) {
            if let payload = generatedBarcodeToPresent {
                BarcodeDetailsView(barcodeText: payload, category: category, navPath: navPath)
            }
        }
    }
    
    // MARK: - Header Bar (< Create Barcode)
    private func headerBar(horizontalPadding: CGFloat) -> some View {
        HStack(alignment: .center, spacing: 14) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismissKeyboard()
                handleBack()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 17, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
            }
            .buttonStyle(PlainButtonStyle())
            
            Text("Create Barcode".localized)
                .font(.inter(.bold, size: isIPad ? 20 : 20))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.top, isIPad ? 16 : 10)
        .padding(.bottom, isIPad ? 10 : 6)
    }
    
    // MARK: - Category Header Summary Card
    private var categorySummaryCard: some View {
        HStack(spacing: 14) {
            Image(category.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: isIPad ? 56 : 40.scaled, height: isIPad ? 56 : 40.scaled)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(category.title.localized)
                    .font(.inter(.bold, size: isIPad ? 17 : 15.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Text(category.subtitle.localized)
                    .font(.inter(.regular, size: isIPad ? 13 : 11.5.scaled))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
            }
            
            Spacer()
        }
        .padding(.horizontal, isIPad ? 18 : 14.scaled)
        .padding(.vertical, isIPad ? 14 : 12.scaled)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
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
        .glassModifier(cornerRadius: 16)
    }
    
    // MARK: - Input Field Section
    private var inputFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.title.localized)
                .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            TextField(category.placeholder.localized, text: $barcodeInput)
                .focused($isFieldFocused)
                .keyboardType(.numberPad)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .font(.inter(.regular, size: isIPad ? 15 : 13.5.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                .padding(.horizontal, 14)
                .padding(.vertical, isIPad ? 15 : 13.scaled)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.05))
                )
                .contentShape(Rectangle())
                .glassModifier(cornerRadius: 14)
                .onChange(of: barcodeInput) { newValue in
                    // Only allow numbers and constrain max length
                    let filtered = newValue.filter { $0.isNumber }
                    let maxLength = category == .ean13 ? 13 : (category == .upca ? 12 : 8)
                    if filtered.count > maxLength {
                        barcodeInput = String(filtered.prefix(maxLength))
                    } else if filtered != newValue {
                        barcodeInput = filtered
                    }
                }
        }
    }
    
    // MARK: - Generate Barcode Button
    private var generateButton: some View {
        Button(action: {
            HapticFeedback.generate(.light)
            dismissKeyboard()
            TR_AdCountViewModel.sharedd.registerTap {
                generateAndNavigate()
            }
        }) {
            Text("Generate Barcode".localized)
                .font(.inter(.bold, size: isIPad ? 18 : 16.scaled))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: isIPad ? 56 : 50.scaled)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(isFormFulfilled ? Color(hex: "#16A34A") : Color(hex: "#16A34A").opacity(0.4))
                )
                .shadow(
                    color: isFormFulfilled ? Color(hex: "#16A34A").opacity(0.35) : Color.clear,
                    radius: 8,
                    x: 0,
                    y: 4
                )
        }
        .disabled(!isFormFulfilled)
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle())
    }
    
    // MARK: - Actions & Validation
    private func generateAndNavigate() {
        let validation = category.validate(input: barcodeInput)
        guard validation.isValid else {
            HapticFeedback.generate(.error)
            validationAlertTitle = "Invalid Barcode".localized
            validationAlertMessage = validation.message
            showValidationAlert = true
            return
        }
        
        let trimmed = barcodeInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        hasNavigatedToDetails = true
        if let nav = navPath {
            nav.wrappedValue.append(HomeDestination.barcodeDetails(barcodeText: trimmed, category: category))
        } else {
            generatedBarcodeToPresent = trimmed
        }
    }
    
    private func resetFormFields() {
        barcodeInput = ""
    }
    
    private func handleBack() {
        if let nav = navPath, !nav.wrappedValue.isEmpty {
            nav.wrappedValue.removeLast()
        } else {
            dismiss()
        }
    }
    
    private func dismissKeyboard() {
        isFieldFocused = false
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    CreateBarcodeFormView(category: .ean8)
}
