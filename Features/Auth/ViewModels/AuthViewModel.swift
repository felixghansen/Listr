import Foundation
import FirebaseAuth

enum AuthAlertState {
    case idle
    case registrationSuccess
    case loginSuccess
    case passwordResetSent
    case error(String)
    
    var message: String {
        switch self {
        case .registrationSuccess: return "Account created! Please verify your email before signing in."
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
                try? AuthService.shared.signOut()
                
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
    
    func signOut() {
        do {
            try AuthService.shared.signOut()
        } catch {
            self.alertState = .error(error.localizedDescription)
            self.showAlert = true
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
            case .emailAlreadyInUse:
                errorMessage = "This email is already registered. Try signing in instead."
            case .invalidEmail:
                errorMessage = "Invalid email address."
            case .weakPassword:
                errorMessage = "That password is too easy to guess."
            case .networkError:
                errorMessage = "Network error. Please check your connection."
            case .invalidCredential:
                errorMessage = "Wrong email or password. Please try again."
            default:
                errorMessage = error.localizedDescription
            }
        }
        
        self.alertState = .error(errorMessage)
        self.showAlert = true
    }
}

