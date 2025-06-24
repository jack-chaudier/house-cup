//
//  PurchaseHistory.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation

struct PurchaseHistory: Identifiable, Codable {
    let id: String
    let studentId: String
    let studentName: String
    let itemId: String
    let itemName: String
    let itemPrice: Int
    let purchaseDate: Date
    let status: PurchaseStatus
    var fulfilledDate: Date?
    var fulfilledBy: String?  // Teacher/Admin ID
    var notes: String?
    
    init(
        id: String = UUID().uuidString,
        studentId: String,
        studentName: String,
        itemId: String,
        itemName: String,
        itemPrice: Int,
        purchaseDate: Date = Date(),
        status: PurchaseStatus = .pending,
        fulfilledDate: Date? = nil,
        fulfilledBy: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.studentId = studentId
        self.studentName = studentName
        self.itemId = itemId
        self.itemName = itemName
        self.itemPrice = itemPrice
        self.purchaseDate = purchaseDate
        self.status = status
        self.fulfilledDate = fulfilledDate
        self.fulfilledBy = fulfilledBy
        self.notes = notes
    }
}

enum PurchaseStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case fulfilled = "Fulfilled"
    case cancelled = "Cancelled"
    
    var color: String {
        switch self {
        case .pending: return "orange"
        case .fulfilled: return "green"
        case .cancelled: return "red"
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .fulfilled: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        }
    }
}