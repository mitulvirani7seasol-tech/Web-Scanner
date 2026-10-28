//
//  NetworkMonitor.swift
//  WebScanner
//
//

import Foundation
import Network
import SystemConfiguration
import Combine

@MainActor
public final class NetworkMonitor: ObservableObject {
    public static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.WebScanner.NetworkMonitor", qos: .background)
    
    @Published public private(set) var isConnected: Bool = true
    
    private init() {
        self.isConnected = Self.checkReachability()
        
        monitor.pathUpdateHandler = { path in
            let isSatisfied = (path.status == .satisfied)
            Task { @MainActor in
                NetworkMonitor.shared.isConnected = isSatisfied && NetworkMonitor.checkReachability()
            }
        }
        monitor.start(queue: queue)
    }
    
    public var isNetworkAvailable: Bool {
        if !Self.checkReachability() {
            return false
        }
        if monitor.currentPath.status != .satisfied {
            return false
        }
        return isConnected
    }
    
    public static func checkReachability() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        guard let reachability = defaultRouteReachability else { return false }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(reachability, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
}
