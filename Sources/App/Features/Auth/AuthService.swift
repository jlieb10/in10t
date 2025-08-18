import Foundation
import AuthenticationServices
import GoogleSignIn
import Firebase
import FirebaseAuth

/// Service for handling authentication with multiple providers
@MainActor
class AuthService: ObservableObject {
    
    enum AuthError: LocalizedError {
        case appleSignInFailed
        case googleSignInFailed
        case emailSignInFailed
        case userCreationFailed
        case invalidCredentials
        
        var errorDescription: String? {
            switch self {
            case .appleSignInFailed:
                return "Apple sign in failed. Please try again."
            case .googleSignInFailed:
                return "Google sign in failed. Please try again."
            case .emailSignInFailed:
                return "Email sign in failed. Please check your credentials."
            case .userCreationFailed:
                return "Failed to create user account."
            case .invalidCredentials:
                return "Invalid credentials provided."
            }
        }
    }
    
    // MARK: - Apple Sign In
    
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) async throws -> UserProfile {
        guard let identityToken = credential.identityToken,
              let tokenString = String(data: identityToken, encoding: .utf8) else {
            throw AuthError.appleSignInFailed
        }
        
        let firebaseCredential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: tokenString,
            rawNonce: nil
        )
        
        let result = try await Auth.auth().signIn(with: firebaseCredential)
        
        return UserProfile(
            uid: result.user.uid,
            email: result.user.email ?? credential.email,
            displayName: result.user.displayName ?? [credential.fullName?.givenName, credential.fullName?.familyName].compactMap { $0 }.joined(separator: " "),
            creationDate: result.user.metadata.creationDate ?? Date(),
            lastSignIn: result.user.metadata.lastSignInDate ?? Date(),
            subscriptionStatus: .free
        )
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle(presentingViewController: UIViewController) async throws -> UserProfile {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.googleSignInFailed
        }
        
        // Configure Google Sign In
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        let user = result.user
        
        guard let idToken = user.idToken?.tokenString else {
            throw AuthError.googleSignInFailed
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: user.accessToken.tokenString
        )
        
        let authResult = try await Auth.auth().signIn(with: credential)
        
        return UserProfile(
            uid: authResult.user.uid,
            email: authResult.user.email,
            displayName: authResult.user.displayName,
            creationDate: authResult.user.metadata.creationDate ?? Date(),
            lastSignIn: authResult.user.metadata.lastSignInDate ?? Date(),
            subscriptionStatus: .free
        )
    }
    
    // MARK: - Email/Password Sign In
    
    func signInWithEmail(email: String, password: String) async throws -> UserProfile {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        
        return UserProfile(
            uid: result.user.uid,
            email: result.user.email,
            displayName: result.user.displayName,
            creationDate: result.user.metadata.creationDate ?? Date(),
            lastSignIn: result.user.metadata.lastSignInDate ?? Date(),
            subscriptionStatus: .free
        )
    }
    
    func createAccountWithEmail(email: String, password: String, displayName: String?) async throws -> UserProfile {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        
        // Update display name if provided
        if let displayName = displayName {
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
        }
        
        return UserProfile(
            uid: result.user.uid,
            email: result.user.email,
            displayName: displayName ?? result.user.displayName,
            creationDate: result.user.metadata.creationDate ?? Date(),
            lastSignIn: result.user.metadata.lastSignInDate ?? Date(),
            subscriptionStatus: .free
        )
    }
    
    // MARK: - Sign Out
    
    func signOut() async throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }
    
    // MARK: - Account Management
    
    func deleteAccount() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AuthError.invalidCredentials
        }
        
        try await user.delete()
    }
    
    func getCurrentUser() -> UserProfile? {
        guard let firebaseUser = Auth.auth().currentUser else { return nil }
        
        return UserProfile(
            uid: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: firebaseUser.displayName,
            creationDate: firebaseUser.metadata.creationDate ?? Date(),
            lastSignIn: firebaseUser.metadata.lastSignInDate ?? Date(),
            subscriptionStatus: .free // This would be loaded from user preferences
        )
    }
}