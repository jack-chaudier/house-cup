//
//  StudentAnnouncementsView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct StudentAnnouncementsView: View {
    @State private var announcements: [Announcement] = []
    @State private var isLoading = true
    @EnvironmentObject var authManager: AuthManager
    
    let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(announcements) { announcement in
                    StudentAnnouncementRow(announcement: announcement)
                }
                
                if announcements.isEmpty && !isLoading {
                    ContentUnavailableView(
                        "No Announcements",
                        systemImage: "megaphone",
                        description: Text("Check back later for updates from your teachers")
                    )
                }
            }
            .navigationTitle("Announcements")
            .task {
                await loadAnnouncements()
            }
            .refreshable {
                await loadAnnouncements()
            }
        }
    }
    
    private func loadAnnouncements() async {
        guard let user = authManager.currentUser else { return }
        
        do {
            let snapshot = try await db.collection("announcements")
                .whereField("isActive", isEqualTo: true)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            let allAnnouncements = snapshot.documents.compactMap { doc in
                try? doc.data(as: Announcement.self)
            }
            
            // Filter announcements based on target audience
            announcements = allAnnouncements.filter { announcement in
                // Check if expired
                if !announcement.isVisible {
                    return false
                }
                
                switch announcement.targetAudience {
                case .all:
                    return true
                case .students:
                    return user.userType == .student
                case .teachers:
                    return false // Students shouldn't see teacher-only announcements
                case .specificGrades:
                    guard let userGrade = user.grade,
                          let targetGrades = announcement.targetGrades else { return false }
                    return targetGrades.contains(userGrade)
                case .specificHouses:
                    guard let userHouseId = user.houseId,
                          let targetHouses = announcement.targetHouseIds else { return false }
                    return targetHouses.contains(userHouseId)
                }
            }
            
            isLoading = false
        } catch {
            print("Error loading announcements: \(error)")
            isLoading = false
        }
    }
}

struct StudentAnnouncementRow: View {
    let announcement: Announcement
    @State private var isExpanded = false
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: announcement.priority.icon)
                        .foregroundColor(Color(announcement.priority.color))
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(announcement.title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("by \(announcement.authorName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Text(announcement.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(isExpanded ? nil : 2)
                    .animation(.easeInOut, value: isExpanded)
                
                HStack {
                    if announcement.priority == .urgent {
                        Label("Urgent", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    Text(announcement.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}