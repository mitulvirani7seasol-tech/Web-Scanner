//
//  NetworkMonitor.swift
//  WebScanner
//
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
    private let queue = DispatchQueue(label: "com.WebScanner.NetworkMonitor", qos: .userInitiated)
    
    @Published public private(set) var isConnected: Bool = true
    
    private init() {
        self.isConnected = Self.checkReachability()
        
        monitor.pathUpdateHandler = { path in
            let isSatisfied = (path.status == .satisfied)
            let reachable = NetworkMonitor.checkReachability()
            let available = isSatisfied || reachable
            Task { @MainActor in
                NetworkMonitor.shared.isConnected = available
            }
        }
        monitor.start(queue: queue)
    }
    
    public var isNetworkAvailable: Bool {
        // 1. If NWPathMonitor reports satisfied, network is definitely available
        if monitor.currentPath.status == .satisfied {
            return true
        }
        // 2. If our published state is true
        if isConnected {
            return true
        }
        // 3. Check reachability flags with full Cellular & VPN on-demand support
        return Self.checkReachability()
    }
    
    nonisolated public static func checkReachability() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        guard let reachability = defaultRouteReachability else { return true }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(reachability, &flags) {
            return true
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
        let canConnectWithoutUserIntervention = canConnectAutomatically && !flags.contains(.interventionRequired)
        
        return isReachable && (!needsConnection || canConnectWithoutUserIntervention)
    }
}
