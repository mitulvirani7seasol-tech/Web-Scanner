//
//  PasscodeSetupView.swift
//  WebScanner
//

import SwiftUI

public struct PasscodeSetupView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var passcodeManager = PasscodeManager.shared
    
    @State private var passcode: String = ""
    @State private var confirmPasscode: String = ""
    @State private var selectedQuestion: String = "What is your favorite pet's name?"
    @State private var answer: String = ""
    @State private var errorMessage: String = ""
    
    private let questions = [
        "What is your favorite pet's name?",
        "What is your mother's maiden name?",
        "What city were you born in?",
        "What was the name of your first school?",
        "What is your favorite book?"
    ]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background(for: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20.scaled) {
                        ZStack {
                            Circle()
                                .fill(AppColors.primaryGreen.opacity(0.12))
                                .scaledSquare(70)
                            
                            Image(systemName: "key.fill")
                                .font(.system(size: 32.scaled))
                                .foregroundColor(AppColors.primaryGreen)
                        }
                        .padding(.top, 10.scaled)
                        
                        Text("Create App Passcode")
                            .font(.inter(.bold, size: 20))
                            .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        
                        Text("Set a 4-digit PIN to protect your chats and cloned sessions.")
                            .font(.inter(.regular, size: 13))
                            .foregroundColor(AppColors.textSecondary(for: colorScheme))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20.scaled)
                        
                        VStack(alignment: .leading, spacing: 14.scaled) {
                            Text("Passcode (4 Digits)")
                                .font(.inter(.semiBold, size: 14))
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            
                            SecureField("Enter 4-digit PIN", text: $passcode)
                                .keyboardType(.numberPad)
                                .font(.inter(.medium, size: 16))
                                .padding(12.scaled)
                                .background(AppColors.card(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
                            
                            SecureField("Confirm PIN", text: $confirmPasscode)
                                .keyboardType(.numberPad)
                                .font(.inter(.medium, size: 16))
                                .padding(12.scaled)
                                .background(AppColors.card(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
                        }
                        
                        VStack(alignment: .leading, spacing: 10.scaled) {
                            Text("Security Recovery Question")
                                .font(.inter(.semiBold, size: 14))
                                .foregroundColor(AppColors.textPrimary(for: colorScheme))
                            
                            Picker("Question", selection: $selectedQuestion) {
                                ForEach(questions, id: \.self) { q in
                                    Text(q).tag(q)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10.scaled)
                            .background(AppColors.card(for: colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
                            
                            TextField("Enter answer", text: $answer)
                                .font(.inter(.regular, size: 14))
                                .padding(12.scaled)
                                .background(AppColors.card(for: colorScheme))
                                .clipShape(RoundedRectangle(cornerRadius: 12.scaled))
                        }
                        
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.inter(.regular, size: 13))
                                .foregroundColor(.red)
                        }
                        
                        Button(action: savePasscode) {
                            Text("Save Passcode")
                                .font(.inter(.bold, size: 16))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14.scaled)
                                .background(AppColors.primaryGreen)
                                .clipShape(RoundedRectangle(cornerRadius: 14.scaled))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .padding(.top, 10.scaled)
                    }
                    .padding(20.scaled)
                }
            }
            .navigationTitle("Set Passcode")
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
    
    private func savePasscode() {
        guard passcode.count == 4, passcode.allSatisfy({ $0.isNumber }) else {
            errorMessage = "Passcode must be exactly 4 digits."
            return
        }
        guard passcode == confirmPasscode else {
            errorMessage = "Passcodes do not match."
            return
        }
        guard !answer.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter an answer for security recovery."
            return
        }
        
        passcodeManager.setPasscode(passcode, question: selectedQuestion, answer: answer)
        HapticFeedback.generate(.success)
        dismiss()
    }
}

#Preview {
    PasscodeSetupView()
}
