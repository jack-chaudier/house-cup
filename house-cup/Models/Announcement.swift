//
//  Announcement.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation

struct Announcement: Identifiable, Codable {
    let id: String
    let authorId: String
    let authorName: String
    let authorType: UserType
    let title: String
    let message: String
    let targetAudience: TargetAudience
    let targetGrades: [Int]?  // nil means all grades
    let targetHouseIds: [String]?  // nil means all houses
    let priority: AnnouncementPriority
    let createdAt: Date
    let expiresAt: Date?
    var isActive: Bool
    
    init(
        id: String = UUID().uuidString,
        authorId: String,
        authorName: String,
        authorType: UserType,
        title: String,
        message: String,
        targetAudience: TargetAudience,
        targetGrades: [Int]? = nil,
        targetHouseIds: [String]? = nil,
        priority: AnnouncementPriority = .normal,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        isActive: Bool = true
    ) {
        self.id = id
        self.authorId = authorId
        self.authorName = authorName
        self.authorType = authorType
        self.title = title
        self.message = message
        self.targetAudience = targetAudience
        self.targetGrades = targetGrades
        self.targetHouseIds = targetHouseIds
        self.priority = priority
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isActive = isActive
    }
    
    var isExpired: Bool {
        if let expiresAt = expiresAt {
            return Date() > expiresAt
        }
        return false
    }
    
    var isVisible: Bool {
        isActive && !isExpired
    }
}

enum TargetAudience: String, CaseIterable, Codable {
    case all = "All Users"
    case students = "Students Only"
    case teachers = "Teachers Only"
    case specificGrades = "Specific Grades"
    case specificHouses = "Specific Houses"
}

enum AnnouncementPriority: String, CaseIterable, Codable {
    case low = "Low"
    case normal = "Normal"
    case high = "High"
    case urgent = "Urgent"
    
    var color: String {
        switch self {
        case .low: return "gray"
        case .normal: return "blue"
        case .high: return "orange"
        case .urgent: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .low: return "info.circle"
        case .normal: return "info.circle.fill"
        case .high: return "exclamationmark.triangle"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}