//
//  IntroView.swift
//  WebScanner
//

import SwiftUI

public struct IntroItem: Identifiable {
    public let id: Int
    public let imageName: String
    public let iconName: String
    public let titleKey: String
    public let subtitleKey: String
    public let buttonTextKey: String
}

public struct IntroCurveShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let curveHeight: CGFloat = 28.scaled
        path.move(to: CGPoint(x: 0, y: curveHeight))
        path.addQuadCurve(
            to: CGPoint(x: rect.width, y: curveHeight),
            control: CGPoint(x: rect.width / 2, y: 0)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

public struct IntroLandscapeCurveShape: Shape {
    public var curveDepth: CGFloat = 80

    public init(curveDepth: CGFloat = 80) {
        self.curveDepth = curveDepth
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let topOffset = curveDepth
        let bottomOffset = curveDepth * 0.85
        let controlX = -(topOffset + bottomOffset) * 0.48

        path.move(to: CGPoint(x: topOffset, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: bottomOffset, y: rect.height),
            control: CGPoint(x: controlX, y: rect.height / 2)
        )
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.closeSubpath()
        return path
    }
}

public struct IntroView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localizationHelper = LocalizationHelper.shared
    @AppStorage(WS_SessionKeys.isPro) private var isPro: Bool = false
    
    @State private var currentPage: Int = 0
    public var onFinish: () -> Void
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private let introItems: [IntroItem] = [
        IntroItem(
            id: 0,
            imageName: "intro_1",
            iconName: "intro_1_Chat",
            titleKey: "Start Chats Without Saving Contacts",
            subtitleKey: "Message anyone without adding new contacts.",
            buttonTextKey: "Continue"
        ),
        IntroItem(
            id: 1,
            imageName: "intro_2",
            iconName: "intro_2_Save",
            titleKey: "Save Your Favorite Status Easily",
            subtitleKey: "Download and save statuses in seconds.",
            buttonTextKey: "Continue"
        ),
        IntroItem(
            id: 2,
            imageName: "intro_3",
            iconName: "intro_3_upload",
            titleKey: "Backup Your Chats With Ease",
            subtitleKey: "Keep Important Messages Safe Forever.",
            buttonTextKey: "Get Started"
        )
    ]
    
    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }
    
    public var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            
            ZStack {
                // Full Screen Background Image (Landscape and Portrait both)
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()
                
                if isLandscape {
                    // MARK: - Landscape Layout (Side-by-Side)
                    VStack {
                        landscapeLayout(geo: geo)
                        
                       
                    }
                    
                    
                } else {
                    // MARK: - Portrait Layout (Vertical Stack)
                    portraitLayout(geo: geo)
                    
                }
            }
        }
        .ignoresSafeArea(.all, edges: .all)
        .id(localizationHelper.refreshID)
    }
    
    // MARK: - Portrait Layout
    private func portraitLayout(geo: GeometryProxy) -> some View {
        let bottomCardHeight: CGFloat = isIPad
            ? min(geo.size.height * 0.44, 320) + geo.safeAreaInsets.bottom
            : min(geo.size.height * 0.56, 430) + geo.safeAreaInsets.bottom
        
        return ZStack(alignment: .bottom) {
            // Top Swiper Illustrations
            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(introItems) { item in
                        VStack {
                            Spacer()
                            Image(item.imageName)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: isIPad ? 760 : min(geo.size.width * 0.86, 380))
                                .frame(maxHeight: isIPad ? min(geo.size.height * 0.56, 500) : max(geo.size.height - bottomCardHeight - 20, 150))
                                .padding(.bottom, isIPad ? 280 : 20)
                            Spacer()
                        }
                        .tag(item.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: max(geo.size.height - bottomCardHeight + 25, 200))
                .padding(.top, max(geo.safeAreaInsets.top, 20) + 8)
                
                Spacer()
                
                if !isPro {
                    TR_NativeAd5()
                        .padding(.horizontal, isIPad ? 32 : 16)
                        .padding(.bottom, 12)
                }
            }
            
            // Bottom Curved Green Gradient Card
            let extraAdHeight: CGFloat = isPro ? 0 : (isIPad ? 115 : 90)
            if isIPad {
                bottomPortraitCard(height: bottomCardHeight + extraAdHeight, safeAreaBottom: geo.safeAreaInsets.bottom, containerWidth: geo.size.width)
            } else {
                bottomPortraitCard(height: 220 + extraAdHeight, safeAreaBottom: geo.safeAreaInsets.bottom, containerWidth: geo.size.width)
            }
            
        }
    }
    
    // MARK: - Landscape Layout (iPad / iPhone Landscape)
    private func landscapeLayout(geo: GeometryProxy) -> some View {
        let leftWidth = geo.size.width * 0.48
        let rightWidth = geo.size.width - leftWidth
        let currentItem = introItems[currentPage]
        let curveDepth: CGFloat = isIPad ? 110 : 70
        
        return VStack {
            HStack(spacing: 0) {
               // Left: Illustration Swiper
               TabView(selection: $currentPage) {
                   ForEach(introItems) { item in
                       VStack {
                           Spacer()
                           Image(item.imageName)
                               .resizable()
                               .aspectRatio(contentMode: .fit)
                               .frame(maxWidth: leftWidth * 0.99)
                               .frame(maxHeight: isIPad ? geo.size.height * 0.78 : geo.size.height * 0.82)
                           Spacer()
                       }
                       .tag(item.id)
                   }
               }
               .tabViewStyle(.page(indexDisplayMode: .never))
               .frame(width: leftWidth, height: geo.size.height)
               .padding(.leading, max(geo.safeAreaInsets.leading, 12))
               
               // Right: Green Curved Sheet matching reference design
               ZStack(alignment: .center) {
                   IntroLandscapeCurveShape(curveDepth: curveDepth)
                       .fill(
                           LinearGradient(
                               colors: [Color(hex: "#17AE60"), Color(hex: "#007C36")],
                               startPoint: .topLeading,
                               endPoint: .bottomTrailing
                           )
                       )
                       .shadow(color: Color.black.opacity(0.12), radius: 14, x: -4, y: 0)
                   
                   VStack(spacing: isIPad ? 22 : 14) {
                       Spacer()
                       
                       // Liquid Glass Icon Badge
                       liquidGlassBadge(iconName: currentItem.iconName)
                       
                       // Title (Localized)
                       Text(currentItem.titleKey.localized)
                           .font(.inter(.bold, size: isIPad ? 28 : 22))
                           .foregroundColor(.white)
                           .multilineTextAlignment(.center)
                           .lineLimit(2)
                           .padding(.horizontal, isIPad ? 32 : 20)
                           .animation(.easeInOut(duration: 0.25), value: currentPage)
                       
                       // Subtitle (Localized)
                       Text(currentItem.subtitleKey.localized)
                           .font(.inter(.regular, size: isIPad ? 25 : 14))
                           .foregroundColor(.white.opacity(0.85))
                           .multilineTextAlignment(.center)
                           .lineLimit(2)
                           .padding(.horizontal, isIPad ? 36 : 24)
                           .animation(.easeInOut(duration: 0.25), value: currentPage)
                       
                       // Indicators
                       pageIndicators
                           .padding(.vertical, isIPad ? 6 : 2)
                       
                       // Continue Button
                       actionButton(title: currentItem.buttonTextKey.localized)
                           .padding(.horizontal, isIPad ? 40 : 20)
                       
                       Spacer()

                   }
                   .frame(maxWidth: isIPad ? 660 : 360)
                   .padding(.leading, curveDepth * 0.35)
                   .padding(.trailing, max(geo.safeAreaInsets.trailing, 16))
               }
               .frame(width: rightWidth, height: geo.size.height - 20)
           }
            
            if !isPro {
                TR_NativeAd5()
                    .padding(.horizontal, isIPad ? 32 : 16)
                    .padding(.bottom, 160)
            }
        }
        
        .frame(width: geo.size.width, height: geo.size.height - 120)
    }
    
    // MARK: - Bottom Portrait Card
    private func bottomPortraitCard(height: CGFloat, safeAreaBottom: CGFloat, containerWidth: CGFloat) -> some View {
        let currentItem = introItems[currentPage]
        
        return ZStack(alignment: .top) {
            // Curved Background
            IntroCurveShape()
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#17AE60"), Color(hex: "#007C36")],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: -4)
            
            // Content
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: isIPad ? 28 : 22)
                
                // Liquid Glass Icon Badge
                liquidGlassBadge(iconName: currentItem.iconName)
                    .padding(.bottom, isIPad ? 18 : 14)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75), value: currentPage)
                
                // Title (Localized)
                Text(currentItem.titleKey.localized)
                    .font(.inter(.bold, size: isIPad ? 28 : 22))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .lineLimit(2)
                    .padding(.horizontal, isIPad ? 32 : 24)
                    .padding(.bottom, isIPad ? 12 : 8)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
                
                // Subtitle (Localized)
                Text(currentItem.subtitleKey.localized)
                    .font(.inter(.regular, size: isIPad ? 17 : 14))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, isIPad ? 40 : 32)
                    .padding(.bottom, isIPad ? 22 : 16)
                    .animation(.easeInOut(duration: 0.25), value: currentPage)
                
                // Vertical Pill Page Indicators
                pageIndicators
                    .padding(.bottom, isIPad ? 24 : 20)
                
                // Action Button (Above Home Indicator)
                actionButton(title: currentItem.buttonTextKey.localized)
                    .padding(.horizontal, isIPad ? 32 : 24)
                    .padding(.bottom, isPro ? (max(safeAreaBottom, 18) + 12) : 10)
            }
            
