import SwiftUI
import Firebase
import Combine

// --------------
// Models

struct User {
    var uid: String
}

// --------------
// Stores

/**
 SessionStore keeps track of the logged in user
 We subscribe to Firebase's Auth state changes, and update logged in user accordingly
 */
class SessionStore : ObservableObject {
    var didChange = PassthroughSubject<SessionStore, Never>()
    @Published var loggedInUser: User? { didSet { self.didChange.send(self) }}
    var handle: AuthStateDidChangeListenerHandle?

    func listen() {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                print(user)
                self.loggedInUser = User(
                    uid: user.uid
                )
            } else {
                self.loggedInUser = nil
            }
        }
    }
}
