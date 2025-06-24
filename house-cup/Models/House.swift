//
//  House.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation
import SwiftUI

struct House: Identifiable, Codable {
    let id: String
    let name: String
    let colorHex: String
    var totalPoints: Int
    let mascot: String?
    let motto: String?
    let grade: Int  // 9, 10, 11, or 12
    
    var color: Color {
        Color(hex: colorHex) ?? .gray
    }
    
    var displayName: String {
        "\(name) - Grade \(grade)"
    }
    
    init(id: String = UUID().uuidString, name: String, colorHex: String, totalPoints: Int = 0, mascot: String? = nil, motto: String? = nil, grade: Int) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.totalPoints = totalPoints
        self.mascot = mascot
        self.motto = motto
        self.grade = grade
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }
        
        self.init(
            red: Double((rgb & 0xFF0000) >> 16) / 255.0,
            green: Double((rgb & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgb & 0x0000FF) / 255.0
        )
    }
}
