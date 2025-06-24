//
//  TeacherView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI

struct TeacherView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            List {
                Section("Quick Actions") {
                    NavigationLink(destination: AwardPointsView()) {
                        Label("Award Points", systemImage: "star.circle.fill")
                            .foregroundColor(.yellow)
                    }
                    NavigationLink(destination: ShopRequestsListView()) {
                        Label("Shop Requests", systemImage: "cart.badge.plus")
                            .foregroundColor(.orange)
                    }
                    NavigationLink(destination: AnnouncementsView()) {
                        Label("Announcements", systemImage: "megaphone.fill")
                            .foregroundColor(.purple)
                    }
                    NavigationLink(destination: MyClassesView()) {
                        Label("My Classes", systemImage: "studentdesk")
                            .foregroundColor(.blue)
                    }
                    NavigationLink(destination: StudentProgressView()) {
                        Label("Student Progress", systemImage: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.green)
                    }
                }
                
                Section("Recent Awards") {
                    Text("No recent awards")
                        .foregroundColor(.secondary)
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
                            Text("Teacher")
                                .foregroundColor(.blue)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .navigationTitle("Teacher Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SettingsButton()
                }
            }
        }
    }
}
