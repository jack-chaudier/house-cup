//
//  ReportsView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//

import SwiftUI
import FirebaseFirestore
import Charts

struct ReportsView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Report Type", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Students").tag(1)
                    Text("Teachers").tag(2)
                    Text("Houses").tag(3)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                switch selectedTab {
                case 0:
                    OverviewReportView()
                case 1:
                    StudentReportView()
                case 2:
                    TeacherReportView()
                case 3:
                    HouseReportView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Analytics & Reports")
        }
    }
}

struct OverviewReportView: View {
    @State private var totalUsers = 0
    @State private var totalStudents = 0
    @State private var totalTeachers = 0
    @State private var totalPointsAwarded = 0
    @State private var totalPurchases = 0
    @State private var recentActivity: [(date: Date, points: Int)] = []
    @State private var isLoading = true
    
    let db = Firestore.firestore()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Cards
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    StatCard(
                        title: "Total Users",
                        value: "\(totalUsers)",
                        icon: "person.3.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        title: "Students",
                        value: "\(totalStudents)",
                        icon: "graduationcap.fill",
                        color: .green
                    )
                    
                    StatCard(
                        title: "Teachers",
                        value: "\(totalTeachers)",
                        icon: "person.fill.badge.plus",
                        color: .orange
                    )
                    
                    StatCard(
                        title: "Points Awarded",
                        value: "\(totalPointsAwarded)",
                        icon: "star.fill",
                        color: .yellow
                    )
                }
                .padding(.horizontal)
                
                // Activity Chart
                if !recentActivity.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Points Activity (Last 7 Days)")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(recentActivity, id: \.date) { item in
                            BarMark(
                                x: .value("Date", item.date, unit: .day),
                                y: .value("Points", item.points)
                            )
                            .foregroundStyle(.blue.gradient)
                        }
                        .frame(height: 200)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                Spacer(minLength: 50)
            }
            .padding(.top)
        }
        .task {
            await loadOverviewData()
        }
    }
    
    private func loadOverviewData() async {
        do {
            // Load user counts
            let usersSnapshot = try await db.collection("users").getDocuments()
            let users = usersSnapshot.documents.compactMap { doc -> AppUser? in
                try? doc.data(as: AppUser.self)
            }
            
            totalUsers = users.count
            totalStudents = users.filter { $0.userType == .student }.count
            totalTeachers = users.filter { $0.userType == .teacher }.count
            
            // Load total points
            let pointsSnapshot = try await db.collection("pointAwards").getDocuments()
            totalPointsAwarded = pointsSnapshot.documents.compactMap { doc -> Int? in
                doc.data()["points"] as? Int
            }.reduce(0, +)
            
            // Load purchase count
            let purchaseSnapshot = try await db.collection("purchases").getDocuments()
            totalPurchases = purchaseSnapshot.documents.count
            
            // Load recent activity (last 7 days)
            let sevenDaysAgo = Date().addingTimeInterval(-604800)
            let activitySnapshot = try await db.collection("pointAwards")
                .whereField("timestamp", isGreaterThan: sevenDaysAgo)
                .getDocuments()
            
            // Group by day
            var dailyPoints: [Date: Int] = [:]
            let calendar = Calendar.current
            
            for doc in activitySnapshot.documents {
                if let timestamp = (doc.data()["timestamp"] as? Timestamp)?.dateValue(),
                   let points = doc.data()["points"] as? Int {
                    let startOfDay = calendar.startOfDay(for: timestamp)
                    dailyPoints[startOfDay, default: 0] += points
                }
            }
            
            recentActivity = dailyPoints.sorted { $0.key < $1.key }.map { (date: $0.key, points: $0.value) }
            
            isLoading = false
        } catch {
            print("Error loading overview data: \(error)")
            isLoading = false
        }
    }
}

struct StudentReportView: View {
    @State private var topStudents: [(user: AppUser, points: Int)] = []
    @State private var mostActiveStudents: [(user: AppUser, purchases: Int)] = []
    @State private var isLoading = true
    
    let db = Firestore.firestore()
    
