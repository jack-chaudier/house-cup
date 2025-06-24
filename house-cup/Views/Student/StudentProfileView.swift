//
//  StudentProfileView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct StudentProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var user: AppUser?
    @State private var house: House?
    @State private var recentAwards: [PointAward] = []
    @State private var recentPurchases: [PurchaseHistory] = []
    @State private var rankInHouse: Int?
    @State private var rankInGrade: Int?
    @State private var isLoading = true
    @State private var selectedTab = 0
    @State private var showingEditProfile = false
    
    let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Header
                    ProfileHeaderView(user: user, house: house)
                    
                    // Stats Cards
                    StatsCardsView(
                        user: user,
                        rankInHouse: rankInHouse,
                        rankInGrade: rankInGrade
                    )
                    
                    // Activity Tabs
                    VStack {
                        Picker("Activity", selection: $selectedTab) {
                            Text("Recent Awards").tag(0)
                            Text("Recent Purchases").tag(1)
                            Text("Achievements").tag(2)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal)
                        
                        switch selectedTab {
                        case 0:
                            RecentAwardsSection(awards: recentAwards)
                        case 1:
                            RecentPurchasesSection(purchases: recentPurchases)
                        case 2:
                            AchievementsSection(user: user)
                        default:
                            EmptyView()
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditProfile = true }) {
                        Image(systemName: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(user: user)
            }
            .task {
                await loadProfileData()
            }
            .refreshable {
                await loadProfileData()
            }
        }
    }
    
    private func loadProfileData() async {
        guard let currentUser = authManager.currentUser else { return }
        
        // Load user data
        do {
            let userDoc = try await db.collection("users").document(currentUser.id).getDocument()
            if let data = userDoc.data() {
                user = AppUser(
                    uid: userDoc.documentID,
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
            
            // Load house data
            if let houseId = user?.houseId {
                let houseDoc = try await db.collection("houses").document(houseId).getDocument()
                house = try? houseDoc.data(as: House.self)
            }
            
            // Load recent awards
            let awardsSnapshot = try await db.collection("pointAwards")
                .whereField("studentId", isEqualTo: currentUser.id)
                .order(by: "timestamp", descending: true)
                .limit(to: 10)
                .getDocuments()
            
            recentAwards = awardsSnapshot.documents.compactMap { doc in
                try? doc.data(as: PointAward.self)
            }
            
            // Load recent purchases
            let purchasesSnapshot = try await db.collection("purchases")
                .whereField("studentId", isEqualTo: currentUser.id)
                .order(by: "purchaseDate", descending: true)
                .limit(to: 10)
                .getDocuments()
            
            recentPurchases = purchasesSnapshot.documents.compactMap { doc in
                try? doc.data(as: PurchaseHistory.self)
            }
            
            // Calculate ranks
            await calculateRanks()
            
            isLoading = false
        } catch {
            print("Error loading profile data: \(error)")
            isLoading = false
        }
    }
    
    private func calculateRanks() async {
        guard let user = user else { return }
        
        do {
            // Rank in house
            if let houseId = user.houseId {
                let houseStudents = try await db.collection("users")
                    .whereField("houseId", isEqualTo: houseId)
                    .whereField("userType", isEqualTo: UserType.student.rawValue)
                    .getDocuments()
                
                let students = houseStudents.documents.compactMap { doc -> (id: String, points: Int)? in
                    guard let points = doc.data()["points"] as? Int else { return nil }
                    return (doc.documentID, points)
                }
                .sorted { $0.points > $1.points }
                
                rankInHouse = students.firstIndex { $0.id == user.id }.map { $0 + 1 }
            }
            
            // Rank in grade
            if let grade = user.grade {
                let gradeStudents = try await db.collection("users")
                    .whereField("grade", isEqualTo: grade)
                    .whereField("userType", isEqualTo: UserType.student.rawValue)
                    .getDocuments()
                
                let students = gradeStudents.documents.compactMap { doc -> (id: String, points: Int)? in
                    guard let points = doc.data()["points"] as? Int else { return nil }
                    return (doc.documentID, points)
                }
                .sorted { $0.points > $1.points }
                
                rankInGrade = students.firstIndex { $0.id == user.id }.map { $0 + 1 }
            }
        } catch {
            print("Error calculating ranks: \(error)")
        }
    }
}

struct ProfileHeaderView: View {
    let user: AppUser?
    let house: House?
    
    var body: some View {
        VStack(spacing: 16) {
            // Profile Picture
            if let photoURL = user?.photoURL, let url = URL(string: photoURL) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                }
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(house?.color ?? .gray, lineWidth: 3))
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                    .overlay(Circle().stroke(house?.color ?? .gray, lineWidth: 3))
            }
            
            // Name and Info
            VStack(spacing: 8) {
                Text(user?.displayName ?? "Student")
                    .font(.title2.bold())
                
                if let email = user?.email {
                    Text(email)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let house = house, let grade = user?.grade {
                    HStack {
                        Label(house.name, systemImage: "house.fill")
                            .foregroundColor(house.color)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("Grade \(grade)")
                    }
                    .font(.subheadline)
                }
            }
        }
        .padding()
    }
}

