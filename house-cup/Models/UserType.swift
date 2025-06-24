//
//  UserType.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation

enum UserType: String, CaseIterable, Codable {
    case admin = "admin"
    case teacher = "teacher"
    case student = "student"
    case none = "none"
    
    var displayName: String {
        switch self {
        case .admin: return "Administrator"
        case .teacher: return "Teacher"
        case .student: return "Student"
        case .none: return "Pending Approval"
        }
    }
}
