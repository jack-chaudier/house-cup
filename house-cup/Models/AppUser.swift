//
//  AppUser.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation

struct AppUser: Identifiable, Codable, Hashable {
    let id: String  // This will be the Firebase UID
    let email: String?
    let displayName: String?
    let userType: UserType
    let photoURL: String?
    let houseId: String?  // For students
    let createdAt: Date?
    let grade: Int?  // For students: 9, 10, 11, or 12
    var points: Int  // Total points earned (not reduced by spending)
    var spentPoints: Int  // Points spent in shop
    
    // Computed properties
    var isApproved: Bool {
        userType != .none
    }
    
    var availablePoints: Int {
        points - spentPoints
    }
    
    // For Firestore
    init(uid: String, email: String?, displayName: String?, userType: UserType, photoURL: String?, houseId: String? = nil, createdAt: Date? = nil, grade: Int? = nil, points: Int = 0, spentPoints: Int = 0) {
        self.id = uid
        self.email = email
        self.displayName = displayName
        self.userType = userType
        self.photoURL = photoURL
        self.houseId = houseId
        self.createdAt = createdAt
        self.grade = grade
        self.points = points
        self.spentPoints = spentPoints
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance (required by Hashable)
    static func == (lhs: AppUser, rhs: AppUser) -> Bool {
        lhs.id == rhs.id
    }
}
