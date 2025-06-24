//
//  ContentView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/21/25.
//

import SwiftUI
import FirebaseFirestore

struct ContentView: View {
    @StateObject private var authManager = AuthManager()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        Group {
            switch authManager.authState {
            case .loading:
                ProgressView()
                    .scaleEffect(1.5)
            case .signedOut:
                SignInView()
            case .signedIn:
                AuthenticatedView()
                    .task {
                        await loadHouseColor()
                    }
            }
        }
        .environmentObject(authManager)
    }
    
    private func loadHouseColor() async {
        guard let user = authManager.currentUser,
              user.userType == .student,
              let houseId = user.houseId else { return }
        
        do {
            let houseDoc = try await Firestore.firestore()
                .collection("houses")
                .document(houseId)
                .getDocument()
            
            if let house = try? houseDoc.data(as: House.self) {
                themeManager.setHouseColor(house.color)
            }
        } catch {
            print("Error loading house color: \(error)")
        }
    }
}

struct AuthenticatedView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        if let user = authManager.currentUser {
            switch user.userType {
            case .admin:
                AdminView()
            case .teacher:
                TeacherView()
            case .student:
                StudentView()
            case .none:
                PendingApprovalView()
            }
        } else {
            ProgressView()
        }
    }
}

#Preview {
    ContentView()
}
