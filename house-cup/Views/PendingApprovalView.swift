//
//  PendingApprovalView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//



import SwiftUI

struct PendingApprovalView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Account Pending Approval")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Your account is awaiting role assignment by an administrator.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Text("Please contact your administrator to complete setup.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button {
                try? authManager.signOut()
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}
