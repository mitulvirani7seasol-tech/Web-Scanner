//
//  UIDevice+Extension.swift
//  WebScanner
//

import UIKit

extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static var padMultiplier: CGFloat {
        isIPad ? 1.5 : 1.0
    }
}
