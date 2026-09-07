import Foundation
import FirebaseAuth
import FirebaseCore

// MARK: - Firebase Configuration
enum FirebaseConfig {
    static var isConfigured: Bool {
        FirebaseApp.app() != nil
    }
}

// MARK: - Auth State
struct MoonAuthState {
    let uid: String
    let email: String?
    let displayName: String?
    let isAnonymous: Bool
    let licenseKey: String?
    let expiresAt: Date?
    
    var isLicenseActive: Bool {
        guard let expires = expiresAt else { return true }
        return expires > Date()
    }
    
    var daysRemaining: Int {
        guard let expires = expiresAt else { return -1 }
        let seconds = expires.timeIntervalSinceNow
        return max(0, Int(seconds / 86400))
    }
}

// MARK: - Moon Place Auth Manager
@MainActor
final class MoonAuthManager: ObservableObject {
    @Published var currentUser: MoonAuthState?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var needsLicenseActivation = false
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    
    static let shared = MoonAuthManager()
    
    private init() {
        setupAuthListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthListener() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                if let user = user {
                    self?.currentUser = MoonAuthState(
                        uid: user.uid,
                        email: user.email,
                        displayName: user.displayName,
                        isAnonymous: user.isAnonymous,
                        licenseKey: nil,
                        expiresAt: nil
                    )
                    self?.isAuthenticated = true
                } else {
                    self?.currentUser = nil
                    self?.isAuthenticated = false
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = MoonAuthState(
                uid: result.user.uid,
                email: result.user.email,
                displayName: result.user.displayName,
                isAnonymous: false,
                licenseKey: nil,
                expiresAt: nil
            )
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signUp(email: String, password: String, username: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = username
            try await changeRequest.commitChanges()
            
            currentUser = MoonAuthState(
                uid: result.user.uid,
                email: result.user.email,
                displayName: username,
                isAnonymous: false,
                licenseKey: nil,
                expiresAt: nil
            )
            isAuthenticated = true
            needsLicenseActivation = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signInAnonymously() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await Auth.auth().signInAnonymously()
            currentUser = MoonAuthState(
                uid: result.user.uid,
                email: nil,
                displayName: "Guest",
                isAnonymous: true,
                licenseKey: nil,
                expiresAt: nil
            )
            isAuthenticated = true
            needsLicenseActivation = true
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            currentUser = nil
            isAuthenticated = false
            needsLicenseActivation = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func activateLicense(key: String) async -> Bool {
        isLoading = true
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        let isValidFormat = key.hasPrefix("MOON-") && key.count >= 19
        
        if isValidFormat, var user = currentUser {
            currentUser = MoonAuthState(
                uid: user.uid,
                email: user.email,
                displayName: user.displayName,
                isAnonymous: user.isAnonymous,
                licenseKey: key,
                expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: Date())
            )
            needsLicenseActivation = false
            isLoading = false
            return true
        }
        
        errorMessage = "Invalid license key"
        isLoading = false
        return false
    }
}