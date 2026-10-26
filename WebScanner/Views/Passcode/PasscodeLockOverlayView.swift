//
//  PasscodeLockOverlayView.swift
//  WebScanner
//

import SwiftUI
import LocalAuthentication

public struct PasscodeLockOverlayView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var passcodeManager = PasscodeManager.shared
    
    @State private var enteredPin: String = ""
    @State private var errorMessage: String = ""
    @State private var shakeOffset: CGFloat = 0
    @State private var showForgotSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 28.scaled) {
                Spacer()
                
                // App Logo / Lock Icon
                ZStack {
                    Circle()
                        .fill(AppColors.primaryGreen.opacity(0.15))
                        .scaledSquare(80)
                    
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 40.scaled))
                        .foregroundColor(AppColors.primaryGreen)
                }
                
                VStack(spacing: 8.scaled) {
                    Text("Enter Passcode")
                        .font(.inter(.bold, size: 22))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    
                    Text(errorMessage.isEmpty ? "Please enter your 4-digit security PIN" : errorMessage)
                        .font(.inter(.regular, size: 13))
                        .foregroundColor(errorMessage.isEmpty ? AppColors.textSecondary(for: colorScheme) : .red)
                }
                
                // 4 PIN Dots
                HStack(spacing: 20.scaled) {
                    ForEach(0..<4, id: \.self) { idx in
                        Circle()
                            .fill(idx < enteredPin.count ? AppColors.primaryGreen : AppColors.border(for: colorScheme))
                            .scaledSquare(16)
                            .scaleEffect(idx < enteredPin.count ? 1.15 : 1.0)
                            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: enteredPin.count)
                    }
                }
                .offset(x: shakeOffset)
                .padding(.vertical, 10.scaled)
                
                Spacer()
                
                // Numeric Keypad
                numericKeypad
                
                // Forgot Passcode Button
                Button(action: {
                    HapticFeedback.generate(.light)
                    showForgotSheet = true
                }) {
                    Text("Forgot Passcode?")
                        .font(.inter(.semiBold, size: 14))
                        .foregroundColor(AppColors.primaryGreen)
                        .padding(.vertical, 8.scaled)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.bottom, 20.scaled)
            }
            .padding(.horizontal, 24.scaled)
        }
        .sheet(isPresented: $showForgotSheet) {
            PasscodeRecoverySheet()
        }
    }
    
    // MARK: - Keypad
    private var numericKeypad: some View {
        let keys: [[String]] = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["bio", "0", "del"]
        ]
        
        return VStack(spacing: 16.scaled) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 28.scaled) {
                    ForEach(row, id: \.self) { key in
                        keypadButton(for: key)
                    }
                }
            }
        }
    }
    
    private func keypadButton(for key: String) -> some View {
        Button(action: {
            handleKeyTap(key)
        }) {
            ZStack {
                Circle()
                    .fill(AppColors.card(for: colorScheme))
                    .scaledSquare(70)
                    .overlay(
                        Circle()
                            .stroke(AppColors.border(for: colorScheme), lineWidth: 0.5)
                    )
                
                if key == "del" {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 20.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                } else if key == "bio" {
                    Image(systemName: "faceid")
                        .font(.system(size: 22.scaled))
                        .foregroundColor(AppColors.primaryGreen)
                } else {
                    Text(key)
                        .font(.inter(.semiBold, size: 24))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func handleKeyTap(_ key: String) {
        if key == "del" {
            HapticFeedback.generate(.light)
            if !enteredPin.isEmpty {
                enteredPin.removeLast()
                errorMessage = ""
            }
        } else if key == "bio" {
            authenticateWithBiometrics()
        } else {
            guard enteredPin.count < 4 else { return }
            HapticFeedback.generate(.light)
            enteredPin.append(key)
            
            if enteredPin.count == 4 {
                verifyPin()
            }
        }
    }
    
    private func verifyPin() {
        if passcodeManager.verifyPasscode(enteredPin) {
            HapticFeedback.generate(.success)
            errorMessage = ""
        } else {
            HapticFeedback.generate(.error)
            errorMessage = "Incorrect passcode. Try again."
            shake()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                enteredPin = ""
            }
        }
    }
    
    private func shake() {
        withAnimation(.default) {
            shakeOffset = -12
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.default) { self.shakeOffset = 12 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.default) { self.shakeOffset = -6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            withAnimation(.default) { self.shakeOffset = 0 }
        }
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock WebScanner") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        passcodeManager.isAppUnlocked = true
                        HapticFeedback.generate(.success)
                    }
                }
            }
        }
    }
}

