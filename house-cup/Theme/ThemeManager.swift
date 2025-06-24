//
//  ThemeManager.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI

class ThemeManager: ObservableObject {
    @AppStorage("isDarkMode") var isDarkMode: Bool = false
    @AppStorage("useSystemTheme") var useSystemTheme: Bool = true
    @AppStorage("accentColorHex") var accentColorHex: String = "#007AFF"
    @Published var currentHouseColor: Color?
    
    var effectiveColorScheme: ColorScheme? {
        useSystemTheme ? nil : (isDarkMode ? .dark : .light)
    }
    
    var accentColor: Color {
        // If user has a house, use house color in light mode
        if let houseColor = currentHouseColor, !isDarkMode {
            return houseColor
        }
        
        // Otherwise use saved accent color
        return Color(hex: accentColorHex) ?? .accentColor
    }
    
    func setHouseColor(_ color: Color?) {
        currentHouseColor = color
    }
}

// Custom color definitions for dark mode support
extension Color {
    static let customPrimaryBackground = Color("PrimaryBackground")
    static let customSecondaryBackground = Color("SecondaryBackground")
    static let customPrimaryText = Color("PrimaryText")
    static let customSecondaryText = Color("SecondaryText")
    
    // House colors that work in both light and dark mode
    static let gryffindorRed = Color(hex: "#740001") ?? .red
    static let slytherinGreen = Color(hex: "#1A472A") ?? .green
    static let hufflepuffYellow = Color(hex: "#FFD800") ?? .yellow
    static let ravenclawBlue = Color(hex: "#0E1A40") ?? .blue
}

// Custom ViewModifiers for consistent theming
struct CardBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
            )
    }
}

struct PrimaryButton: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(color)
            .cornerRadius(12)
    }
}

struct SecondaryButton: ViewModifier {
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(color)
            .padding()
            .background(color.opacity(0.15))
            .cornerRadius(12)
    }
}

// View extensions for easy application
extension View {
    func cardBackground() -> some View {
        modifier(CardBackground())
    }
    
    func primaryButton(color: Color = .accentColor) -> some View {
        modifier(PrimaryButton(color: color))
    }
    
    func secondaryButton(color: Color = .accentColor) -> some View {
        modifier(SecondaryButton(color: color))
    }
}

// Gradient backgrounds for houses
extension LinearGradient {
    static func houseGradient(for color: Color) -> LinearGradient {
        LinearGradient(
            colors: [color.opacity(0.8), color.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var darkModeBackground: LinearGradient {
        LinearGradient(
            colors: [Color(.systemGray6), Color(.systemBackground)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}