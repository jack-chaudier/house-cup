//
//  ShopRequest.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation

struct ShopRequest: Identifiable, Codable {
    let id: String
    let teacherId: String
    let teacherName: String
    let itemName: String
    let itemDescription: String
    let suggestedPrice: Int
    let category: ShopCategory
    let justification: String
    let requestDate: Date
    var status: RequestStatus
    var adminNotes: String?
    var reviewedBy: String?
    var reviewedDate: Date?
    
    init(
        id: String = UUID().uuidString,
        teacherId: String,
        teacherName: String,
        itemName: String,
        itemDescription: String,
        suggestedPrice: Int,
        category: ShopCategory,
        justification: String,
        requestDate: Date = Date(),
        status: RequestStatus = .pending,
        adminNotes: String? = nil,
        reviewedBy: String? = nil,
        reviewedDate: Date? = nil
    ) {
        self.id = id
        self.teacherId = teacherId
        self.teacherName = teacherName
        self.itemName = itemName
        self.itemDescription = itemDescription
        self.suggestedPrice = suggestedPrice
        self.category = category
        self.justification = justification
        self.requestDate = requestDate
        self.status = status
        self.adminNotes = adminNotes
        self.reviewedBy = reviewedBy
        self.reviewedDate = reviewedDate
    }
}

enum RequestStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case approved = "Approved"
    case rejected = "Rejected"
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .approved: return "green"
        case .rejected: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        }
    }
}