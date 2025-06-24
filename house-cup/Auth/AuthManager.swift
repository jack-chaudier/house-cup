//
//  AuthManager.swift
//  house-cup
//
//  Created by Jack Gaffney on 6/22/25.
//


import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import GoogleSignIn

@MainActor
final class AuthManager: ObservableObject {
    @Published var currentUser: AppUser?
    @Published var isLoading = false
    @Published var authState: AuthState = .signedOut
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    
    enum AuthState {
        case signedIn
        case signedOut
        case loading
    }
    
    enum AuthError: Error {
        case missingClientID
        case missingRootVC
        case missingToken
        case userDataNotFound
    }
    
    private let db = Firestore.firestore()
    
    init() {
        // Listen to auth state changes
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.authState = .loading
                    await self?.fetchUserData(user)
                } else {
                    self?.currentUser = nil
                    self?.authState = .signedOut
                }
            }
        }
    }
    
    deinit {
        // Remove the listener when AuthManager is deallocated
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    func signIn() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.missingClientID
        }
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        
        guard let rootVC = UIApplication.shared.firstKeyWindow?.rootViewController else {
            throw AuthError.missingRootVC
        }
        
        let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = signInResult.user.idToken?.tokenString else {
            throw AuthError.missingToken
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: signInResult.user.accessToken.tokenString
        )
        
        let authResult = try await Auth.auth().signIn(with: credential)
        await createOrUpdateUser(authResult.user)
    }
    
    private func createOrUpdateUser(_ user: User) async {
        let userRef = db.collection("users").document(user.uid)
        
        do {
            let document = try await userRef.getDocument()
            
            if document.exists {
                // User exists, just fetch the data
                await fetchUserData(user)
            } else {
                // New user, create with default role
                let userData: [String: Any] = [
                    "uid": user.uid,
                    "email": user.email ?? "",
                    "displayName": user.displayName ?? "",
                    "photoURL": user.photoURL?.absoluteString ?? "",
                    "userType": UserType.none.rawValue,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                
                try await userRef.setData(userData)
                await fetchUserData(user)
            }
        } catch {
            print("Error creating/updating user: \(error)")
        }
    }
    
    private func fetchUserData(_ user: User) async {
        do {
            let document = try await db.collection("users").document(user.uid).getDocument()
            
            guard let data = document.data() else {
                throw AuthError.userDataNotFound
            }
            
            let userTypeString = data["userType"] as? String ?? UserType.none.rawValue
            let userType = UserType(rawValue: userTypeString) ?? .none
            
            currentUser = AppUser(
                uid: user.uid,
                email: user.email,
                displayName: user.displayName,
                userType: userType,
                photoURL: data["photoURL"] as? String,
                houseId: data["houseId"] as? String
            )
            
            authState = .signedIn
        } catch {
            print("Error fetching user data: \(error)")
            authState = .signedOut
        }
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
        currentUser = nil
        authState = .signedOut
    }
}
