//
//  UserManagement.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseFirestore

struct UserManagementView: View {
    @State private var users: [AppUser] = []
    @State private var houses: [House] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var filterType: UserType? = nil
    private let db = Firestore.firestore()
    
    var filteredUsers: [AppUser] {
        var result = users
        
        if !searchText.isEmpty {
            result = result.filter { user in
                (user.displayName?.lowercased().contains(searchText.lowercased()) ?? false) ||
                (user.email?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
        
        if let filterType = filterType {
            result = result.filter { $0.userType == filterType }
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Pills
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterPill(title: "All", isSelected: filterType == nil) {
                        filterType = nil
                    }
                    ForEach(UserType.allCases, id: \.self) { type in
                        FilterPill(title: type.displayName, isSelected: filterType == type) {
                            filterType = type
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            List {
                ForEach(filteredUsers) { user in
                    UserRow(user: user, houses: houses, onUpdate: { updatedUser in
                        updateUser(user: updatedUser)
                    })
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search users")
        .navigationTitle("Manage Users")
        .navigationBarTitleDisplayMode(.large)
        .overlay {
            if isLoading {
                ProgressView()
            } else if users.isEmpty {
                ContentUnavailableView(
                    "No Users",
                    systemImage: "person.slash",
                    description: Text("No users found")
                )
            }
        }
        .task {
            await loadUsers()
            await loadHouses()
        }
        .refreshable {
            await loadUsers()
            await loadHouses()
        }
    }
    
    private func loadUsers() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("users").getDocuments()
            users = snapshot.documents.compactMap { doc -> AppUser? in
                let data = doc.data()
                return AppUser(
                    uid: doc.documentID,
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
        } catch {
            print("Error loading users: \(error)")
        }
        isLoading = false
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
    
    private func updateUser(user: AppUser) {
        Task {
            do {
                var updateData: [String: Any] = [
                    "userType": user.userType.rawValue
                ]
                
                if let houseId = user.houseId {
                    updateData["houseId"] = houseId
                }
                
                if let grade = user.grade {
                    updateData["grade"] = grade
                }
                
                try await db.collection("users").document(user.id).updateData(updateData)
                await loadUsers()
            } catch {
                print("Error updating user: \(error)")
            }
        }
    }
}

struct UserRow: View {
    let user: AppUser
    let houses: [House]
    let onUpdate: (AppUser) -> Void
    @State private var selectedRole: UserType
    @State private var selectedHouseId: String?
    @State private var selectedGrade: Int?
    @State private var showingHouseSelection = false
    
    init(user: AppUser, houses: [House], onUpdate: @escaping (AppUser) -> Void) {
        self.user = user
        self.houses = houses
        self.onUpdate = onUpdate
        self._selectedRole = State(initialValue: user.userType)
        self._selectedHouseId = State(initialValue: user.houseId)
        self._selectedGrade = State(initialValue: user.grade)
    }
    
    var availableHouses: [House] {
        guard let grade = selectedGrade else { return [] }
        return houses.filter { $0.grade == grade }
    }
    
    var assignedHouse: House? {
        guard let houseId = selectedHouseId else { return nil }
        return houses.first { $0.id == houseId }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.displayName ?? "Unknown")
                        .font(.headline)
                    Text(user.email ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if user.userType == .student {
                        HStack(spacing: 8) {
                            if let house = assignedHouse {
                                Label(house.displayName, systemImage: "house.fill")
                                    .font(.caption)
                                    .foregroundColor(house.color)
                            } else if selectedGrade != nil {
                                Label("No house assigned", systemImage: "house")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            
                            Text("•")
                                .foregroundColor(.secondary)
                            
                            Label("\(user.availablePoints) pts", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                
                Spacer()
                
                // Role Selection
                Menu {
                    ForEach(UserType.allCases, id: \.self) { userType in
                        Button {
                            selectedRole = userType
                            updateUser()
                        } label: {
                            Label(userType.displayName, systemImage: iconForRole(userType))
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedRole.displayName)
                            .font(.caption)
                            .foregroundColor(colorForRole(selectedRole))
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(colorForRole(selectedRole).opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Student-specific controls
            if user.userType == .student {
                HStack(spacing: 12) {
                    // Grade Selection
                    Menu {
                        ForEach(9...12, id: \.self) { grade in
                            Button {
                                selectedGrade = grade
                                selectedHouseId = nil // Reset house when grade changes
                                updateUser()
                            } label: {
                                Text("Grade \(grade)")
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "graduationcap")
                                .font(.caption)
                            Text(selectedGrade != nil ? "Grade \(selectedGrade!)" : "Select Grade")
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // House Assignment
                    if selectedGrade != nil {
                        Button {
                            showingHouseSelection = true
                        } label: {
                            HStack {
                                Image(systemName: "house")
                                    .font(.caption)
                                Text(assignedHouse?.name ?? "Assign House")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(assignedHouse != nil ? assignedHouse!.color.opacity(0.2) : Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingHouseSelection) {
            HouseSelectionSheet(
                houses: availableHouses,
                selectedHouseId: $selectedHouseId,
                onSelect: { houseId in
                    selectedHouseId = houseId
                    updateUser()
                }
            )
        }
    }
    
    private func updateUser() {
        let updatedUser = AppUser(
            uid: user.id,
            email: user.email,
            displayName: user.displayName,
            userType: selectedRole,
            photoURL: user.photoURL,
            houseId: selectedHouseId,
            createdAt: user.createdAt,
            grade: selectedGrade,
            points: user.points,
            spentPoints: user.spentPoints
        )
        onUpdate(updatedUser)
    }
    
    private func colorForRole(_ role: UserType) -> Color {
        switch role {
        case .admin: return .red
        case .teacher: return .blue
        case .student: return .green
        case .none: return .gray
        }
    }
    
    private func iconForRole(_ role: UserType) -> String {
        switch role {
        case .admin: return "shield.fill"
        case .teacher: return "graduationcap.fill"
        case .student: return "backpack.fill"
        case .none: return "clock.fill"
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct HouseSelectionSheet: View {
    let houses: [House]
    @Binding var selectedHouseId: String?
    let onSelect: (String?) -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if houses.isEmpty {
                    ContentUnavailableView(
                        "No Houses Available",
                        systemImage: "house.slash",
                        description: Text("Please select a grade first or create houses for this grade")
                    )
                } else {
                    ForEach(houses) { house in
                        Button {
                            selectedHouseId = house.id
                            onSelect(house.id)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "house.fill")
                                    .foregroundColor(house.color)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(house.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    if let motto = house.motto {
                                        Text(motto)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack {
                                        Label("\(house.totalPoints) pts", systemImage: "star.fill")
                                            .font(.caption)
                                            .foregroundColor(.yellow)
                                        
                                        if let mascot = house.mascot {
                                            Text("• \(mascot)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                                
                                Spacer()
                                
                                if selectedHouseId == house.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    if selectedHouseId != nil {
                        Button(role: .destructive) {
                            selectedHouseId = nil
                            onSelect(nil)
                            dismiss()
                        } label: {
                            Label("Remove House Assignment", systemImage: "xmark.circle")
                        }
                    }
                }
            }
            .navigationTitle("Select House")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
