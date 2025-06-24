//
//  AdminView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI

struct AdminView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            List {
                Section("Admin Actions") {
                    NavigationLink(destination: UserManagementView()) {
                        Label("Manage Users", systemImage: "person.3.fill")
                    }
                    NavigationLink(destination: HouseManagementView()) {
                        Label("Manage Houses", systemImage: "house.fill")
                    }
                    NavigationLink(destination: ShopManagementView()) {
                        Label("Manage Shop", systemImage: "cart.fill")
                    }
                    NavigationLink(destination: PointsOverviewView()) {
                        Label("Points Overview", systemImage: "chart.bar.fill")
                    }
                    NavigationLink(destination: ReportsView()) {
                        Label("Reports", systemImage: "doc.text.fill")
                    }
                }
                
                Section("Quick Stats") {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Total Users")
                        Spacer()
                        Text("--")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Image(systemName: "trophy.fill")
                        Text("Total Points Awarded")
                        Spacer()
                        Text("--")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Profile") {
                    if let user = authManager.currentUser {
                        HStack {
                            Text("Name:")
                            Spacer()
                            Text(user.displayName ?? "Unknown")
                                .foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Role:")
                            Spacer()
                            Text("Administrator")
                                .foregroundColor(.red)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .navigationTitle("Admin Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SettingsButton()
                }
            }
        }
    }
}
