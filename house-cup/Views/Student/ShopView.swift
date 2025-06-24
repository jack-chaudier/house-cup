//
//  ShopView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ShopView: View {
    @State private var shopItems: [ShopItem] = []
    @State private var selectedCategory: ShopCategory? = nil
    @State private var isLoading = true
    @State private var showingPurchaseAlert = false
    @State private var selectedItem: ShopItem?
    @State private var availablePoints = 0
    @State private var searchText = ""
    
    let db = Firestore.firestore()
    
    var filteredItems: [ShopItem] {
        shopItems.filter { item in
            let matchesCategory = selectedCategory == nil || item.category == selectedCategory
            let matchesSearch = searchText.isEmpty || 
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.description.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch && item.isAvailable
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Points Balance Header
                HStack {
                    Label("Available Points", systemImage: "star.circle.fill")
                        .font(.headline)
                    Spacer()
                    Text("\(availablePoints)")
                        .font(.title2.bold())
                        .foregroundColor(.accentColor)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search items...", text: $searchText)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                
                // Category Filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        CategoryChip(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
                        ForEach(ShopCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                
                // Items Grid
                if isLoading {
                    Spacer()
                    ProgressView("Loading shop items...")
                    Spacer()
                } else if filteredItems.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "cart")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No items available")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(filteredItems) { item in
                                ShopItemCard(
                                    item: item,
                                    availablePoints: availablePoints,
                                    onPurchase: {
                                        selectedItem = item
                                        showingPurchaseAlert = true
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadShopItems()
                loadUserPoints()
            }
            .alert("Confirm Purchase", isPresented: $showingPurchaseAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Purchase") {
                    if let item = selectedItem {
                        purchaseItem(item)
                    }
                }
            } message: {
                if let item = selectedItem {
                    Text("Purchase \(item.name) for \(item.price) points?")
                }
            }
        }
    }
    
    private func loadShopItems() {
        db.collection("shopItems")
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    print("Error loading shop items: \(error)")
                    return
                }
                
                self.shopItems = snapshot?.documents.compactMap { doc in
                    try? doc.data(as: ShopItem.self)
                } ?? []
                
                self.isLoading = false
            }
    }
    
    private func loadUserPoints() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId)
            .addSnapshotListener { snapshot, error in
                if let data = snapshot?.data() {
                    let points = data["points"] as? Int ?? 0
                    let spentPoints = data["spentPoints"] as? Int ?? 0
                    self.availablePoints = points - spentPoints
                }
            }
    }
    
    private func purchaseItem(_ item: ShopItem) {
        guard let userId = Auth.auth().currentUser?.uid,
              let userName = Auth.auth().currentUser?.displayName else { return }
        
        // Create purchase record
        let purchase = PurchaseHistory(
            studentId: userId,
            studentName: userName,
            itemId: item.id,
            itemName: item.name,
            itemPrice: item.price
        )
        
        // Use a batch write for atomic operation
        let batch = db.batch()
        
        // Add purchase record
        let purchaseRef = db.collection("purchases").document(purchase.id)
        try? batch.setData(from: purchase, forDocument: purchaseRef)
        
        // Update user's spent points
        let userRef = db.collection("users").document(userId)
        batch.updateData(["spentPoints": FieldValue.increment(Int64(item.price))], forDocument: userRef)
        
        // Update item sold count
        let itemRef = db.collection("shopItems").document(item.id)
        batch.updateData(["soldCount": FieldValue.increment(Int64(1))], forDocument: itemRef)
        
        // Commit the batch
        batch.commit { error in
            if let error = error {
                print("Error purchasing item: \(error)")
            }
        }
    }
}

struct CategoryChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption.bold())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

struct ShopItemCard: View {
    let item: ShopItem
    let availablePoints: Int
    let onPurchase: () -> Void
    
    var canAfford: Bool {
        availablePoints >= item.price
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Item Image/Icon
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray5))
                .frame(height: 120)
                .overlay(
                    Image(systemName: item.category.icon)
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                )
            
            // Item Info
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                    .lineLimit(2)
                
                Text(item.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Stock indicator
                if let remainingStock = item.remainingStock {
                    HStack {
                        Image(systemName: "cube.box")
                            .font(.caption2)
                        Text("\(remainingStock) left")
                            .font(.caption2)
                    }
                    .foregroundColor(.orange)
                }
                
                Spacer()
                
                // Price and Purchase Button
                HStack {
                    Label("\(item.price)", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundColor(canAfford ? .primary : .red)
                    
                    Spacer()
                    
                    Button(action: onPurchase) {
                        Image(systemName: "cart.badge.plus")
                            .font(.body.bold())
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canAfford)
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}