    var body: some View {
        List {
            Section("Top Students by Points") {
                if topStudents.isEmpty && !isLoading {
                    Text("No data available")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(topStudents.enumerated()), id: \.offset) { index, item in
                        HStack {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(item.user.displayName ?? "Unknown")
                                    .font(.headline)
                                Text(item.user.email ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Label("\(item.points)", systemImage: "star.fill")
                                .font(.headline)
                                .foregroundColor(.yellow)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Section("Most Active Shoppers") {
                if mostActiveStudents.isEmpty && !isLoading {
                    Text("No data available")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(mostActiveStudents.enumerated()), id: \.offset) { index, item in
                        HStack {
                            Text("\(index + 1)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading) {
                                Text(item.user.displayName ?? "Unknown")
                                    .font(.headline)
                                Text("\(item.purchases) purchases")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "cart.fill")
                                .foregroundColor(.orange)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .task {
            await loadStudentData()
        }
    }
    
    private func loadStudentData() async {
        do {
            // Load all students
            let usersSnapshot = try await db.collection("users")
                .whereField("userType", isEqualTo: UserType.student.rawValue)
                .getDocuments()
            
            let students = usersSnapshot.documents.compactMap { doc in
                try? doc.data(as: AppUser.self)
            }
            
            // Sort by points
            topStudents = students
                .map { ($0, $0.points) }
                .sorted { $0.1 > $1.1 }
                .prefix(10)
                .map { $0 }
            
            // Load purchase counts
            let purchasesSnapshot = try await db.collection("purchases").getDocuments()
            var purchaseCounts: [String: Int] = [:]
            
            for doc in purchasesSnapshot.documents {
                if let studentId = doc.data()["studentId"] as? String {
                    purchaseCounts[studentId, default: 0] += 1
                }
            }
            
            mostActiveStudents = students
                .compactMap { student in
                    let count = purchaseCounts[student.id] ?? 0
                    return count > 0 ? (student, count) : nil
                }
                .sorted { $0.1 > $1.1 }
                .prefix(10)
                .map { $0 }
            
            isLoading = false
        } catch {
            print("Error loading student data: \(error)")
            isLoading = false
        }
    }
}

struct TeacherReportView: View {
    @State private var mostActiveTeachers: [(teacher: AppUser, awardsGiven: Int, totalPoints: Int)] = []
    @State private var isLoading = true
    
    let db = Firestore.firestore()
    
    var body: some View {
        List {
            Section("Most Active Teachers") {
                if mostActiveTeachers.isEmpty && !isLoading {
                    Text("No data available")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(Array(mostActiveTeachers.enumerated()), id: \.offset) { index, item in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .frame(width: 30)
                                
                                VStack(alignment: .leading) {
                                    Text(item.teacher.displayName ?? "Unknown")
                                        .font(.headline)
                                    Text(item.teacher.email ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            HStack {
                                Label("\(item.awardsGiven) awards", systemImage: "gift")
                                    .font(.caption)
                                
                                Spacer()
                                
                                Label("\(item.totalPoints) pts given", systemImage: "star.fill")
                                    .font(.caption)
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .task {
            await loadTeacherData()
        }
    }
    
    private func loadTeacherData() async {
        do {
            // Load all teachers
            let teachersSnapshot = try await db.collection("users")
                .whereField("userType", isEqualTo: UserType.teacher.rawValue)
                .getDocuments()
            
            let teachers = teachersSnapshot.documents.compactMap { doc in
                try? doc.data(as: AppUser.self)
            }
            
            // Load awards data
            let awardsSnapshot = try await db.collection("pointAwards").getDocuments()
            var teacherStats: [String: (count: Int, points: Int)] = [:]
            
            for doc in awardsSnapshot.documents {
                if let teacherId = doc.data()["teacherId"] as? String,
                   let points = doc.data()["points"] as? Int {
                    let current = teacherStats[teacherId] ?? (0, 0)
                    teacherStats[teacherId] = (current.count + 1, current.points + points)
                }
            }
            
            mostActiveTeachers = teachers
                .compactMap { teacher in
                    guard let stats = teacherStats[teacher.id] else { return nil }
                    return (teacher, stats.count, stats.points)
                }
                .sorted { $0.2 > $1.2 } // Sort by total points given
                .prefix(10)
                .map { $0 }
            
            isLoading = false
        } catch {
            print("Error loading teacher data: \(error)")
            isLoading = false
        }
    }
}

struct HouseReportView: View {
    @State private var houses: [House] = []
    @State private var houseStats: [(house: House, studentCount: Int, avgPoints: Double)] = []
    @State private var isLoading = true
    
    let db = Firestore.firestore()
    
    var body: some View {
        List {
            ForEach(houseStats, id: \.house.id) { stat in
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "house.fill")
                            .font(.title2)
                            .foregroundColor(stat.house.color)
                        
                        VStack(alignment: .leading) {
                            Text(stat.house.displayName)
                                .font(.headline)
                            if let motto = stat.house.motto {
                                Text(motto)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Total Points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(stat.house.totalPoints)")
                                .font(.title3.bold())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Students")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(stat.studentCount)")
                                .font(.title3.bold())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Avg Points")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.1f", stat.avgPoints))
                                .font(.title3.bold())
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .task {
            await loadHouseData()
        }
    }
    
    private func loadHouseData() async {
        do {
            // Load houses
            let housesSnapshot = try await db.collection("houses").getDocuments()
            houses = housesSnapshot.documents.compactMap { doc in
                try? doc.data(as: House.self)
            }.sorted { $0.grade < $1.grade }
            
            // Load student counts per house
            let studentsSnapshot = try await db.collection("users")
                .whereField("userType", isEqualTo: UserType.student.rawValue)
                .getDocuments()
            
            var houseCounts: [String: Int] = [:]
            var housePointTotals: [String: Int] = [:]
            
            for doc in studentsSnapshot.documents {
                if let houseId = doc.data()["houseId"] as? String,
                   let points = doc.data()["points"] as? Int {
                    houseCounts[houseId, default: 0] += 1
                    housePointTotals[houseId, default: 0] += points
                }
            }
            
            houseStats = houses.map { house in
                let count = houseCounts[house.id] ?? 0
                let totalPoints = housePointTotals[house.id] ?? 0
                let avgPoints = count > 0 ? Double(totalPoints) / Double(count) : 0
                return (house, count, avgPoints)
            }
            
            isLoading = false
        } catch {
            print("Error loading house data: \(error)")
            isLoading = false
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title.bold())
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}