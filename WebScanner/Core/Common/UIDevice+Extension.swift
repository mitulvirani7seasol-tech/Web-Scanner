//
//  UIDevice+Extension.swift
//  WebScanner
//

import UIKit

extension UIDevice {
    /// True if the current device is an iPad
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    /// Multiplier for scaling UI on iPad (1.5x)
    static var padMultiplier: CGFloat {
        isIPad ? 1.5 : 1.0
    }
}
