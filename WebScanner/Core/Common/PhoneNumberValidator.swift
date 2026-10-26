//
//  PhoneNumberValidator.swift
//  WebScanner
//

import Foundation

public struct PhoneNumberValidationResult {
    public let isValid: Bool
    public let errorMessage: String
    
    public init(isValid: Bool, errorMessage: String) {
        self.isValid = isValid
        self.errorMessage = errorMessage
    }
}

public enum PhoneNumberValidator {
    
    /// Returns allowed subscriber digit lengths for a country ISO code
    public static func allowedLengths(for countryCode: String) -> [Int] {
        switch countryCode.uppercased() {
        case "IN": // India
            return [10]
        case "US", "CA": // USA, Canada
            return [10]
        case "GB": // UK
            return [10, 11]
        case "AU": // Australia
            return [9, 10]
        case "DE": // Germany
            return [10, 11]
        case "FR": // France
            return [9, 10]
        case "IT": // Italy
            return [9, 10]
        case "ES": // Spain
            return [9]
        case "AE": // UAE
            return [9]
        case "SA": // Saudi Arabia
            return [9]
        case "PK": // Pakistan
            return [10]
        case "BD": // Bangladesh
            return [10]
        case "RU", "KZ": // Russia, Kazakhstan
            return [10]
        case "JP": // Japan
            return [10, 11]
        case "CN": // China
            return [11]
        case "BR": // Brazil
            return [10, 11]
        case "MX": // Mexico
            return [10]
        case "AR": // Argentina
            return [10]
        case "ZA": // South Africa
            return [9]
        case "NG": // Nigeria
            return [10]
        case "EG": // Egypt
            return [10]
        case "PH": // Philippines
            return [10]
        case "ID": // Indonesia
            return [9, 10, 11, 12]
        case "MY": // Malaysia
            return [9, 10]
        case "SG": // Singapore
            return [8]
        case "TH": // Thailand
            return [9]
        case "VN": // Vietnam
            return [9, 10]
        case "TR": // Turkey
            return [10]
        case "KR": // South Korea
            return [9, 10, 11]
        case "NZ": // New Zealand
            return [8, 9, 10]
        case "NL": // Netherlands
            return [9]
        case "BE": // Belgium
            return [9]
        case "CH": // Switzerland
            return [9]
        case "AT": // Austria
            return [10, 11]
        case "SE": // Sweden
            return [9]
        case "NO": // Norway
            return [8]
        case "DK": // Denmark
            return [8]
        case "FI": // Finland
            return [9, 10]
        case "PL": // Poland
            return [9]
        case "PT": // Portugal
            return [9]
        case "GR": // Greece
            return [10]
        case "IL": // Israel
            return [9]
        case "KW", "QA", "OM", "BH", "HK": // Gulf countries & HK
            return [8]
        case "TW": // Taiwan
            return [9]
        case "LK": // Sri Lanka
            return [9]
        case "NP": // Nepal
            return [10]
        default:
            return Array(6...13)
        }
    }
    
    public static func validate(number: String, country: CountryCodeItem) -> PhoneNumberValidationResult {
        let clean = number.filter { "0123456789".contains($0) }
        guard !clean.isEmpty else {
            return PhoneNumberValidationResult(
                isValid: false,
                errorMessage: String(format: "Please enter a valid phone number for %@.".localized, country.name)
            )
        }
        
        let withoutLeadingZero = clean.hasPrefix("0") ? String(clean.drop(while: { $0 == "0" })) : clean
        let allowed = allowedLengths(for: country.code)
        
        let isMatch = allowed.contains(clean.count) || allowed.contains(withoutLeadingZero.count)
        
        if isMatch {
            return PhoneNumberValidationResult(isValid: true, errorMessage: "")
        }
        
        // Build localized error message
        if allowed.count == 1, let exact = allowed.first {
            let msg = String(format: "Please enter a valid %d-digit phone number for %@.".localized, exact, country.name)
            return PhoneNumberValidationResult(isValid: false, errorMessage: msg)
        } else {
            let msg = String(format: "Please enter a valid phone number for %@.".localized, country.name)
            return PhoneNumberValidationResult(isValid: false, errorMessage: msg)
        }
    }
}
