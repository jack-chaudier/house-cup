//
//  PointAward.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation
import FirebaseFirestore

struct PointAward: Identifiable, Codable {
    let id: String
    let studentId: String
    let teacherId: String
    let houseId: String
    let points: Int
    let reason: String
    let category: AwardCategory
    let timestamp: Date
    
    // Student and teacher names for display
    var studentName: String?
    var teacherName: String?
    var houseName: String?
    
    init(
        id: String = UUID().uuidString,
        studentId: String,
        teacherId: String,
        houseId: String,
        points: Int,
        reason: String,
        category: AwardCategory,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.studentId = studentId
        self.teacherId = teacherId
        self.houseId = houseId
        self.points = points
        self.reason = reason
        self.category = category
        self.timestamp = timestamp
    }
}

enum AwardCategory: String, CaseIterable, Codable {
    case academic = "Academic Excellence"
    case behavior = "Good Behavior"
    case leadership = "Leadership"
    case teamwork = "Teamwork"
    case creativity = "Creativity"
    case sports = "Sports"
    case community = "Community Service"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .academic: return "graduationcap.fill"
        case .behavior: return "star.fill"
        case .leadership: return "flag.fill"
        case .teamwork: return "person.3.fill"
        case .creativity: return "paintbrush.fill"
        case .sports: return "sportscourt.fill"
        case .community: return "heart.fill"
        case .other: return "sparkles"
        }
    }
}
