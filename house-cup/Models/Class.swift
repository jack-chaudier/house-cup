//
//  Class.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation

struct Class: Identifiable, Codable {
    let id: String
    let name: String
    let teacherId: String
    let subject: String
    let grade: String?
    let studentIds: [String]
    let schedule: String?  // e.g., "MWF 9:00-10:00"
    
    var teacherName: String?  // Populated when fetching
    
    init(
        id: String = UUID().uuidString,
        name: String,
        teacherId: String,
        subject: String,
        grade: String? = nil,
        studentIds: [String] = [],
        schedule: String? = nil
    ) {
        self.id = id
        self.name = name
        self.teacherId = teacherId
        self.subject = subject
        self.grade = grade
        self.studentIds = studentIds
        self.schedule = schedule
    }
}
