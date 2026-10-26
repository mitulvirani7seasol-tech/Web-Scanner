//
//  PasscodeManager.swift
//  WebScanner
//

import SwiftUI
import Combine

@MainActor
public final class PasscodeManager: ObservableObject {
    public static let shared = PasscodeManager()
    
    private let passcodeKey = "app_lock_passcode"
    private let isPasscodeEnabledKey = "is_passcode_enabled"
    private let securityQuestionKey = "security_question"
    private let securityAnswerKey = "security_answer"
    
    @Published public var isPasscodeEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isPasscodeEnabled, forKey: isPasscodeEnabledKey)
        }
    }
    
    @Published public var isAppUnlocked: Bool = false
    
    private init() {
        self.isPasscodeEnabled = UserDefaults.standard.bool(forKey: isPasscodeEnabledKey)
        // If passcode is not enabled, mark app unlocked
        if !isPasscodeEnabled {
            self.isAppUnlocked = true
        }
    }
    
    public var hasPasscode: Bool {
        guard let code = UserDefaults.standard.string(forKey: passcodeKey), !code.isEmpty else {
            return false
        }
        return true
    }
    
    public func setPasscode(_ code: String, question: String = "What is your favorite pet's name?", answer: String = "") {
        UserDefaults.standard.set(code, forKey: passcodeKey)
        UserDefaults.standard.set(question, forKey: securityQuestionKey)
        UserDefaults.standard.set(answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), forKey: securityAnswerKey)
        self.isPasscodeEnabled = true
        self.isAppUnlocked = true
    }
    
    public func verifyPasscode(_ code: String) -> Bool {
        guard let saved = UserDefaults.standard.string(forKey: passcodeKey) else { return false }
        let matches = (saved == code)
        if matches {
            self.isAppUnlocked = true
        }
        return matches
    }
    
    public func verifySecurityAnswer(_ answer: String) -> Bool {
        guard let savedAnswer = UserDefaults.standard.string(forKey: securityAnswerKey) else { return false }
        return savedAnswer.lowercased() == answer.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    public func getSecurityQuestion() -> String {
        UserDefaults.standard.string(forKey: securityQuestionKey) ?? "What is your favorite pet's name?"
    }
    
    public func disablePasscode() {
        UserDefaults.standard.removeObject(forKey: passcodeKey)
        self.isPasscodeEnabled = false
        self.isAppUnlocked = true
    }
    
    public func lockApp() {
        if isPasscodeEnabled && hasPasscode {
            self.isAppUnlocked = false
        }
    }
}