//            .frame(maxWidth: isIPad ? 580 : min(containerWidth, 540))
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .padding(.bottom,  isIPad ? 140 : 100)
        }
    }
    
    // MARK: - Reusable Liquid Glass Icon Badge
    private func liquidGlassBadge(iconName: String) -> some View {
        let badgeSize: CGFloat = isIPad ? 110 : 56
        let iconSize: CGFloat = isIPad ? 60 : 28
        let cornerRadius: CGFloat = isIPad ? 22 : 18
        
        return ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.clear)
                .background(
                    .clear,
                    in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.white.opacity(0.85), location: 0.0),
                                    .init(color: Color.white.opacity(0.20), location: 1.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 3)
            
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: iconSize, height: iconSize)
        }
        .frame(width: badgeSize, height: badgeSize)
    }
    
    // MARK: - Reusable Page Indicators
    private var pageIndicators: some View {
        HStack(spacing: isIPad ? 8 : 6) {
            ForEach(0..<introItems.count, id: \.self) { index in
                Capsule()
                    .fill(currentPage == index ? Color.white : Color.white.opacity(0.35))
                    .frame(width: isIPad ? 6 : 4, height: currentPage == index ? (isIPad ? 26 : 20) : (isIPad ? 16 : 12))
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentPage)
            }
        }
    }
    
    // MARK: - Reusable Action Button
    private func actionButton(title: String) -> some View {
        Button(action: {
            HapticFeedback.generate(.medium)
            if currentPage < introItems.count - 1 {
                withAnimation(.easeInOut(duration: 0.35)) {
                    currentPage += 1
                }
            } else {
                onFinish()
            }
        }) {
            Text(title)
                .font(.inter(.bold, size: isIPad ? 19 : 16))
                .foregroundColor(Color(hex: "#007C36"))
                .frame(maxWidth: isIPad ? .infinity : .infinity)
                .frame(height: isIPad ? 74 : 54)
                .background(Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

#Preview {
    IntroView(onFinish: {})
}
