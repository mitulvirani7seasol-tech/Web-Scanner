//
//  CreateQRCodeFormView.swift
//  WebScanner
//
//

import SwiftUI

public struct CreateQRCodeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private enum FormField: Hashable {
        case text
        case url
        case contactName
        case contactPhone
        case contactAddress
        case contactEmail
        case emailAddress
        case emailSubject
        case emailMessage
        case geoLatitude
        case geoLongitude
        case smsPhone
        case smsMessage
        case phoneNumber
        case wifiSSID
        case wifiPassword
    }
    
    @FocusState private var focusedField: FormField?
    
    public let category: QRCodeCategory
    private var navPath: Binding<NavigationPath>?
    
    // Form fields state
    @State private var textInput: String = ""
    @State private var urlInput: String = ""
    
    // Contact
    @State private var contactName: String = ""
    @State private var contactPhone: String = ""
    @State private var contactAddress: String = ""
    @State private var contactEmail: String = ""
    
    // Email
    @State private var emailAddress: String = ""
    @State private var emailSubject: String = ""
    @State private var emailMessage: String = ""
    
    // Geo Location
    @State private var geoLatitude: String = ""
    @State private var geoLongitude: String = ""
    
    // SMS
    @State private var smsPhone: String = ""
    @State private var smsMessage: String = ""
    
    // Phone
    @State private var phoneNumber: String = ""
    
    // Wi-Fi
    @State private var wifiSSID: String = ""
    @State private var wifiPassword: String = ""
    @State private var wifiSecurity: String = "WPA" // WPA, WEP, Open
    
    // Navigation & Validation alert state
    @State private var generatedPayloadToPresent: String? = nil
    @State private var hasNavigatedToDetails: Bool = false
    @State private var showValidationAlert: Bool = false
    @State private var validationAlertTitle: String = ""
    @State private var validationAlertMessage: String = ""
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(category: QRCodeCategory, navPath: Binding<NavigationPath>? = nil) {
        self.category = category
        self.navPath = navPath
    }
    
    // Check if ALL fields of the selected category are fulfilled
    private var isFormFulfilled: Bool {
        switch category {
        case .text:
            return !textInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
        case .url:
            return !urlInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
        case .contact:
            return !contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !contactPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !contactAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !contactEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
        case .email:
            return !emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !emailSubject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !emailMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
        case .geoLocation:
            return !geoLatitude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !geoLongitude.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
        case .sms:
            return !smsPhone.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !smsMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
        case .phone:
            return !phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
        case .wifi:
            let ssidValid = !wifiSSID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if wifiSecurity == "Nopass" {
                return ssidValid
            } else {
                return ssidValid && !wifiPassword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
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
                // 1. Top Custom Navigation Header: < Create QR Code
                headerBar(horizontalPadding: horizontalPadding)
                
                // 2. Main Scrollable Form Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isIPad ? 22 : 18.scaled) {
                        // Category Header Summary Card (matching Screenshot 3)
                        categorySummaryCard
                        
                        // Dynamic Form Inputs
                        formFieldsSection
                        
                        // Generate QR Code Action Button
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
                GenerateQRTabManager.shared.selectedTab = .qrCode
                if let nav = navPath, !nav.wrappedValue.isEmpty {
                    nav.wrappedValue.removeLast()
                } else {
                    dismiss()
                }
            }
        }
        .onChange(of: generatedPayloadToPresent) { payload in
            if payload == nil && hasNavigatedToDetails {
                resetFormFields()
                hasNavigatedToDetails = false
                GenerateQRTabManager.shared.selectedTab = .qrCode
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
            get: { generatedPayloadToPresent != nil && navPath == nil },
            set: { if !$0 { generatedPayloadToPresent = nil } }
        )) {
            if let payload = generatedPayloadToPresent {
                QRCodeDetailsView(resultText: payload, navPath: navPath)
            }
        }
    }
    
    // MARK: - Header Bar (< Create QR Code)
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
            
            Text("Create QR Code".localized)
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
                .frame(width: isIPad ? 46 : 40.scaled, height: isIPad ? 46 : 40.scaled)
            
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
    
    // MARK: - Dynamic Form Fields
    @ViewBuilder
    private var formFieldsSection: some View {
        VStack(spacing: isIPad ? 18 : 14.scaled) {
            switch category {
            case .text:
                formInputField(
                    title: "Text".localized,
                    placeholder: "Enter text here...".localized,
                    text: $textInput,
                    field: .text
                )
                
            case .url:
                formInputField(
                    title: "URL".localized,
                    placeholder: "Enter website URL here...".localized,
                    text: $urlInput,
                    field: .url,
                    keyboardType: .URL
                )
                
            case .contact:
                // Contact Fields (Matches Screenshot 3)
                formInputField(
                    title: "Name".localized,
                    placeholder: "Enter name here...".localized,
                    text: $contactName,
                    field: .contactName
                )
                formInputField(
                    title: "Phone".localized,
                    placeholder: "Enter phone number here...".localized,
                    text: $contactPhone,
                    field: .contactPhone,
                    keyboardType: .phonePad
                )
                formInputField(
                    title: "Address".localized,
                    placeholder: "Enter address here...".localized,
                    text: $contactAddress,
                    field: .contactAddress
                )
                formInputField(
                    title: "Email".localized,
                    placeholder: "Enter email here...".localized,
                    text: $contactEmail,
                    field: .contactEmail,
                    keyboardType: .emailAddress
                )
                
            case .email:
                formInputField(
                    title: "Email".localized,
                    placeholder: "Enter email here...".localized,
                    text: $emailAddress,
                    field: .emailAddress,
                    keyboardType: .emailAddress
                )
                formInputField(
                    title: "Subject".localized,
                    placeholder: "Enter subject here...".localized,
                    text: $emailSubject,
                    field: .emailSubject
                )
                formInputField(
                    title: "Message".localized,
                    placeholder: "Enter message here...".localized,
                    text: $emailMessage,
                    field: .emailMessage
                )
                
            case .geoLocation:
                formInputField(
                    title: "Latitude".localized,
                    placeholder: "Enter latitude here...".localized,
                    text: $geoLatitude,
                    field: .geoLatitude,
                    keyboardType: .decimalPad
                )
                formInputField(
                    title: "Longitude".localized,
                    placeholder: "Enter longitude here...".localized,
                    text: $geoLongitude,
                    field: .geoLongitude,
                    keyboardType: .decimalPad
                )
                
            case .sms:
                formInputField(
                    title: "Phone".localized,
                    placeholder: "Enter phone number here...".localized,
                    text: $smsPhone,
                    field: .smsPhone,
                    keyboardType: .phonePad
                )
                formInputField(
                    title: "Message".localized,
                    placeholder: "Enter message here...".localized,
                    text: $smsMessage,
                    field: .smsMessage
                )
                
            case .phone:
                formInputField(
                    title: "Phone".localized,
                    placeholder: "Enter phone number here...".localized,
                    text: $phoneNumber,
                    field: .phoneNumber,
                    keyboardType: .phonePad
                )
                
            case .wifi:
                // 1. Wi-Fi SSID (Matches Screenshot)
                formInputField(
                    title: "Wi-Fi SSID".localized,
                    placeholder: "Enter SSID here...".localized,
                    text: $wifiSSID,
                    field: .wifiSSID
                )
                
                // 2. Select Security Type (WPA | WEP | Nopass)
                wifiSecurityPicker
                
                // 3. Wi-Fi Password (Visible when not Nopass)
                if wifiSecurity != "Nopass" {
                    formInputField(
                        title: "Wi-Fi Password".localized,
                        placeholder: "Enter password here...".localized,
                        text: $wifiPassword,
                        field: .wifiPassword
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
    
    // MARK: - Reusable Form Input Field
    private func formInputField(
        title: String,
        placeholder: String,
        text: Binding<String>,
        field: FormField,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            TextField(placeholder, text: text)
                .focused($focusedField, equals: field)
                .keyboardType(keyboardType)
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
        }
    }
    
    // MARK: - Wi-Fi Security Picker (Matches Screenshot)
    private var wifiSecurityPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Security Type".localized)
                .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            HStack(spacing: 0) {
                let securityOptions = ["WPA", "WEP", "Nopass"]
                ForEach(0..<securityOptions.count, id: \.self) { index in
                    let sec = securityOptions[index]
                    let isSelected = wifiSecurity == sec
                    
                    Button(action: {
                        HapticFeedback.generate(.selection)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            wifiSecurity = sec
                        }
                    }) {
                        Text(sec.localized)
                            .font(.inter(.bold, size: isIPad ? 16 : 14.scaled))
                            .foregroundColor(isSelected ? .white : AppColors.textSecondary(for: colorScheme))
                            .frame(maxWidth: .infinity)
                            .frame(height: isIPad ? 48 : 42.scaled)
                            .background(
                                Capsule()
                                    .fill(isSelected ? Color(hex: "#16A34A") : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Vertical divider between unselected adjacent options
                    if index < securityOptions.count - 1 {
                        let nextSec = securityOptions[index + 1]
                        if wifiSecurity != sec && wifiSecurity != nextSec {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 1, height: isIPad ? 20 : 16.scaled)
                        } else {
                            Spacer()
                                .frame(width: 1)
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
                                Color.white.opacity(colorScheme == .dark ? 0.3 : 0.6),
                                Color.white.opacity(colorScheme == .dark ? 0.05 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())
            .glassModifier(cornerRadius: 24)
        }
    }
    
    // MARK: - Generate Action Button
    private var generateButton: some View {
        Button(action: {
            HapticFeedback.generate(.light)
            dismissKeyboard()
            TR_AdCountViewModel.sharedd.registerTap {
                generateAndNavigate()
            }
        }) {
            Text("Generate QR Code".localized)
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
    
    // MARK: - Payload Generation Logic
    private func buildPayload() -> String {
        switch category {
        case .text:
            return textInput.trimmingCharacters(in: .whitespacesAndNewlines)
            
        case .url:
            let trimmed = urlInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
                return trimmed
            } else {
                return "https://\(trimmed)"
            }
            
        case .contact:
            // vCard 3.0 format matching Screenshot 4
            var lines: [String] = []
            lines.append("BEGIN : VCARD")
            lines.append("VERSION : 3.0")
            if !contactName.isEmpty {
                lines.append("FN : \(contactName)")
            }
            if !contactPhone.isEmpty {
                lines.append("TEL : \(contactPhone)")
            }
            if !contactAddress.isEmpty {
                lines.append("ADR : \(contactAddress)")
            }
            if !contactEmail.isEmpty {
                lines.append("EMAIL : \(contactEmail)")
            }
            return lines.joined(separator: "\n")
            
        case .email:
            let to = emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            let sub = emailSubject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let body = emailMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            return "mailto:\(to)?subject=\(sub)&body=\(body)"
            
        case .geoLocation:
            let lat = geoLatitude.trimmingCharacters(in: .whitespacesAndNewlines)
            let lon = geoLongitude.trimmingCharacters(in: .whitespacesAndNewlines)
            return "geo:\(lat),\(lon)"
            
        case .sms:
            let phone = smsPhone.trimmingCharacters(in: .whitespacesAndNewlines)
            let msg = smsMessage.trimmingCharacters(in: .whitespacesAndNewlines)
            return "SMSTO:\(phone):\(msg)"
            
        case .phone:
            let phone = phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            return "tel:\(phone)"
            
        case .wifi:
            let ssid = wifiSSID.trimmingCharacters(in: .whitespacesAndNewlines)
            let pass = wifiPassword.trimmingCharacters(in: .whitespacesAndNewlines)
            if wifiSecurity == "Nopass" {
                return "WIFI:T:nopass;S:\(ssid);;"
            } else {
                return "WIFI:T:\(wifiSecurity);S:\(ssid);P:\(pass);;"
            }
        }
    }
    
    private func generateAndNavigate() {
        // Validation checks per category before generating
        switch category {
        case .phone:
            guard isValidPhone(phoneNumber) else {
                showValidationError(
                    title: "Invalid Phone Number".localized,
                    message: "Please enter a valid phone number.".localized
                )
                return
            }
            
        case .contact:
            guard isValidPhone(contactPhone) else {
                showValidationError(
                    title: "Invalid Phone Number".localized,
                    message: "Please enter a valid phone number.".localized
                )
                return
            }
            guard isValidEmail(contactEmail) else {
                showValidationError(
                    title: "Invalid Email".localized,
                    message: "Please enter a valid email address.".localized
                )
                return
            }
            
        case .sms:
            guard isValidPhone(smsPhone) else {
                showValidationError(
                    title: "Invalid Phone Number".localized,
                    message: "Please enter a valid phone number.".localized
                )
                return
            }
            
        case .email:
            guard isValidEmail(emailAddress) else {
                showValidationError(
                    title: "Invalid Email".localized,
                    message: "Please enter a valid email address.".localized
                )
                return
            }
            
        case .url:
            guard isValidURL(urlInput) else {
                showValidationError(
                    title: "Invalid URL".localized,
                    message: "Please enter a valid website URL.".localized
                )
                return
            }
            
        case .geoLocation:
            guard isValidLatitude(geoLatitude) && isValidLongitude(geoLongitude) else {
                showValidationError(
                    title: "Invalid Location".localized,
                    message: "Please enter valid coordinates (-90 to 90 for latitude, -180 to 180 for longitude).".localized
                )
                return
            }
            
        case .wifi:
            let pass = wifiPassword.trimmingCharacters(in: .whitespacesAndNewlines)
            if wifiSecurity == "WPA" && pass.count < 8 {
                showValidationError(
                    title: "Invalid Password".localized,
                    message: "Wi-Fi password must be at least 8 characters for WPA.".localized
                )
                return
            } else if wifiSecurity == "WEP" && pass.count < 5 {
                showValidationError(
                    title: "Invalid Password".localized,
                    message: "Wi-Fi password must be at least 5 characters for WEP.".localized
                )
                return
            }
            
        case .text:
            break
        }
        
        let payload = buildPayload()
        guard !payload.isEmpty else { return }
        
        hasNavigatedToDetails = true
        if let nav = navPath {
            nav.wrappedValue.append(HomeDestination.qrCodeDetails(scannedText: payload))
        } else {
            generatedPayloadToPresent = payload
        }
    }
    
    private func showValidationError(title: String, message: String) {
        HapticFeedback.generate(.error)
        validationAlertTitle = title
        validationAlertMessage = message
        showValidationAlert = true
    }
    
    private func resetFormFields() {
        textInput = ""
        urlInput = ""
        contactName = ""
        contactPhone = ""
        contactAddress = ""
        contactEmail = ""
        emailAddress = ""
        emailSubject = ""
        emailMessage = ""
        geoLatitude = ""
        geoLongitude = ""
        smsPhone = ""
        smsMessage = ""
        phoneNumber = ""
        wifiSSID = ""
        wifiPassword = ""
        wifiSecurity = "WPA"
    }
    
    // MARK: - Validation Helpers
    private func isValidURL(_ urlString: String) -> Bool {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains(" ") else { return false }
        let formatted = (trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://")) ? trimmed : "https://\(trimmed)"
        guard let url = URL(string: formatted), let host = url.host else { return false }
        return host.contains(".") && host.count >= 3
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: trimmed)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let allowed = CharacterSet(charactersIn: "+0123456789 -()")
        guard trimmed.unicodeScalars.allSatisfy({ allowed.contains($0) }) else { return false }
        let digits = trimmed.filter { $0.isNumber }
        return digits.count >= 7 && digits.count <= 15
    }
    
    private func isValidLatitude(_ lat: String) -> Bool {
        let trimmed = lat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let val = Double(trimmed) else { return false }
        return val >= -90.0 && val <= 90.0
    }
    
    private func isValidLongitude(_ lon: String) -> Bool {
        let trimmed = lon.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let val = Double(trimmed) else { return false }
        return val >= -180.0 && val <= 180.0
    }
    
    private func handleBack() {
        if let nav = navPath, !nav.wrappedValue.isEmpty {
            nav.wrappedValue.removeLast()
        } else {
            dismiss()
        }
    }
    
    private func dismissKeyboard() {
        focusedField = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    CreateQRCodeFormView(category: .contact)
}
