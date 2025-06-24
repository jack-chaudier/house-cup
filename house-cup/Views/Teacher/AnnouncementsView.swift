//
//  AnnouncementsView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct AnnouncementsView: View {
    @State private var announcements: [Announcement] = []
    @State private var showingNewAnnouncement = false
    @State private var isLoading = true
    
    let db = Firestore.firestore()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(announcements) { announcement in
                    AnnouncementRow(announcement: announcement)
                }
                
                if announcements.isEmpty && !isLoading {
                    ContentUnavailableView(
                        "No Announcements",
                        systemImage: "megaphone",
                        description: Text("Create your first announcement")
                    )
                }
            }
            .navigationTitle("Announcements")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewAnnouncement = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewAnnouncement) {
                CreateAnnouncementView()
            }
            .task {
                await loadAnnouncements()
            }
            .refreshable {
                await loadAnnouncements()
            }
        }
    }
    
    private func loadAnnouncements() async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        do {
            let snapshot = try await db.collection("announcements")
                .whereField("authorId", isEqualTo: userId)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            announcements = snapshot.documents.compactMap { doc in
                try? doc.data(as: Announcement.self)
            }
            isLoading = false
        } catch {
            print("Error loading announcements: \(error)")
            isLoading = false
        }
    }
}

struct CreateAnnouncementView: View {
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var message = ""
    @State private var targetAudience = TargetAudience.students
    @State private var selectedGrades: Set<Int> = []
    @State private var selectedHouses: Set<String> = []
    @State private var priority = AnnouncementPriority.normal
    @State private var expiresIn: ExpirationOption = .never
    @State private var isSubmitting = false
    @State private var houses: [House] = []
    
    let db = Firestore.firestore()
    
    enum ExpirationOption: String, CaseIterable {
        case never = "Never"
        case oneDay = "1 Day"
        case threeDays = "3 Days"
        case oneWeek = "1 Week"
        case twoWeeks = "2 Weeks"
        
        var expirationDate: Date? {
            switch self {
            case .never: return nil
            case .oneDay: return Date().addingTimeInterval(86400)
            case .threeDays: return Date().addingTimeInterval(259200)
            case .oneWeek: return Date().addingTimeInterval(604800)
            case .twoWeeks: return Date().addingTimeInterval(1209600)
            }
        }
    }
    
    var isValid: Bool {
        !title.isEmpty && !message.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Announcement Details") {
                    TextField("Title", text: $title)
                    
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section("Target Audience") {
                    Picker("Audience", selection: $targetAudience) {
                        ForEach(TargetAudience.allCases, id: \.self) { audience in
                            Text(audience.rawValue).tag(audience)
                        }
                    }
                    
                    if targetAudience == .specificGrades {
                        VStack(alignment: .leading) {
                            Text("Select Grades")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                ForEach(9...12, id: \.self) { grade in
                                    Button {
                                        if selectedGrades.contains(grade) {
                                            selectedGrades.remove(grade)
                                        } else {
                                            selectedGrades.insert(grade)
                                        }
                                    } label: {
                                        Text("Grade \(grade)")
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(selectedGrades.contains(grade) ? Color.accentColor : Color(.systemGray6))
                                            .foregroundColor(selectedGrades.contains(grade) ? .white : .primary)
                                            .cornerRadius(20)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    
                    if targetAudience == .specificHouses && !houses.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Select Houses")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ForEach(houses) { house in
                                Button {
                                    if selectedHouses.contains(house.id) {
                                        selectedHouses.remove(house.id)
                                    } else {
                                        selectedHouses.insert(house.id)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: selectedHouses.contains(house.id) ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedHouses.contains(house.id) ? .accentColor : .gray)
                                        
                                        Text(house.displayName)
                                        
                                        Spacer()
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
                
                Section("Settings") {
                    Picker("Priority", selection: $priority) {
                        ForEach(AnnouncementPriority.allCases, id: \.self) { priority in
                            Label(priority.rawValue, systemImage: priority.icon)
                                .tag(priority)
                        }
                    }
                    
                    Picker("Expires", selection: $expiresIn) {
                        ForEach(ExpirationOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                }
            }
            .navigationTitle("New Announcement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        createAnnouncement()
                    }
                    .disabled(!isValid || isSubmitting)
                }
            }
            .task {
                await loadHouses()
            }
        }
    }
    
    private func loadHouses() async {
        do {
            let snapshot = try await db.collection("houses").getDocuments()
            houses = snapshot.documents.compactMap { doc in
                try? doc.data(as: House.self)
            }.sorted { $0.grade < $1.grade }
        } catch {
            print("Error loading houses: \(error)")
        }
    }
    
    private func createAnnouncement() {
        guard let userId = Auth.auth().currentUser?.uid,
              let userName = Auth.auth().currentUser?.displayName else { return }
        
        isSubmitting = true
        
        let announcement = Announcement(
            authorId: userId,
            authorName: userName,
            authorType: .teacher,
            title: title,
            message: message,
            targetAudience: targetAudience,
            targetGrades: targetAudience == .specificGrades ? Array(selectedGrades) : nil,
            targetHouseIds: targetAudience == .specificHouses ? Array(selectedHouses) : nil,
            priority: priority,
            expiresAt: expiresIn.expirationDate
        )
        
        do {
            try db.collection("announcements").document(announcement.id).setData(from: announcement) { error in
                isSubmitting = false
                if error == nil {
                    dismiss()
                }
            }
        } catch {
            isSubmitting = false
            print("Error creating announcement: \(error)")
        }
    }
}

struct AnnouncementRow: View {
    let announcement: Announcement
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: announcement.priority.icon)
                    .foregroundColor(Color(announcement.priority.color))
                
                Text(announcement.title)
                    .font(.headline)
                
                Spacer()
                
                if !announcement.isVisible {
                    Text("Expired")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            
            Text(announcement.message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(announcement.targetAudience.rawValue, systemImage: "person.2")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(announcement.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}