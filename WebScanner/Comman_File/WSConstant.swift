//
//  WSConstant.swift
//  WebScanner
//
//  Created by Kushang kaklotar on 19/10/26.
//

import Foundation
import UIKit
import SwiftUI

let AppId = 6505063874

let appname = "Dual App"
let REVIEW_LINK = "https://apps.apple.com/app/id\(AppId)?action=write-review"
let APPURL = "https://apps.apple.com/app/id\(AppId)"
let PRIVACYPOLICY = "https://vsapps7.blogspot.com/2024/07/privacymetqr.html"
let TEARMS = "https://vsapps7.blogspot.com/2024/10/termicrickmaster.html"
let EULA = "https://vsapps7.blogspot.com/2024/09/eulaftscore.html"

// In-App Purchase identifiers
var iapYearlyPlan = "false" 
var iapMonthlyPlan = "false"
var iapWeeklyPlan = "false"
var premiumCloseTime: Double = 2.0

public var isYearlyPlanEnabled: Bool {
    let val = iapYearlyPlan.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return val == "true" || val == "1"
}

public var isMonthlyPlanEnabled: Bool {
    let val = iapMonthlyPlan.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return val == "true" || val == "1"
}

public var isWeeklyPlanEnabled: Bool {
    let val = iapWeeklyPlan.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    return val == "true" || val == "1"
}

var isShowPremium = ""
var second_native = ""
var second_appopen = ""
var small_native = ""
var second_small_native = ""
var pro_close_inter = ""
var smallNativeAd = ""
var freeLimitCount = ""

var bannerId = "ca-app-pub-3940256099942544/2934735716"
var nativeId = "ca-app-pub-3940256099942544/3986624511"
var interstialId = "ca-app-pub-3940256099942544/4411468910"
var rewardId = ""
var appopenId = "ca-app-pub-3940256099942544/5575463023"
var addButtonColor = "#007AFF"
var adsCount = 4
var adsPlus = 1
var smallNativeBannerId = ""

let ApiURL : String = "https://d3ae04iuu0wjup.cloudfront.net/pbz-rnfljn-zrrglpung.json"

func isIpad() -> Bool {
    UIDevice.current.userInterfaceIdiom == .pad
}
