//
//  PointsHistoryView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct PointsHistoryView: View {
    @State private var pointsHistory: [PointTransaction] = []
    @State private var isLoading = true
    @State private var selectedFilter: TransactionFilter = .all
    @State private var currentUser: AppUser?
    
    let db = Firestore.firestore()
    
    var filteredTransactions: [PointTransaction] {
        switch selectedFilter {
        case .all:
            return pointsHistory
        case .earned:
            return pointsHistory.filter { $0.type == .earned }
        case .spent:
            return pointsHistory.filter { $0.type == .spent }
        }
    }
    
    var totalEarned: Int {
        pointsHistory.filter { $0.type == .earned }.reduce(0) { $0 + $1.points }
    }
    
    var totalSpent: Int {
        pointsHistory.filter { $0.type == .spent }.reduce(0) { $0 + $1.points }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Cards
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        SummaryCard(
                            title: "Available",
                            value: currentUser?.availablePoints ?? 0,
                            icon: "star.circle.fill",
                            color: .blue
                        )
                        
                        SummaryCard(
                            title: "Total Earned",
                            value: totalEarned,
                            icon: "arrow.up.circle.fill",
                            color: .green
                        )
                        
                        SummaryCard(
                            title: "Total Spent",
                            value: totalSpent,
                            icon: "cart.fill",
                            color: .orange
                        )
                    }
                    .padding()
                }
                
                // Filter Buttons
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag(TransactionFilter.all)
                    Text("Earned").tag(TransactionFilter.earned)
                    Text("Spent").tag(TransactionFilter.spent)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Transaction List
                if isLoading {
                    Spacer()
                    ProgressView("Loading history...")
                    Spacer()
                } else if filteredTransactions.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No transactions yet")
                            .font(.headline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                } else {
                    List(filteredTransactions) { transaction in
                        TransactionRow(transaction: transaction)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Points History")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadUserData()
                loadPointsHistory()
            }
        }
    }
    
    private func loadUserData() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(userId)
            .addSnapshotListener { snapshot, error in
                if let data = snapshot?.data() {
                    self.currentUser = AppUser(
                        uid: snapshot?.documentID ?? "",
                        email: data["email"] as? String,
                        displayName: data["displayName"] as? String,
                        userType: UserType(rawValue: data["userType"] as? String ?? "") ?? .none,
                        photoURL: data["photoURL"] as? String,
                        houseId: data["houseId"] as? String,
                        createdAt: (data["createdAt"] as? Timestamp)?.dateValue(),
                        grade: data["grade"] as? Int,
                        points: data["points"] as? Int ?? 0,
                        spentPoints: data["spentPoints"] as? Int ?? 0
                    )
                }
            }
    }
    
    private func loadPointsHistory() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        // Load earned points
        db.collection("pointAwards")
            .whereField("studentId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                let earnedTransactions = snapshot?.documents.compactMap { doc -> PointTransaction? in
                    guard let award = try? doc.data(as: PointAward.self) else { return nil }
                    return PointTransaction(
                        id: award.id,
                        type: .earned,
                        points: award.points,
                        description: award.reason,
                        category: award.category.rawValue,
                        date: award.timestamp,
                        relatedPersonName: award.teacherName
                    )
                } ?? []
                
                // Load spent points (purchases)
                db.collection("purchases")
                    .whereField("studentId", isEqualTo: userId)
                    .order(by: "purchaseDate", descending: true)
                    .getDocuments { snapshot, error in
                        let spentTransactions = snapshot?.documents.compactMap { doc -> PointTransaction? in
                            guard let purchase = try? doc.data(as: PurchaseHistory.self) else { return nil }
                            return PointTransaction(
                                id: purchase.id,
                                type: .spent,
                                points: purchase.itemPrice,
                                description: purchase.itemName,
                                category: "Shop Purchase",
                                date: purchase.purchaseDate,
                                status: purchase.status.rawValue
                            )
                        } ?? []
                        
                        // Combine and sort all transactions
                        self.pointsHistory = (earnedTransactions + spentTransactions)
                            .sorted { $0.date > $1.date }
                        self.isLoading = false
                    }
            }
    }
}

struct PointTransaction: Identifiable {
    let id: String
    let type: TransactionType
    let points: Int
    let description: String
    let category: String
    let date: Date
    var relatedPersonName: String? = nil
    var status: String? = nil
}

enum TransactionType {
    case earned
    case spent
}

enum TransactionFilter: String, CaseIterable {
    case all = "All"
    case earned = "Earned"
    case spent = "Spent"
}

struct SummaryCard: View {
    let title: String
    let value: Int
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(value)")
                    .font(.title2.bold())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(width: 140)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct TransactionRow: View {
    let transaction: PointTransaction
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: transaction.type == .earned ? "arrow.up.circle.fill" : "cart.fill")
                .font(.title2)
                .foregroundColor(transaction.type == .earned ? .green : .orange)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.headline)
                
                HStack {
                    Text(transaction.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let person = transaction.relatedPersonName {
                        Text("• by \(person)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let status = transaction.status {
                        Text("• \(status)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(transaction.date, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Points
            Text("\(transaction.type == .earned ? "+" : "-")\(transaction.points)")
                .font(.headline)
                .foregroundColor(transaction.type == .earned ? .green : .orange)
        }
        .padding(.vertical, 4)
    }
}