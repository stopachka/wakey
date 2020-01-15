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
// Model

struct LoggedInUser : Equatable {
    var uid: String
    var photoURL: URL?
    var displayName: String?
}

struct WakeyUser {
    var uid: String
    var displayName: String
}

// --------------
// UserInfoStore

class UserInfoStore: ObservableObject {
    @Published var users: [WakeyUser] = []
    
    init() {
        Firestore.firestore().collection("userInfos")
            .addSnapshotListener { collectionSnapshot, error in
                guard let collection = collectionSnapshot else {
                    print("Error fetching collection: \(error!)")
                    return
                }
                let wakeyUsers = collection.documents.map {
                    // TODO: Improve coeriscon, see if we can coerce firebase documents into
                    // structs
                    return WakeyUser(
                        uid: $0["uid"]! as! String,
                        displayName: $0["displayName"]! as! String
                    )
                }
                self.users = wakeyUsers
                print("Current data: \(wakeyUsers)")
        }
    }

    static func onSignIn(loggedInUser: LoggedInUser) {
        let db = Firestore.firestore()
        db.collection("userInfos").document(loggedInUser.uid).setData([
            "uid": loggedInUser.uid,
            "displayName": loggedInUser.displayName as Any,
        ], merge: true)
        print("Saved \(loggedInUser.uid) to db")
    }
}

// --------------
// SessionStore

/**
 SessionStore keeps track of the logged in user, and acts as a facade for Firebase Auth APIs
 We subscribe to Firebase's Auth state changes, and update logged in user accordingly
 The work for  FB signin is handled in `FBLoginContainer`
 
 TODO: Think about whether we want to use this pattern of stores for managing daata
 */
class SessionStore : ObservableObject {
    @Published var loggedInUser: LoggedInUser?
    @Published var isLoading: Bool = true
    var handle: AuthStateDidChangeListenerHandle?

    init() {
        handle = Auth.auth().addStateDidChangeListener { (auth, fireUser) in
            guard let fireUser = fireUser else {
                self.loggedInUser = nil
                self.isLoading = false
                return
            }
            let loggedInUser = LoggedInUser(
                uid: fireUser.uid,
                photoURL: fireUser.photoURL,
                displayName: fireUser.displayName
            )
            self.loggedInUser = loggedInUser
            UserInfoStore.onSignIn(loggedInUser: loggedInUser)
            self.isLoading = false
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
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
