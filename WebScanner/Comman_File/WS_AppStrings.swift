//
//  WS_AppStrings.swift
//  WebScanner
//
//  Created by Kushang kaklotar on 19/10/26.
//

import Foundation
import SwiftUI

struct WS_AppStrings {
    
    static let groupID = "group.com.WebScanner.app"
    static let appExtensionPackageName = "com.WebScanner.app1.ExportWpChatt"
}

struct WS_SessionKeys {
    static var language = "language"
    static var intro1 = "intro1"
    static var intro2 = "intro2"
    static var intro3 = "intro3"
    static var intro4 = "intro4"
    static let appLanguage = "appLanguage"
    static var isPro = "isPro"
    static var interAdId = "interAdId"
    static var afterClick = "afterClick"
    static let isHapticEnabled = "isHapticEnabled"
    static var isPasswordOn = "isPasswordOn"
    static var isPasswordSet = "isPasswordSet"
    static let isHomeOpened = "isHomeOpened"
}

enum WS_Products: String, CaseIterable {
    case Motion_Week = "Week_Cast"
    case Motion_Month = "Month_Cast"
    case Motion_Year = "Year_Cast"
    case Motion_LifeTime = "Life_Time_Cast"
}

class WS_AppSession {
    static let shared = WS_AppSession()
    var isSplashCompleted = false
    var hasShownPremium = false
    var hasShownRate = false
    var hasPromptedUpdateAlert = false
}

typealias WSAPP_AppStrings = WS_AppStrings
typealias WSAPP_SessionKeys = WS_SessionKeys
typealias WSAPP_Products = WS_Products
typealias WSAPP_AppSession = WS_AppSession
typealias AppSession = WS_AppSession