struct StatsCardsView: View {
    let user: AppUser?
    let rankInHouse: Int?
    let rankInGrade: Int?
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ProfileStatCard(
                title: "Total Points",
                value: "\(user?.points ?? 0)",
                icon: "star.fill",
                color: .yellow
            )
            
            ProfileStatCard(
                title: "Available",
                value: "\(user?.availablePoints ?? 0)",
                icon: "star.circle",
                color: .blue
            )
            
            ProfileStatCard(
                title: "Rank in House",
                value: rankInHouse != nil ? "#\(rankInHouse!)" : "-",
                icon: "house.fill",
                color: .purple
            )
            
            ProfileStatCard(
                title: "Rank in Grade",
                value: rankInGrade != nil ? "#\(rankInGrade!)" : "-",
                icon: "graduationcap.fill",
                color: .green
            )
        }
        .padding(.horizontal)
    }
}

struct RecentAwardsSection: View {
    let awards: [PointAward]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if awards.isEmpty {
                EmptyStateView(
                    icon: "star.slash",
                    message: "No awards yet"
                )
            } else {
                ForEach(awards) { award in
                    AwardItemRow(award: award)
                }
            }
        }
        .padding()
    }
}

struct RecentPurchasesSection: View {
    let purchases: [PurchaseHistory]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if purchases.isEmpty {
                EmptyStateView(
                    icon: "cart",
                    message: "No purchases yet"
                )
            } else {
                ForEach(purchases) { purchase in
                    PurchaseItemRow(purchase: purchase)
                }
            }
        }
        .padding()
    }
}

struct AchievementsSection: View {
    let user: AppUser?
    
    var achievements: [(title: String, description: String, icon: String, unlocked: Bool)] {
        guard let user = user else { return [] }
        
        return [
            ("First Points", "Earn your first points", "star", user.points > 0),
            ("Century Club", "Earn 100 points", "100.circle.fill", user.points >= 100),
            ("High Achiever", "Earn 500 points", "500.circle.fill", user.points >= 500),
            ("Point Master", "Earn 1000 points", "crown.fill", user.points >= 1000),
            ("Smart Shopper", "Make your first purchase", "cart.fill", user.spentPoints > 0),
            ("Regular Customer", "Spend 100 points", "bag.fill", user.spentPoints >= 100)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(achievements, id: \.title) { achievement in
                HStack {
                    Image(systemName: achievement.icon)
                        .font(.title2)
                        .foregroundColor(achievement.unlocked ? .yellow : .gray)
                        .frame(width: 40)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title)
                            .font(.headline)
                            .foregroundColor(achievement.unlocked ? .primary : .secondary)
                        Text(achievement.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if achievement.unlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "lock.circle")
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical)
    }
}

struct AwardItemRow: View {
    let award: PointAward
    
    var body: some View {
        HStack {
            Image(systemName: award.category.icon)
                .font(.title3)
                .foregroundColor(.yellow)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(award.reason)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(award.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("+\(award.points)")
                .font(.headline)
                .foregroundColor(.green)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct PurchaseItemRow: View {
    let purchase: PurchaseHistory
    
    var body: some View {
        HStack {
            Image(systemName: "cart.fill")
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(purchase.itemName)
                    .font(.subheadline)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(purchase.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                    Text("•")
                    Image(systemName: purchase.status.icon)
                        .font(.caption2)
                    Text(purchase.status.rawValue)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("-\(purchase.itemPrice)")
                .font(.headline)
                .foregroundColor(.red)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title2.bold())
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let icon: String
    let message: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

struct EditProfileView: View {
    let user: AppUser?
    @Environment(\.dismiss) var dismiss
    @State private var displayName = ""
    @State private var isUpdating = false
    
    let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Information") {
                    TextField("Display Name", text: $displayName)
                }
                
                Section("Account Information") {
                    LabeledContent("Email", value: user?.email ?? "")
                    LabeledContent("Grade", value: user?.grade != nil ? "Grade \(user!.grade!)" : "Not set")
                    LabeledContent("Member Since", value: user?.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateProfile()
                    }
                    .disabled(displayName.isEmpty || isUpdating)
                }
            }
            .onAppear {
                displayName = user?.displayName ?? ""
            }
        }
    }
    
    private func updateProfile() {
        guard let userId = user?.id else { return }
        
        isUpdating = true
        
        db.collection("users").document(userId).updateData([
            "displayName": displayName
        ]) { error in
            isUpdating = false
            if error == nil {
                dismiss()
            }
        }
    }
}