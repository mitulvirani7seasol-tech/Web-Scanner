//
//  Scaled+Extension.swift
//  WebScanner
//

import SwiftUI

extension CGFloat {
    var scaled: CGFloat {
        UIDevice.isIPad ? (self * 1.5).rounded() : self
    }
    
    func scaled(by multiplier: CGFloat) -> CGFloat {
        UIDevice.isIPad ? (self * multiplier).rounded() : self
    }
}

extension Double {
    var scaled: CGFloat {
        CGFloat(self).scaled
    }
}

extension Int {
    var scaled: CGFloat {
        CGFloat(self).scaled
    }
}

extension View {
    func scaledFrame(width: CGFloat? = nil, height: CGFloat? = nil, alignment: Alignment = .center) -> some View {
        self.frame(
            width: width?.scaled,
            height: height?.scaled,
            alignment: alignment
        )
    }
    
    func scaledSquare(_ size: CGFloat) -> some View {
        self.frame(width: size.scaled, height: size.scaled)
    }
    
    func scaledPaddingHorizontal(_ length: CGFloat) -> some View {
        self.padding(.horizontal, length.scaled)
    }
    
    func scaledPaddingVertical(_ length: CGFloat) -> some View {
        self.padding(.vertical, length.scaled)
    }
    
    func scaledPadding(_ length: CGFloat) -> some View {
        self.padding(length.scaled)
    }
}
