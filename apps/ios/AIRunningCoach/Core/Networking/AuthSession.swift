import Foundation

protocol AuthSessioning: AnyObject, Sendable {
    var accessToken: String? { get set }
}

final class InMemoryAuthSession: AuthSessioning, @unchecked Sendable {
    var accessToken: String?

    init(accessToken: String? = nil) {
        self.accessToken = accessToken
    }
}
