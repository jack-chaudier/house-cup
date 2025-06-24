//
//  AppSettings.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation

struct AppSettings: Codable {
    var pointsEnabled: Bool = true
    var maxPointsPerAward: Int = 50
    var minPointsPerAward: Int = 5
    var allowNegativePoints: Bool = false
    var currentTerm: String = "Spring 2025"
    var schoolName: String = "Hogwarts School"
}