// MARK: - PasscodeRecoverySheet
public struct PasscodeRecoverySheet: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var passcodeManager = PasscodeManager.shared
    
    @State private var answer: String = ""
    @State private var newPasscode: String = ""
    @State private var confirmPasscode: String = ""
    @State private var isAnswerVerified: Bool = false
    @State private var errorText: String = ""
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20.scaled) {
                    if !isAnswerVerified {
                        // Answer Security Question
                        VStack(alignment: .leading, spacing: 8.scaled) {
                            Text("Security Question")
                                .font(.inter(.bold, size: 16))
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            
                            Text(passcodeManager.getSecurityQuestion())
                                .font(.inter(.medium, size: 14))
                                .foregroundColor(AppColors.primaryGreen)
                                .padding(12.scaled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.card(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
                        }
                        
                        VStack(alignment: .leading, spacing: 8.scaled) {
                            Text("Your Answer")
                                .font(.inter(.semiBold, size: 14))
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            
                            TextField("Enter answer", text: $answer)
                                .font(.inter(.regular, size: 15))
                                .padding(12.scaled)
                                .background(AppColors.card(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
                        }
                        
                        if !errorText.isEmpty {
                            Text(errorText)
                                .font(.inter(.regular, size: 13))
                                .foregroundColor(.red)
                        }
                        
                        Button(action: verifyAnswer) {
                            Text("Verify Answer")
                                .font(.inter(.bold, size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14.scaled)
                                .background(AppColors.primaryGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 14.scaled))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    } else {
                        // Enter New Passcode
                        VStack(alignment: .leading, spacing: 14.scaled) {
                            Text("Set New 4-Digit Passcode")
                                .font(.inter(.bold, size: 16))
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            
                            SecureField("New Passcode (4 digits)", text: $newPasscode)
                                .keyboardType(.numberPad)
                                .font(.inter(.medium, size: 16))
                                .padding(12.scaled)
                                .background(AppColors.card(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
                            
                            SecureField("Confirm Passcode", text: $confirmPasscode)
                                .keyboardType(.numberPad)
                                .font(.inter(.medium, size: 16))
                                .padding(12.scaled)
                                .background(AppColors.card(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
                        }
                        
                        if !errorText.isEmpty {
                            Text(errorText)
                                .font(.inter(.regular, size: 13))
                                .foregroundColor(.red)
                        }
                        
                        Button(action: saveNewPasscode) {
                            Text("Save Passcode & Unlock")
                                .font(.inter(.bold, size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14.scaled)
                                .background(AppColors.primaryGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 14.scaled))
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    Spacer()
                }
                .padding(20.scaled)
            }
            .navigationTitle("Passcode Recovery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                }
            }
        }
    }
    
    private func verifyAnswer() {
        if passcodeManager.verifySecurityAnswer(answer) {
            errorText = ""
            isAnswerVerified = true
            HapticFeedback.generate(.success)
        } else {
            errorText = "Incorrect answer. Please try again."
            HapticFeedback.generate(.error)
        }
    }
    
    private func saveNewPasscode() {
        guard newPasscode.count == 4, newPasscode.allSatisfy({ $0.isNumber }) else {
            errorText = "Passcode must be exactly 4 digits."
            return
        }
        guard newPasscode == confirmPasscode else {
            errorText = "Passcodes do not match."
            return
        }
        
        passcodeManager.setPasscode(newPasscode, question: passcodeManager.getSecurityQuestion(), answer: answer)
        HapticFeedback.generate(.success)
        dismiss()
    }
}

#Preview {
    PasscodeLockOverlayView()
}
