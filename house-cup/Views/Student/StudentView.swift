//
//  StudentView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseFirestore

struct StudentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var myHouse: House?
    @State private var recentAwards: [PointAward] = []
    @State private var currentUser: AppUser?
    private let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Points Summary Card
                    if let user = currentUser {
                        PointsSummaryCard(user: user)
                    }
                    
                    if let house = myHouse {
                        HouseCard(house: house)
                    }
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        NavigationLink(destination: ShopView()) {
                            QuickActionCard(
                                icon: "cart.fill",
                                title: "Shop",
                                subtitle: "Spend your points",
                                color: .orange
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: PointsHistoryView()) {
                            QuickActionCard(
                                icon: "clock.arrow.circlepath",
                                title: "Points History",
                                subtitle: "View all transactions",
                                color: .purple
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: LeaderboardView()) {
                            QuickActionCard(
                                icon: "chart.bar.fill",
                                title: "Leaderboard",
                                subtitle: "House rankings",
                                color: .blue
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        NavigationLink(destination: StudentAnnouncementsView()) {
                            QuickActionCard(
                                icon: "megaphone.fill",
                                title: "Announcements",
                                subtitle: "Updates from teachers",
                                color: .indigo
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Awards")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if recentAwards.isEmpty {
                            Text("No awards yet")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        } else {
                            ForEach(recentAwards) { award in
                                AwardRow(award: award)
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("My Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: StudentProfileView()) {
                        Image(systemName: "person.circle")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    SettingsButton()
                }
            }
        }
        .task {
            await loadUserData()
            await loadMyHouse()
            await loadRecentAwards()
        }
    }
    
    private func loadUserData() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        do {
            let doc = try await db.collection("users").document(userId).getDocument()
            currentUser = try? doc.data(as: AppUser.self)
        } catch {
            print("Error loading user data: \(error)")
        }
    }
    
    private func loadMyHouse() async {
        guard let houseId = authManager.currentUser?.houseId else { return }
        
        do {
            let doc = try await db.collection("houses").document(houseId).getDocument()
            myHouse = try? doc.data(as: House.self)
        } catch {
            print("Error loading house: \(error)")
        }
    }
    
    private func loadRecentAwards() async {
        guard let userId = authManager.currentUser?.id else { return }
        
        do {
            let snapshot = try await db.collection("pointAwards")
                .whereField("studentId", isEqualTo: userId)
                .order(by: "timestamp", descending: true)
                .limit(to: 5)
                .getDocuments()
            
            recentAwards = snapshot.documents.compactMap { doc in
                try? doc.data(as: PointAward.self)
            }
        } catch {
            print("Error loading awards: \(error)")
        }
    }
}

struct HouseCard: View {
    let house: House
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(house.name)
                        .font(.title)
                        .fontWeight(.bold)
                    if let motto = house.motto {
                        Text(motto)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "shield.fill")
                    .font(.system(size: 40))
                    .foregroundColor(house.color)
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(house.totalPoints)")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                Spacer()
            }
        }
        .padding()
        .background(house.color.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct PointsSummaryCard: View {
    let user: AppUser
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("My Points")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(user.availablePoints)")
                            .font(.title.bold())
                            .foregroundColor(.accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Earned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(user.points)")
                            .font(.title3)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(user.spentPoints)")
                            .font(.title3)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "star.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.accentColor.opacity(0.1), Color.accentColor.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct AwardRow: View {
    let award: PointAward
    
    var body: some View {
        HStack {
            Image(systemName: award.category.icon)
                .font(.title2)
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(award.reason)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(award.timestamp.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("+\(award.points)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding(.vertical, 8)
    }
}
