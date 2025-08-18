import SwiftUI

struct EmailSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var isCreatingAccount = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text(isCreatingAccount ? "Create Account" : "Sign In")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(isCreatingAccount ? "Join Intentional today" : "Welcome back")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 32)
                
                Spacer()
                
                // Form fields
                VStack(spacing: 16) {
                    if isCreatingAccount {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Display Name")
                                .font(.headline)
                            TextField("Your name", text: $displayName)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.name)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email")
                            .font(.headline)
                        TextField("your@email.com", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.headline)
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(isCreatingAccount ? .newPassword : .password)
                    }
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: handlePrimaryAction) {
                        Group {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isCreatingAccount ? "Create Account" : "Sign In")
                                    .fontWeight(.medium)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .disabled(!isFormValid || isLoading)
                    
                    Button(action: { isCreatingAccount.toggle() }) {
                        HStack {
                            Text(isCreatingAccount ? "Already have an account?" : "Don't have an account?")
                                .foregroundColor(.secondary)
                            Text(isCreatingAccount ? "Sign In" : "Create Account")
                                .fontWeight(.medium)
                        }
                    }
                    .disabled(isLoading)
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && 
        !password.isEmpty && 
        password.count >= 6 && 
        (!isCreatingAccount || !displayName.isEmpty)
    }
    
    private func handlePrimaryAction() {
        errorMessage = nil
        isLoading = true
        
        Task {
            do {
                let profile: UserProfile
                
                if isCreatingAccount {
                    profile = try await appState.authService.createAccountWithEmail(
                        email: email,
                        password: password,
                        displayName: displayName.isEmpty ? nil : displayName
                    )
                } else {
                    profile = try await appState.authService.signInWithEmail(
                        email: email,
                        password: password
                    )
                }
                
                await MainActor.run {
                    appState.authState.signIn(with: profile)
                    isLoading = false
                    dismiss()
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