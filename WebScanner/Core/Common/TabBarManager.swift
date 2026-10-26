//
//  TabBarManager.swift
//  WebScanner
//
//

import SwiftUI
import Combine

public class TabBarManager: ObservableObject {
    public static let shared = TabBarManager()
    
    @Published public var isHidden: Bool = false
    @Published public var selectedTab: Int = 0
    @Published public var shouldNavigateToBackupChats: Bool = false
    @Published public var shouldShowImportSheet: Bool = false
    @Published public var chatToOpenImmediately: ChatConversation?
    @Published public var showPaywall: Bool = false
    @Published public var isPaywallFromAppOpen: Bool = false
    
    public func reset() {
        isHidden = false
    }
    
    public func navigateToBackupChats() {
        selectedTab = 0
        shouldNavigateToBackupChats = true
    }
    
    public func navigateDirectlyToChat(_ conversation: ChatConversation) {
        selectedTab = 0
        shouldNavigateToBackupChats = false
        chatToOpenImmediately = conversation
    }
    
    private init() {}
}
