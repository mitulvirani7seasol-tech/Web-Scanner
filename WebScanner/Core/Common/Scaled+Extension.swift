//
//  Scaled+Extension.swift
//  WebScanner
//

import SwiftUI

extension CGFloat {
    /// Returns value * 1.5 on iPad, or unchanged on iPhone
    var scaled: CGFloat {
        UIDevice.isIPad ? (self * 1.5).rounded() : self
    }
    
    /// Custom multiplier scaling for iPad
    func scaled(by multiplier: CGFloat) -> CGFloat {
        UIDevice.isIPad ? (self * multiplier).rounded() : self
    }
}

extension Double {
    /// Returns value * 1.5 on iPad, or unchanged on iPhone
    var scaled: CGFloat {
        CGFloat(self).scaled
    }
}

extension Int {
    /// Returns value * 1.5 on iPad, or unchanged on iPhone
    var scaled: CGFloat {
        CGFloat(self).scaled
    }
}

extension View {
    /// Applies frame with automatic 1.5x scale on iPad
    func scaledFrame(width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .center) -> some View {
        self.frame(
            width: width?.scaled,
            height: height?.scaled,
            alignment: alignment
        )
    }
    
    /// Square frame with automatic 1.5x scale on iPad
    func scaledSquare(_ size: CGFloat) -> some View {
        self.frame(width: size.scaled, height: size.scaled)
    }
    
    /// Horizontal padding with automatic 1.5x scale on iPad
    func scaledPaddingHorizontal(_ length: CGFloat) -> some View {
        self.padding(.horizontal, length.scaled)
    }
    
    /// Vertical padding with automatic 1.5x scale on iPad
    func scaledPaddingVertical(_ length: CGFloat) -> some View {
        self.padding(.vertical, length.scaled)
    }
    
    /// All edges padding with automatic 1.5x scale on iPad
    func scaledPadding(_ length: CGFloat) -> some View {
        self.padding(length.scaled)
    }
}
