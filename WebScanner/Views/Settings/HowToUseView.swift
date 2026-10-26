//
//  HowToUseView.swift
//  WebScanner
//

import SwiftUI

public struct HowToUseView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedGuide: Int = 0 // 0: WT Scan, 1: Direct Chat, 2: Chat Backup, 3: Status Saver
    
    private let guides = ["WT Scan", "Direct Chat", "Chat Backup", "Status Saver"]
    
    public init() {}
    
    public var body: some View {
        ZStack {
            AppColors.background(for: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 16.scaled) {
                // Header
                headerView
                
                // Segmented Selector
                segmentedBar
                
                // Guide Content
                ScrollView(.vertical, showsIndicators: false) {
                    guideContent(for: selectedGuide)
                        .padding(.bottom, 24.scaled)
                }
            }
            .padding(.horizontal, 18.scaled)
            .padding(.top, 12.scaled)
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private var headerView: some View {
        HStack(spacing: 12.scaled) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18.scaled, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .padding(8.scaled)
                    .background(AppColors.card(for: colorScheme))
                    .clipShape(Circle())
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text("How to Use")
                .font(.inter(.bold, size: 22))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
    }
    
    private var segmentedBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8.scaled) {
                ForEach(0..<guides.count, id: \.self) { idx in
                    Button(action: {
                        HapticFeedback.generate(.selection)
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedGuide = idx
                        }
                    }) {
                        Text(guides[idx])
                            .font(.inter(.semiBold, size: 13))
                            .foregroundColor(selectedGuide == idx ? .white : AppColors.textSecondary(for: colorScheme))
                            .padding(.horizontal, 16.scaled)
                            .padding(.vertical, 8.scaled)
                            .background(
                                RoundedRectangle(cornerRadius: 10.scaled)
                                    .fill(selectedGuide == idx ? AppColors.primaryGreen : AppColors.card(for: colorScheme))
                            )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
    
    @ViewBuilder
    private func guideContent(for index: Int) -> some View {
        switch index {
        case 0:
            wtScanGuide
        case 1:
            directChatGuide
        case 2:
            chatBackupGuide
        case 3:
            statusSaverGuide
        default:
            EmptyView()
        }
    }
    
    // WT Scan
    private var wtScanGuide: some View {
        VStack(spacing: 16.scaled) {
            guideStepCard(
                step: 1,
                title: "Open WT Scan",
                description: "Tap 'WT Scan Now' on the Home tab. The WhatsApp Web desktop QR code scanner will load.",
                icon: "qrcode.viewfinder"
            )
            
            guideStepCard(
                step: 2,
                title: "Open WhatsApp on Target Phone",
                description: "On the phone you wish to clone, open WhatsApp > Settings > Linked Devices.",
                icon: "gearshape.fill"
            )
            
            guideStepCard(
                step: 3,
                title: "Link a Device & Scan",
                description: "Tap 'Link a Device' and point your camera at the QR code displayed on WebScanner.",
                icon: "camera.viewfinder"
            )
            
            guideStepCard(
                step: 4,
                title: "Dual Account Ready!",
                description: "Your chats will synchronize seamlessly. You can now use multiple WhatsApp accounts simultaneously on one device.",
                icon: "checkmark.seal.fill"
            )
        }
    }
    
    // Direct Chat
    private var directChatGuide: some View {
        VStack(spacing: 16.scaled) {
            guideStepCard(
                step: 1,
                title: "Select Country Code",
                description: "Tap the country flag selector and pick the recipient's country code (e.g. +1, +91, +44).",
                icon: "flag.fill"
            )
            
            guideStepCard(
                step: 2,
                title: "Enter Phone Number",
                description: "Type the recipient's phone number without any special characters or country prefix.",
                icon: "phone.fill"
            )
            
            guideStepCard(
                step: 3,
                title: "Add Message (Optional)",
                description: "Type your message or choose a pre-saved Quick Reply template.",
                icon: "message.fill"
            )
            
            guideStepCard(
                step: 4,
                title: "Start Chat Without Saving",
                description: "Tap 'Open WhatsApp' or 'Open WA Business'. The conversation opens instantly without saving to contacts!",
                icon: "arrow.up.right.square.fill"
            )
        }
    }
    
    // Chat Backup
    private var chatBackupGuide: some View {
        VStack(spacing: 16.scaled) {
            guideStepCard(
                step: 1,
                title: "Export Chat from WhatsApp",
                description: "Open the WhatsApp chat you want to backup. Tap Contact Info > Export Chat > Choose 'Attach Media'.",
                icon: "square.and.arrow.up.fill"
            )
            
            guideStepCard(
                step: 2,
                title: "Save ZIP to Files",
                description: "Select 'Save to Files' from the iOS share sheet and save the exported .zip file.",
                icon: "folder.fill"
            )
            
            guideStepCard(
                step: 3,
                title: "Import into WebScanner",
                description: "Open WebScanner > Chat Backup tab > Tap '+ Import Chat' and select the saved ZIP.",
                icon: "arrow.down.doc.fill"
            )
            
            guideStepCard(
                step: 4,
                title: "Read & Search Offline",
                description: "Read messages in native chat bubbles, view media, listen to audio voice notes, and search messages anytime.",
                icon: "bubble.left.and.bubble.right.fill"
            )
        }
    }
    
    // Status Saver
    private var statusSaverGuide: some View {
        VStack(spacing: 16.scaled) {
            guideStepCard(
                step: 1,
                title: "View Status on WhatsApp",
                description: "Open WhatsApp, go to the Status tab, and view the photo or video status you want to save.",
                icon: "eye.fill"
            )
            
            guideStepCard(
                step: 2,
                title: "Capture to Device",
                description: "Capture a screenshot or short screen recording on your iPhone or iPad.",
                icon: "camera.fill"
            )
            
            guideStepCard(
                step: 3,
                title: "Manage in WebScanner",
                description: "Open WebScanner Status Saver tab to view, share, and export your captured status media.",
                icon: "square.and.arrow.down.fill"
            )
        }
    }
    
    private func guideStepCard(step: Int, title: String, description: String, icon: String) -> some View {
        HStack(alignment: .top, spacing: 14.scaled) {
            ZStack {
                Circle()
                    .fill(AppColors.primaryGreen.opacity(0.12))
                    .scaledSquare(42)
                
                Image(systemName: icon)
                    .font(.system(size: 18.scaled))
                    .foregroundColor(AppColors.primaryGreen)
            }
            
            VStack(alignment: .leading, spacing: 4.scaled) {
                Text("Step \(step): \(title)")
                    .font(.inter(.bold, size: 15))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                
                Text(description)
                    .font(.inter(.regular, size: 13))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(14.scaled)
        .glassCard(cornerRadius: 16)
    }
}

#Preview {
    HowToUseView()
}
