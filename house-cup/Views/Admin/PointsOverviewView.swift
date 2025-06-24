//
//  PointsOverviewView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//

import SwiftUI
import FirebaseFirestore

struct PointsOverviewView: View {
    @State private var recentAwards: [PointAward] = []
    @State private var isLoading = true
    @State private var dateFilter = DateFilter.today
    
    let db = Firestore.firestore()
    
    enum DateFilter: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
        case month = "This Month"
        case all = "All Time"
        
        var startDate: Date? {
            let calendar = Calendar.current
            switch self {
            case .today:
                return calendar.startOfDay(for: Date())
            case .week:
                return calendar.dateInterval(of: .weekOfYear, for: Date())?.start
            case .month:
                return calendar.dateInterval(of: .month, for: Date())?.start
            case .all:
                return nil
            }
        }
    }
    
    var filteredAwards: [PointAward] {
        guard let startDate = dateFilter.startDate else { return recentAwards }
        return recentAwards.filter { $0.timestamp >= startDate }
    }
    
    var totalPointsAwarded: Int {
        filteredAwards.reduce(0) { $0 + $1.points }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Summary Header
                VStack(spacing: 16) {
                    Picker("Time Period", selection: $dateFilter) {
                        ForEach(DateFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    HStack {
                        VStack {
                            Text("Points Awarded")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(totalPointsAwarded)")
                                .font(.largeTitle.bold())
                        }
                        
                        Spacer()
                        
                        VStack {
                            Text("Awards Given")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(filteredAwards.count)")
                                .font(.largeTitle.bold())
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
                
                // Recent Awards List
                if isLoading {
                    Spacer()
                    ProgressView("Loading awards...")
                    Spacer()
                } else if filteredAwards.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        "No Awards",
                        systemImage: "star.slash",
                        description: Text("No points have been awarded in this time period")
                    )
                    Spacer()
                } else {
                    List(filteredAwards) { award in
                        PointAwardDetailRow(award: award)
                    }
                }
            }
            .navigationTitle("Points Overview")
            .task {
                await loadRecentAwards()
            }
            .refreshable {
                await loadRecentAwards()
            }
        }
    }
    
    private func loadRecentAwards() async {
        do {
            let snapshot = try await db.collection("pointAwards")
                .order(by: "timestamp", descending: true)
                .limit(to: 500)
                .getDocuments()
            
            var awards = snapshot.documents.compactMap { doc -> PointAward? in
                guard var award = try? doc.data(as: PointAward.self) else { return nil }
                
                // Fetch additional display data
                let data = doc.data()
                award.studentName = data["studentName"] as? String ?? "Unknown Student"
                award.teacherName = data["teacherName"] as? String ?? "Unknown Teacher"
                award.houseName = data["houseName"] as? String ?? "Unknown House"
                
                return award
            }
            
            // Load names if they're missing
            for (index, award) in awards.enumerated() {
                if award.studentName?.isEmpty ?? true {
                    if let studentDoc = try? await db.collection("users").document(award.studentId).getDocument(),
                       let name = studentDoc.data()?["displayName"] as? String {
                        awards[index].studentName = name
                    }
                }
                
                if award.teacherName?.isEmpty ?? true {
                    if let teacherDoc = try? await db.collection("users").document(award.teacherId).getDocument(),
                       let name = teacherDoc.data()?["displayName"] as? String {
                        awards[index].teacherName = name
                    }
                }
                
                if award.houseName?.isEmpty ?? true {
                    if let houseDoc = try? await db.collection("houses").document(award.houseId).getDocument(),
                       let house = try? houseDoc.data(as: House.self) {
                        awards[index].houseName = house.displayName
                    }
                }
            }
            
            recentAwards = awards
            isLoading = false
        } catch {
            print("Error loading awards: \(error)")
            isLoading = false
        }
    }
}

struct PointAwardDetailRow: View {
    let award: PointAward
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(award.studentName ?? "Unknown")
                        .font(.headline)
                    
                    HStack {
                        Label(award.category.rawValue, systemImage: award.category.icon)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(award.houseName ?? "Unknown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Label("\(award.points)", systemImage: "star.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    
                    Text(award.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(award.reason)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "person.fill")
                    .font(.caption)
                Text("Awarded by \(award.teacherName ?? "Unknown")")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}