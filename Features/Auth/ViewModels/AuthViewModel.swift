import Foundation
import FirebaseAuth

enum AuthAlertState: Equatable {
    case idle
    case registrationSuccess
    case unverifiedAction
    case loginSuccess
    case passwordResetSent
    case error(String)
    
    var message: String {
        switch self {
        case .registrationSuccess: return "Account created! Please verify your email to unlock all features. Check your inbox."
        case .unverifiedAction: return "Please verify your email to unlock all features. Check your inbox."
        case .loginSuccess: return "Successfully logged in!"
        case .passwordResetSent: return "Password reset email sent."
        case .error(let message): return message
        case .idle: return ""
        }
    }
}

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var alertState: AuthAlertState = .idle
    @Published var showAlert = false
    @Published var isLoading = false
    
    @Published var resendCooldown: Int = 0
    private var timer: Timer?

    var canResend: Bool {
        resendCooldown <= 0
    }
    
    func register(email: String, password: String, name: String) {
        if let validationError = validatePasswordLocally(password) {
            self.alertState = .error(validationError)
            self.showAlert = true
            return
        }
        
        self.isLoading = true
        
        AuthService.shared.registerUser(email: email, password: password, name: name) { result in
            self.isLoading = false
            switch result {
            case .success:
                self.alertState = .registrationSuccess
                self.showAlert = true
            case .failure(let error):
                self.handleFirebaseError(error)
            }
        }
    }
    
    func signIn(email: String, password: String) {
        self.isLoading = true
        AuthService.shared.loginUser(email: email, password: password) { result in
            self.isLoading = false
            switch result {
            case .success:
                self.alertState = .loginSuccess
                self.showAlert = true
            case .failure(let error):
                self.handleFirebaseError(error)
            }
        }
    }
    
    func resetPassword(email: String) {
        guard !email.isEmpty else {
            self.alertState = .error("Please enter your email address.")
            self.showAlert = true
            return
        }
        
        self.isLoading = true
        AuthService.shared.sendPasswordReset(email: email) { result in
            self.isLoading = false
            switch result {
            case .success:
                self.alertState = .passwordResetSent
                self.showAlert = true
            case .failure(let error):
                self.handleFirebaseError(error)
            }
        }
    }
    
    func sendVerification() {
        if canResend {
            AuthService.shared.sendVerification { result in
                switch result {
                case .success:
                    self.startCooldown()
                    self.alertState = .unverifiedAction
                    self.showAlert = true
                case .failure(let error):
                    self.handleFirebaseError(error)
                }
            }
        } else {
            self.alertState = .unverifiedAction
            self.showAlert = true
        }
    }
    
    func signOut() {
        do {
            try AuthService.shared.signOut()
        } catch {
            self.alertState = .error(error.localizedDescription)
            self.showAlert = true
        }
    }
    
    private func startCooldown() {
        resendCooldown = 60
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                if let self = self {
                    if self.resendCooldown > 0 {
                        self.resendCooldown -= 1
                    } else {
                        self.timer?.invalidate()
                    }
                }
            }
        }
    }
    
    private func validatePasswordLocally(_ pass: String) -> String? {
        if pass.count < 10 { return "Password must be at least 10 characters." }
        if pass.rangeOfCharacter(from: .lowercaseLetters) == nil { return "Include a lowercase letter." }
        if pass.rangeOfCharacter(from: .uppercaseLetters) == nil { return "Include an uppercase letter." }
        if pass.rangeOfCharacter(from: .decimalDigits) == nil { return "Include at least one number." }
        return nil
    }
    
    private func handleFirebaseError(_ error: Error) {
        let nsError = error as NSError
        var errorMessage = error.localizedDescription
        
        if let code = AuthErrorCode(rawValue: nsError.code) {
            switch code {
            case .emailAlreadyInUse: // Note: Possible safety concern
                errorMessage = "This email is already registered. Try signing in instead."
            case .invalidEmail:
                errorMessage = "Invalid email address."
            case .weakPassword:
                errorMessage = "Password is too weak."
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            case .invalidCredential:
                errorMessage = "Wrong email or password."
            default:
                errorMessage = error.localizedDescription
            }
        }
        
        self.alertState = .error(errorMessage)
        self.showAlert = true
    }
}

