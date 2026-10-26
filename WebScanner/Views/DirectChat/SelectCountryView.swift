//
//  SelectCountryView.swift
//  WebScanner
//

import SwiftUI

public struct SelectCountryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var countryManager = CountryCodeManager.shared
    
    @Binding var selectedCountry: CountryCodeItem
    
    @State private var searchQuery: String = ""
    @FocusState private var isSearchFocused: Bool
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    public init(selectedCountry: Binding<CountryCodeItem>) {
        self._selectedCountry = selectedCountry
    }
    
    private var filteredCountries: [CountryCodeItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return countryManager.countries
        }
        return countryManager.countries.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.dial_code.contains(query) ||
            $0.code.localizedCaseInsensitiveContains(query)
        }
    }
    
    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Fixed background image strictly bounded to geo
                Image(colorScheme == .dark ? "BG_Dark" : "BG")
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. Header Bar: < Select Country (Pinned safely below notch/status bar)
                    headerBar(topInset: geo.safeAreaInsets.top)
                    
                    // 2. Search Bar with Close button when focused / active
                    searchBarSection
                        .padding(.horizontal, isIPad ? 32 : 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                    
                    // 3. Country List (Full width for iPad as requested)
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredCountries) { country in
                                countryRow(country)
                            }
                        }
                        .padding(.horizontal, isIPad ? 32 : 16)
                        .padding(.bottom, max(geo.safeAreaInsets.bottom, 24) + 20)
                        .frame(maxWidth: .infinity)
                    }
                    .scrollDismissesKeyboard(.immediately)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
//            .frame(width: geo.size.width, height: geo.size.height)
//            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .navigationBarBackButtonHidden(true)
        .enableNativeSwipeBack()
        .onAppear {
            TabBarManager.shared.isHidden = true
        }
        .onDisappear {
            TabBarManager.shared.isHidden = false
        }
    }
    
    // MARK: - Header Bar (Safely padded below status bar)
    private func headerBar(topInset: CGFloat) -> some View {
        HStack(spacing: 6) {
            Button(action: {
                HapticFeedback.generate(.light)
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: isIPad ? 22 : 18, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Text("Select Country".localized)
                .font(.inter(.bold, size: isIPad ? 28 : 22))
                .foregroundColor(AppColors.textPrimary(for: colorScheme))
            
            Spacer()
        }
        .padding(.horizontal, isIPad ? 32 : 16)
        .padding(.top, isIPad ? 14 : 8)
        .padding(.bottom, 8)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Search Bar Section
    private var searchBarSection: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: isIPad ? 17 : 15, weight: .medium))
                    .foregroundColor(AppColors.textSecondary(for: colorScheme))
                
                TextField("Search Country or Dial Code".localized, text: $searchQuery)
                    .font(.inter(.medium, size: isIPad ? 16 : 14.scaled))
                    .foregroundColor(AppColors.textPrimary(for: colorScheme))
                    .focused($isSearchFocused)
                
                if !searchQuery.isEmpty {
                    Button(action: {
                        searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color(hex: "#8E8E93"))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, isIPad ? 16 : 14.scaled)
            .frame(height: isIPad ? 52 : 46.scaled)
            .background(
                RoundedRectangle(cornerRadius: 14.scaled, style: .continuous)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.09) : Color(hex: "#E5E9EE").opacity(0.65))
            )
            
            // Close Button shown when user clicks search bar or is searching
            if isSearchFocused || !searchQuery.isEmpty {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        searchQuery = ""
                        isSearchFocused = false
                        hideKeyboard()
                    }
                }) {
                    Text("Close".localized)
                        .font(.inter(.semiBold, size: isIPad ? 16 : 14.scaled))
                        .foregroundColor(AppColors.primaryGreen)
                        .padding(.horizontal, 4)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSearchFocused)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: searchQuery.isEmpty)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Country Row
    private func countryRow(_ country: CountryCodeItem) -> some View {
        Button(action: {
            HapticFeedback.generate(.light)
            selectedCountry = country
            TR_AdCountViewModel.sharedd.registerTap {
                dismiss()
            }
        }) {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Text(country.emoji)
                        .font(.system(size: isIPad ? 26 : 22))
                    
                    Text(country.name)
                        .font(.inter(.medium, size: isIPad ? 17 : 15.scaled))
                        .foregroundColor(AppColors.textPrimary(for: colorScheme))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(country.dial_code)
                        .font(.inter(.semiBold, size: isIPad ? 16 : 14.scaled))
                        .foregroundColor(AppColors.primaryGreen)
                }
                .padding(.vertical, isIPad ? 15 : 13.scaled)
                .contentShape(Rectangle())
                
                // Subtle divider
                Rectangle()
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06))
                    .frame(height: 0.8)
            }
        }
        .buttonStyle(ScaleButtonStyle(scaleAmount: 0.98))
        .frame(maxWidth: .infinity)
    }
}
