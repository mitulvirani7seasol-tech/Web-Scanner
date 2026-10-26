//
//  CountryCodeManager.swift
//  WebScanner
//

import Foundation
import Combine

public struct CountryCodeItem: Codable, Identifiable, Equatable {
    public var id: String { code }
    public let name: String
    public let code: String
    public let emoji: String
    public let dial_code: String
}

@MainActor
public final class CountryCodeManager: ObservableObject {
    public static let shared = CountryCodeManager()
    
    @Published public private(set) var countries: [CountryCodeItem] = []
    
    private init() {
        loadCountries()
    }
    
    public func loadCountries() {
        guard let url = Bundle.main.url(forResource: "Country_Codes", withExtension: "json") ??
                Bundle.main.url(forResource: "Country_Codes", withExtension: "json", subdirectory: nil) else {
            // Fallback default list
            self.countries = [
                CountryCodeItem(name: "India", code: "IN", emoji: "🇮🇳", dial_code: "+91"),
                CountryCodeItem(name: "United States", code: "US", emoji: "🇺🇸", dial_code: "+1"),
                CountryCodeItem(name: "United Kingdom", code: "GB", emoji: "🇬🇧", dial_code: "+44")
            ]
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            self.countries = try JSONDecoder().decode([CountryCodeItem].self, from: data)
        } catch {
            print("Failed to decode Country_Codes.json:", error)
        }
    }
}
