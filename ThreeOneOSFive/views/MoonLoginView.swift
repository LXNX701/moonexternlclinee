import SwiftUI

struct MoonLoginView: View {
    @StateObject private var auth = MoonAuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSignUp = false
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.black, Color(red: 0.08, green: 0.0, blue: 0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Spacer().frame(height: 60)
                    
                    Image(uiImage: UIImage(named: "ExternalIcon") ?? UIImage(systemName: "sparkles")!)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .blue.opacity(0.5), radius: 15)
                    
                    Text("MOON PLACE")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.white, .blue], startPoint: .leading, endPoint: .trailing)
                        )
                    
                    Text(isSignUp ? "Create Account" : "Sign In")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    VStack(spacing: 16) {
                        if isSignUp {
                            MoonTextField(title: "Username", text: $username, icon: "person.fill")
                        }
                        MoonTextField(title: "Email", text: $email, icon: "envelope.fill")
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        MoonSecureField(title: "Password", text: $password, icon: "lock.fill")
                    }
                    .padding(.horizontal, 24)
                    
                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal, 24)
                    }
                    
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                if isSignUp {
                                    await auth.signUp(email: email, password: password, username: username)
                                } else {
                                    await auth.signIn(email: email, password: password)
                                }
                                if auth.isAuthenticated {
                                    isAuthenticated = true
                                }
                            }
                        } label: {
                            HStack {
                                if auth.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(isSignUp ? "REGISTER" : "LOGIN")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                        .tracking(2)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .disabled(auth.isLoading || email.isEmpty || password.isEmpty)
                        .padding(.horizontal, 24)
                        
                        Button {
                            withAnimation {
                                isSignUp.toggle()
                                auth.errorMessage = nil
                            }
                        } label: {
                            Text(isSignUp ? "Already have account? Sign In" : "New user? Register")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.blue)
                        }
                        
                        Button {
                            Task {
                                await auth.signInAnonymously()
                                if auth.isAuthenticated {
                                    isAuthenticated = true
                                }
                            }
                        } label: {
                            Text("Continue as Guest")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    
                    Spacer().frame(height: 40)
                }
            }
        }
    }
}