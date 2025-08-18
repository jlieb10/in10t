import SwiftUI
import AuthenticationServices
import GoogleSignIn
import Firebase
import FirebaseAuth

struct AuthenticationView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingEmailSignIn = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Logo and title
                VStack(spacing: 16) {
                    Image(systemName: "hourglass.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("Intentional")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Make screen time intentional")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Sign in options
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: handleAppleSignIn
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .cornerRadius(8)
                    
                    // Google Sign In
                    Button(action: signInWithGoogle) {
                        HStack {
                            Image(systemName: "globe")
                                .resizable()
                                .frame(width: 20, height: 20)
                            Text("Continue with Google")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(.systemBackground))
                        .foregroundColor(.primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                    }
                    
                    // Email Sign In
                    Button(action: { showingEmailSignIn = true }) {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Continue with Email")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
                .disabled(isLoading)
                .opacity(isLoading ? 0.6 : 1)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Terms and Privacy
                VStack(spacing: 8) {
                    Text("By continuing, you agree to our")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Button("Terms of Service") {
                            // Open terms
                        }
                        .font(.caption)
                        
                        Text("and")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Privacy Policy") {
                            // Open privacy policy
                        }
                        .font(.caption)
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
        .sheet(isPresented: $showingEmailSignIn) {
            EmailSignInView()
        }
    }
    
    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            signInWithApple(authorization)
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
    
    private func signInWithApple(_ authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            errorMessage = "Failed to get Apple ID credential"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let profile = try await appState.authService.signInWithApple(
                    credential: appleIDCredential
                )
                
                await MainActor.run {
                    appState.authState.signIn(with: profile)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
    
    private func signInWithGoogle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Failed to get root view controller"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let profile = try await appState.authService.signInWithGoogle(
                    presentingViewController: rootViewController
                )
                
                await MainActor.run {
                    appState.authState.signIn(with: profile)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}