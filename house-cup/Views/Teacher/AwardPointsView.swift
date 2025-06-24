//
//  AwardPointsView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseFirestore

struct AwardPointsView: View {
    @State private var selectedStudent: AppUser?
    @State private var selectedCategory: AwardCategory = .academic
    @State private var pointAmount = "10"
    @State private var reason = ""
    @State private var students: [AppUser] = []
    @State private var isLoading = false
    @State private var showSuccess = false
    @EnvironmentObject var authManager: AuthManager
    
    private let db = Firestore.firestore()
    
    var body: some View {
        Form {
            Section("Select Student") {
                Picker("Student", selection: $selectedStudent) {
                    Text("Select a student").tag(nil as AppUser?)
                    ForEach(students) { student in
                        Text(student.displayName ?? "Unknown")
                            .tag(student as AppUser?)
                    }
                }
            }
            
            Section("Award Details") {
                Picker("Category", selection: $selectedCategory) {
                    ForEach(AwardCategory.allCases, id: \.self) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .tag(category)
                    }
                }
                
                HStack {
                    Text("Points:")
                    TextField("Points", text: $pointAmount)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                TextField("Reason", text: $reason, axis: .vertical)
                    .lineLimit(3...5)
            }
            
            Section {
                Button {
                    Task {
                        await awardPoints()
                    }
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Award Points")
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(selectedStudent == nil || reason.isEmpty || pointAmount.isEmpty)
            }
        }
        .navigationTitle("Award Points")
        .alert("Success!", isPresented: $showSuccess) {
            Button("OK") {
                // Reset form
                selectedStudent = nil
                pointAmount = "10"
                reason = ""
            }
        } message: {
            Text("Points awarded successfully!")
        }
        .task {
            await loadStudents()
        }
    }
    
    private func loadStudents() async {
        isLoading = true
        do {
            let snapshot = try await db.collection("users")
                .whereField("userType", isEqualTo: UserType.student.rawValue)
                .getDocuments()
            
            students = snapshot.documents.compactMap { doc -> AppUser? in
                let data = doc.data()
                return AppUser(
                    uid: doc.documentID,
                    email: data["email"] as? String,
                    displayName: data["displayName"] as? String,
                    userType: .student,
                    photoURL: data["photoURL"] as? String,
                    houseId: data["houseId"] as? String
                )
            }
        } catch {
            print("Error loading students: \(error)")
        }
        isLoading = false
    }
    
    private func awardPoints() async {
        guard let student = selectedStudent,
              let points = Int(pointAmount),
              let teacherId = authManager.currentUser?.id,
              let houseId = student.houseId else { return }
        
        let award = PointAward(
            studentId: student.id,
            teacherId: teacherId,
            houseId: houseId,
            points: points,
            reason: reason,
            category: selectedCategory
        )
        
        do {
            // Use batch write for atomic operation
            let batch = db.batch()
            
            // Save the award
            let awardRef = db.collection("pointAwards").document(award.id)
            try batch.setData(from: award, forDocument: awardRef)
            
            // Update student points
            let studentRef = db.collection("users").document(student.id)
            batch.updateData(["points": FieldValue.increment(Int64(points))], forDocument: studentRef)
            
            // Update house points
            let houseRef = db.collection("houses").document(houseId)
            batch.updateData(["totalPoints": FieldValue.increment(Int64(points))], forDocument: houseRef)
            
            // Commit the batch
            try await batch.commit()
            
            showSuccess = true
        } catch {
            print("Error awarding points: \(error)")
        }
    }
}
