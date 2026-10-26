//
//  QRCodeType.swift
//  WebScanner
//
//

import SwiftUI

public enum QRCodeCategory: String, Hashable, CaseIterable, Identifiable {
    case text
    case url
    case contact
    case email
    case geoLocation
    case sms
    case phone
    case wifi
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .text: return "Text"
        case .url: return "URL"
        case .contact: return "Contact"
        case .email: return "Email"
        case .geoLocation: return "Geo Location"
        case .sms: return "SMS"
        case .phone: return "Phone"
        case .wifi: return "Wi-Fi"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .text: return "Convert your text into QR."
        case .url: return "Generate QR codes for websites."
        case .contact: return "Create QR codes for contacts."
        case .email: return "Create QR codes for email sharing."
        case .geoLocation: return "Share your location instantly."
        case .sms: return "Create QR codes for SMS."
        case .phone: return "Create QR codes for calling."
        case .wifi: return "Generate Wi-Fi QR codes."
        }
    }
    
    public var iconName: String {
        switch self {
        case .text: return "img_Text"
        case .url: return "img_URL"
        case .contact: return "img_Contact"
        case .email: return "img_Email"
        case .geoLocation: return "img_Geo_Location"
        case .sms: return "img_SMS"
        case .phone: return "img_Phone"
        case .wifi: return "img_Wi-Fi"
        }
    }
}

public enum BarcodeCategory: String, Hashable, CaseIterable, Identifiable {
    case ean8
    case ean13
    case upce
    case upca
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .ean8: return "EAN_8"
        case .ean13: return "EAN_13"
        case .upce: return "UPC_E"
        case .upca: return "UPC_A"
        }
    }
    
    public var subtitle: String {
        switch self {
        case .ean8: return "8 digit barcode"
        case .ean13: return "13 digit barcode"
        case .upce: return "6-8 digit barcode"
        case .upca: return "12 digit barcode"
        }
    }
    
    public var iconName: String {
        switch self {
        case .ean8: return "img_EAN_8"
        case .ean13: return "img_EAN_13"
        case .upce: return "img_UPC_E"
        case .upca: return "img_UPC_A"
        }
    }
    
    public var placeholder: String {
        switch self {
        case .ean8: return "Enter 8 digit number..."
        case .ean13: return "Enter 13 digit number..."
        case .upce: return "Enter 6-8 digit number..."
        case .upca: return "Enter 12 digit number..."
        }
    }
    
    public func validate(input: String) -> (isValid: Bool, message: String) {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return (false, "Please enter a valid number.".localized)
        }
        guard trimmed.allSatisfy({ $0.isNumber }) else {
            return (false, "Please enter numbers only.".localized)
        }
        switch self {
        case .ean8:
            if trimmed.count == 8 {
                return (true, "")
            } else {
                return (false, "Please enter a valid 8 digit number.".localized)
            }
        case .ean13:
            if trimmed.count == 13 {
                return (true, "")
            } else {
                return (false, "Please enter a valid 13 digit number.".localized)
            }
        case .upce:
            if trimmed.count >= 6 && trimmed.count <= 8 {
                return (true, "")
            } else {
                return (false, "Please enter a valid 6-8 digit number.".localized)
            }
        case .upca:
            if trimmed.count == 12 {
                return (true, "")
            } else {
                return (false, "Please enter a valid 12 digit number.".localized)
            }
        }
    }
}
