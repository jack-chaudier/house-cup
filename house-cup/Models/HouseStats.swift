//
//  HouseStats.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation

struct HouseStatistics: Identifiable {
    let id: String  // House ID
    let houseName: String
    let totalPoints: Int
    let weeklyPoints: Int
    let monthlyPoints: Int
    let rank: Int
    let topContributors: [StudentContribution]
    let recentAwards: [PointAward]
}

struct StudentContribution: Identifiable {
    let id: String  // Student ID
    let studentName: String
    let points: Int
    let photoURL: String?
}
