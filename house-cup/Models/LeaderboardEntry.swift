//
//  LeaderboardEntry.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation

struct LeaderboardEntry: Identifiable {
    let id: String
    let name: String
    let points: Int
    let rank: Int
    let colorHex: String
    let trend: Trend  // up, down, or stable
    
    enum Trend {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.circle.fill"
            case .down: return "arrow.down.circle.fill"
            case .stable: return "minus.circle.fill"
            }
        }
    }
}
