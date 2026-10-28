//
//  ContactDetailsView.swift
//  WebScanner
//

import SwiftUI

public struct ContactDetailsView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    public let contact: ContactCardInfo
    @State private var phoneNumber: String = ""
    @State private var showShareSheet: Bool = false
    @State private var shareItems: [Any] = []
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(contact: ContactCardInfo) {
        self.contact = contact
        _phoneNumber = State(initialValue: contact.number)
    }
    
    public var body: some View {
        ZStack {
            (colorScheme == .dark ? Color(hex: "#111B21") : Color(hex: "#F7F8FA"))
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        HapticFeedback.generate(.light)
                        dismiss()
                    }) {
                        ZStack {
                            Circle()
                                .fill(colorScheme == .dark ? Color(hex: "#202C33") : Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
                                .frame(width: isIPad ? 46 : 38, height: isIPad ? 46 : 38)
                            
                            Image(systemName: "chevron.left")
                                .font(.system(size: isIPad ? 18 : 15, weight: .bold))
                                .foregroundColor(colorScheme == .dark ? .white : Color(hex: "#111B21"))
                                .glassCard(cornerRadius: 12)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                .padding(.horizontal, isIPad ? 32 : 18)
                .padding(.top, isIPad ? 16 : 10)
                .padding(.bottom, 6)
                .frame(maxWidth: .infinity)
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: isIPad ? 22 : 16) {
                        ZStack {
                            Circle()
                                .fill(colorScheme == .dark ? Color(hex: "#3D3866") : Color(hex: "#D0C9FF"))
                                .frame(width: isIPad ? 140 : 108, height: isIPad ? 140 : 108)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: isIPad ? 60 : 46))
                                .foregroundColor(colorScheme == .dark ? Color(hex: "#B4ABF5") : Color(hex: "#4E4299"))
                        }
                        .padding(.top, isIPad ? 24 : 14)
                        
                        Text(contact.name.isEmpty ? "Contact".localized : contact.name)
                            .font(.system(size: isIPad ? 28 : 22, weight: .bold))
                            .foregroundColor(colorScheme == .dark ? .white : Color(hex: "#111B21"))
                            .multilineTextAlignment(.center)
                        
                        HStack(alignment: .center, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Mobile".localized)
                                    .font(.system(size: isIPad ? 14 : 12, weight: .regular))
                                    .foregroundColor(Color(hex: "#8696A0"))
                                
                                Text(displayNumber)
                                    .font(.system(size: isIPad ? 17 : 15, weight: .medium))
                                    .foregroundColor(phoneNumber.isEmpty ? Color(hex: "#8696A0") : Color(hex: "#00A884"))
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                        }
                        .padding(.horizontal, isIPad ? 20 : 16)
                        .padding(.vertical, isIPad ? 16 : 14)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(colorScheme == .dark ? Color(hex: "#1F2C34") : Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        .padding(.top, 6)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, isIPad ? 32 : 18)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showShareSheet) {
            ActivityView(activityItems: shareItems)
        }
    }
    
    private var displayNumber: String {
        if !phoneNumber.isEmpty {
            return phoneNumber
        }
        return "No phone number available".localized
    }

}
