//
//  Font+Extension.swift
//  WebScanner
//

import SwiftUI

extension Font {
    enum InterWeight {
        case thin
        case extraLight
        case light
        case regular
        case medium
        case semiBold
        case bold
        case extraBold
        case black
        
        var postscriptName: String {
            switch self {
            case .thin: return "Inter24pt-Thin"
            case .extraLight: return "Inter24pt-ExtraLight"
            case .light: return "Inter24pt-Light"
            case .regular: return "Inter24pt-Regular"
            case .medium: return "Inter24pt-Medium"
            case .semiBold: return "Inter24pt-SemiBold"
            case .bold: return "Inter24pt-Bold"
            case .extraBold: return "Inter24pt-ExtraBold"
            case .black: return "Inter24pt-Black"
            }
        }
        
        var systemWeight: Font.Weight {
            switch self {
            case .thin: return .thin
            case .extraLight: return .ultraLight
            case .light: return .light
            case .regular: return .regular
            case .medium: return .medium
            case .semiBold: return .semibold
            case .bold: return .bold
            case .extraBold: return .heavy
            case .black: return .black
            }
        }
    }
    
    static func inter(_ weight: InterWeight = .regular, size: CGFloat, autoScaleForPad: Bool = true) -> Font {
        let finalSize = (autoScaleForPad && UIDevice.isIPad) ? (size * 1.5).rounded() : size
        if UIFont(name: weight.postscriptName, size: finalSize) != nil {
            return .custom(weight.postscriptName, size: finalSize)
        } else {
            return .system(size: finalSize, weight: weight.systemWeight)
        }
    }
}
