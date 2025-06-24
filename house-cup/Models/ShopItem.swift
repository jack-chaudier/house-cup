//
//  ShopItem.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import Foundation

struct ShopItem: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let price: Int
    let category: ShopCategory
    let imageURL: String?
    var isActive: Bool
    let createdAt: Date
    let createdBy: String  // Teacher ID who requested
    var approvedBy: String?  // Admin ID who approved
    var approvedAt: Date?
    let stockQuantity: Int?  // nil = unlimited
    var soldCount: Int
    
    init(
        id: String = UUID().uuidString,
        name: String,
        description: String,
        price: Int,
        category: ShopCategory,
        imageURL: String? = nil,
        isActive: Bool = false,
        createdAt: Date = Date(),
        createdBy: String,
        approvedBy: String? = nil,
        approvedAt: Date? = nil,
        stockQuantity: Int? = nil,
        soldCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.price = price
        self.category = category
        self.imageURL = imageURL
        self.isActive = isActive
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.approvedBy = approvedBy
        self.approvedAt = approvedAt
        self.stockQuantity = stockQuantity
        self.soldCount = soldCount
    }
    
    var isAvailable: Bool {
        isActive && (stockQuantity == nil || (stockQuantity ?? 0) > soldCount)
    }
    
    var remainingStock: Int? {
        guard let stock = stockQuantity else { return nil }
        return stock - soldCount
    }
}

enum ShopCategory: String, CaseIterable, Codable {
    case apparel = "Apparel"
    case supplies = "School Supplies"
    case privileges = "Privileges"
    case experiences = "Experiences"
    case food = "Food & Treats"
    case accessories = "Accessories"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .apparel: return "tshirt"
        case .supplies: return "pencil.and.ruler"
        case .privileges: return "star.fill"
        case .experiences: return "ticket"
        case .food: return "fork.knife"
        case .accessories: return "bag"
        case .other: return "questionmark.circle"
        }
    }
}