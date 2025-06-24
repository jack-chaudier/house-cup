//
//  SignInView.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//

import SwiftUI
import GoogleSignInSwift

struct SignInView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                
                Text("House Cup")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to continue")
                    .foregroundColor(.secondary)
            }
            
            GoogleSignInButton {
                Task {
                    do {
                        try await authManager.signIn()
                    } catch {
                        errorMessage = error.localizedDescription
                        showError = true
                    }
                }
            }
            .frame(maxWidth: 280, maxHeight: 48)
            .disabled(authManager.isLoading)
            
            if authManager.isLoading {
                ProgressView()
            }
        }
        .padding()
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}
