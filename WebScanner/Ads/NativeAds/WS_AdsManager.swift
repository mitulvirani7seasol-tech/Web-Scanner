//
//  WS_AdsManager.swift
//  WebScanner
//
//

import Foundation
import UIKit
import GoogleMobileAds
import AppTrackingTransparency
import AdSupport
import SystemConfiguration
import UserMessagingPlatform

protocol WS_AdsManagerDelegate {
    func NativeAdLoad()
    func DidDismissFullScreenContent()
    func NativeAdsDidFailedToLoad()
}

typealias TR_AdsManagerDelegate = WS_AdsManagerDelegate
typealias SM_AdsManagerDelegate = WS_AdsManagerDelegate

typealias TR_AdsManager = WS_AdsManager
typealias SM_AdsManager = WS_AdsManager

var interstitialAd: InterstitialAd?
var interstitialAd2: InterstitialAd?
var isNativeLoad : Bool = false

var NATIVE_ADS:NativeAd?
var isAdsLoadFailed = Bool()


class WS_AdsManager: NSObject {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
    
    static let shared = TR_AdsManager()
    var delegate: TR_AdsManagerDelegate?

    var adLoader: AdLoader!
    var arrNativeAds = [NativeAd]()

    var appOpenAd :AppOpenAd?
    var loadTime = Date()

    var isMobileAdsStartCalled = Bool()
    var interAdVisible = false
    
    //MARK:- TOP VIEW CONTROLLER
    var topMostViewController: UIViewController? {
        var currentVc = UIApplication.shared.keyWindow?.rootViewController
        while let presentedVc = currentVc?.presentedViewController {
            if let navVc = (presentedVc as? UINavigationController)?.viewControllers.last {
                currentVc = navVc
            } else if let tabVc = (presentedVc as? UITabBarController)?.selectedViewController {
                currentVc = tabVc
            } else {
                currentVc = presentedVc
            }
        }
        return currentVc
    }

    //MARK: - Request For Content Form
    func requestForConsentForms(){
        let parameters = RequestParameters()
        let debugSettings = DebugSettings()
        debugSettings.geography = DebugGeography.EEA
        parameters.debugSettings = debugSettings
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) {
            [weak self] requestConsentError in
            guard let self else { return }
            
            if let consentError = requestConsentError {
                return print("Error: \(consentError.localizedDescription)")
            }
            let rootController = UIApplication.shared.keyWindow?.rootViewController

            ConsentForm.loadAndPresentIfRequired(from: rootController ?? UIViewController()) {
                [weak self] loadAndPresentError in
                guard let self else { return }
                
                if let consentError = loadAndPresentError {
                    // Consent gathering failed.
                    return print("Error: \(consentError.localizedDescription)")
                }
                
                if ConsentInformation.shared.canRequestAds {
                    self.startGoogleMobileAdsSDK()
                }
            }
        }
        
        if ConsentInformation.shared.canRequestAds {
            startGoogleMobileAdsSDK()
        }
    }
    
    func requestForConsentForm(completion: @escaping (Bool) -> Void) {
        let parameters = RequestParameters()
        let debugSettings = DebugSettings()
        debugSettings.geography = DebugGeography.EEA
           parameters.debugSettings = debugSettings
        ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { [weak self] requestConsentError in
               guard let self = self else { return }

               if let consentError = requestConsentError {
                   print("Error: \(consentError.localizedDescription)")
                   completion(false)
                   return
               }

                   let rootController = UIApplication.shared.keyWindow?.rootViewController
                   ConsentForm.loadAndPresentIfRequired(from: rootController) { [weak self] loadAndPresentError in
                       guard let self = self else { return }

                       if let consentError = loadAndPresentError {
                           print("Error: \(consentError.localizedDescription)")
                           completion(false)
                           return
                       }

                       if ConsentInformation.shared.consentStatus == ConsentStatus.obtained {
                           completion(true)
                       } else {
                           completion(false)
                       }
                   }
           }

        if ConsentInformation.shared.canRequestAds {
               startGoogleMobileAdsSDK()
           }
       }
    
    private func startGoogleMobileAdsSDK() {
        DispatchQueue.main.async {
            guard !self.isMobileAdsStartCalled else { return }
            
            self.isMobileAdsStartCalled = true
            
            MobileAds.shared.start()
        }
    }


    //MARK: - PRESENT (INTERSITITAL, NATIVE) ADS
    func showInterstitialAd (_ isLoader:Bool = false, isRandom:Bool = false, ratio:Int = 3,shouldMatchRandom : Int = 2){
        if interstitialAd != nil {
            self.checkRandomAndPresentInterstitial(isRandom: isRandom, ratio: ratio, shouldMatchRandom: shouldMatchRandom)
        } else {
        }
    }

    func checkRandomAndPresentInterstitial( isRandom:Bool, ratio:Int,shouldMatchRandom :Int){
        if isRandom{
            let isRandomMatch = Int.random(in: 1 ... ratio) == shouldMatchRandom
            if isRandomMatch {
                self.presentInterstitialAd()
            }
        }
        else {
            self.presentInterstitialAd()
        }
    }

    func presentInterstitialAd() {
        DispatchQueue.main.async {
            if let rootController = getTopViewController(){
                interstitialAd?.present(from: rootController)
            }
        }
    }
    var adCompletionHandler: (() -> Void)?
}


// MARK: - Interstitial Delegate
extension TR_AdsManager: FullScreenContentDelegate {

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
    }

    func adWillDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        self.delegate?.DidDismissFullScreenContent()
    }
}

// MARK: - NativeAd Loader Delegate
extension TR_AdsManager: NativeAdLoaderDelegate {

    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        isNativeLoad = true
        arrNativeAds.append(nativeAd)
        self.delegate?.NativeAdLoad()
    }

    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        isNativeLoad = false
    }

    func adLoaderDidFinishLoading(_ adLoader: AdLoader) {

    }
}


// MARK: - Display view into subview
func displaySubViewtoParentView(_ parentview: UIView! , subview: UIView!) {
    subview.translatesAutoresizingMaskIntoConstraints = false
    parentview.addSubview(subview);
    parentview.addConstraint(NSLayoutConstraint(item: subview!, attribute: NSLayoutConstraint.Attribute.top, relatedBy: NSLayoutConstraint.Relation.equal, toItem: parentview, attribute: NSLayoutConstraint.Attribute.top, multiplier: 1.0, constant: 0.0))
    parentview.addConstraint(NSLayoutConstraint(item: subview!, attribute: NSLayoutConstraint.Attribute.leading, relatedBy: NSLayoutConstraint.Relation.equal, toItem: parentview, attribute: NSLayoutConstraint.Attribute.leading, multiplier: 1.0, constant: 0.0))
    parentview.addConstraint(NSLayoutConstraint(item: subview!, attribute: NSLayoutConstraint.Attribute.bottom, relatedBy: NSLayoutConstraint.Relation.equal, toItem: parentview, attribute: NSLayoutConstraint.Attribute.bottom, multiplier: 1.0, constant: 0.0))
    parentview.addConstraint(NSLayoutConstraint(item: subview!, attribute: NSLayoutConstraint.Attribute.trailing, relatedBy: NSLayoutConstraint.Relation.equal, toItem: parentview, attribute: NSLayoutConstraint.Attribute.trailing, multiplier: 1.0, constant: 0.0))
    parentview.layoutIfNeeded()
}

func getTopViewController() -> UIViewController? {
    return UIApplication.topViewController
}
