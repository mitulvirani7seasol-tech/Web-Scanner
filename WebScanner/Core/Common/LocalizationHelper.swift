//
//  LocalizationHelper.swift
//  WebScanner
//

import Foundation
import SwiftUI
import Combine

public class LocalizationHelper: ObservableObject {
    public static let shared = LocalizationHelper()
    
    @Published public var currentLanguage: String = "en"
    @Published public var refreshID: UUID = UUID()
    
    private var bundle: Bundle? = nil
    
    private init() {
        let code = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
        setLanguage(code: code)
    }
    
    public func setLanguage(code: String) {
        UserDefaults.standard.set(code, forKey: "appLanguage")
        UserDefaults.standard.synchronize()
        self.currentLanguage = code
        
        let targetCode = (code == "pt" ? "pt-PT" : code)
        if let path = Bundle.main.path(forResource: targetCode, ofType: "lproj") {
            bundle = Bundle(path: path)
        } else if let path = Bundle.main.path(forResource: code, ofType: "lproj") {
            bundle = Bundle(path: path)
        } else {
            bundle = Bundle.main
        }
        
        DispatchQueue.main.async {
            self.refreshID = UUID()
        }
    }
    
    public func localizedString(for key: String) -> String {
        if let localized = bundle?.localizedString(forKey: key, value: nil, table: nil), localized != key {
            return localized
        }
        // Fallback to English bundle if translation missing
        if let enPath = Bundle.main.path(forResource: "en", ofType: "lproj"),
           let enBundle = Bundle(path: enPath) {
            let enVal = enBundle.localizedString(forKey: key, value: nil, table: nil)
            if enVal != key { return enVal }
        }
        return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }
}

public extension String {
    var localized: String {
        return LocalizationHelper.shared.localizedString(for: self)
    }
}
