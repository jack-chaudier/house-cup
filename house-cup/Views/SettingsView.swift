//
//  SettingsView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @StateObject private var themeManager = ThemeManager()
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle("Use System Theme", isOn: $themeManager.useSystemTheme)
                    
                    if !themeManager.useSystemTheme {
                        Toggle("Dark Mode", isOn: $themeManager.isDarkMode)
                    }
                    
                    if let user = authManager.currentUser,
                       user.userType == .student {
                        Toggle("Use House Color as Accent", isOn: .constant(true))
                            .disabled(true)
                        
                        Text("Your house color will be used as the accent color in light mode")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Account") {
                    if let user = authManager.currentUser {
                        LabeledContent("Name", value: user.displayName ?? "")
                        LabeledContent("Email", value: user.email ?? "")
                        LabeledContent("Role", value: user.userType.displayName)
                        
                        if user.userType == .student {
                            NavigationLink("Edit Profile", destination: StudentProfileView())
                        }
                    }
                }
                
                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    
                    Link(destination: URL(string: "https://github.com/yourusername/house-cup")!) {
                        HStack {
                            Text("View on GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button("Sign Out") {
                        showingSignOutAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    try? authManager.signOut()
                    dismiss()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
        .preferredColorScheme(themeManager.effectiveColorScheme)
    }
}

// Settings button to add to navigation bars
struct SettingsButton: View {
    @State private var showingSettings = false
    
    var body: some View {
        Button(action: { showingSettings = true }) {
            Image(systemName: "gearshape")
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}