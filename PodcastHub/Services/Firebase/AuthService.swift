import FirebaseAuth
import Foundation

protocol AuthServiceType {
    var currentUser: User? { get }
    var isAuthenticated: Bool { get }

    func signInAnonymously() async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signUp(email: String, password: String) async throws -> User
    func signOut() throws
    func addStateDidChangeListener(_ listener: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle
    func removeStateDidChangeListener(_ handle: AuthStateDidChangeListenerHandle)
}

final class AuthService: AuthServiceType {
    private let auth = Auth.auth()

    var currentUser: User? {
        auth.currentUser
    }

    var isAuthenticated: Bool {
        auth.currentUser != nil
    }

    func signInAnonymously() async throws -> User {
        let result = try await auth.signInAnonymously()
        return result.user
    }

    func signIn(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return result.user
    }

    func signUp(email: String, password: String) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        return result.user
    }

    func signOut() throws {
        try auth.signOut()
    }

    func addStateDidChangeListener(_ listener: @escaping (User?) -> Void)
        -> AuthStateDidChangeListenerHandle
    {
        auth.addStateDidChangeListener { _, user in
            listener(user)
        }
    }

    func removeStateDidChangeListener(_ handle: AuthStateDidChangeListenerHandle) {
        auth.removeStateDidChangeListener(handle)
    }
}
