import SwiftUI
import Firebase
import Combine
import FBSDKLoginKit

// --------------
// AppDelegae

/*
 This is all the work that needs to happen to initializse auth. Runs in `AppDelegate`
 */
struct AuthInitializers {
    static func didFinishLaunchingWithOptions(application: UIApplication, launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        return ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    static func open(application: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return ApplicationDelegate.shared.application(application, open: url, options: options)
    }
}


// --------------
// SessionStore

struct LoggedInUser : Equatable {
    var uid: String
    var photoURL: URL?
}

/**
 SessionStore keeps track of the logged in user, and acts as a facade for Firebase Auth APIs
 We subscribe to Firebase's Auth state changes, and update logged in user accordingly
 The work for  FB signin is handled in `FBLoginContainer`
 */
class SessionStore : ObservableObject {
    var didChange = PassthroughSubject<SessionStore, Never>()
    @Published var loggedInUser: LoggedInUser? { didSet { self.didChange.send(self) }}
    var handle: AuthStateDidChangeListenerHandle?

    func listen() {
        handle = Auth.auth().addStateDidChangeListener { (auth, user) in
            guard let loggedInUser = user else {
                self.loggedInUser = nil
                return
            }
            self.loggedInUser = LoggedInUser(
                uid: loggedInUser.uid,
                photoURL: loggedInUser.photoURL
            )
        }
    }
    
    static func signInWithFacebook(accessToken : AccessToken) {
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
        Auth.auth().signIn(with: credential)
    }
    
    static func signOut() {
        try! Auth.auth().signOut()
    }
}

// --------------
// FB

/**
 Wraps FB's FBLoginButton into a `UIViewRepresentable`.
 This lets us embed this into SwiftUI components
 Also handles the glue into Firebase
 */
struct FBLoginContainer: UIViewRepresentable {
    func makeCoordinator() -> FBLoginContainer.Coordinator {
        return FBLoginContainer.Coordinator()
    }

    func makeUIView(context: UIViewRepresentableContext<FBLoginContainer>) -> FBLoginButton {
        let loginButton = FBLoginButton()
        loginButton.delegate = context.coordinator

        return loginButton
    }

    // Needed to conform to UIViewRepresentable's protocol, but not used
    func updateUIView(_ uiView: FBLoginButton, context: UIViewRepresentableContext<FBLoginContainer>) {}

    class Coordinator : NSObject, LoginButtonDelegate {
        func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let currentAccessToken = AccessToken.current else {
                print("uh oh, no access token")
                return
            }
            SessionStore.signInWithFacebook(accessToken: currentAccessToken)
        }

        func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
            SessionStore.signOut()
        }
    }
}
