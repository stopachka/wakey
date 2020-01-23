import SwiftUI
import Firebase
import FBSDKLoginKit

//----
// Data

// TODO(stopachka)
// Sharing `User` for both loggedInUser, and the data from `userInfo`
// At some point, i.e if we include "wakeups", and enforce them as non-nullable,
// We may want to structure things differently
// For example:
//   We could only keep the `loggedInUserId` as the state
//   Then have the source of truth come from `userInfos`
// Avoiding this refactor for now
struct User {
    let uid: String
    var photoURL: URL?
    var displayName: String?
}

struct WakeyAlarm {
    var hour: Int
    var minute: Int
    // TODO(stopacka)
    // We could have `repeatDays`, `snoozeConfig`, etc
}


//----
// Data Transformations

func coerceToURL(input : Any?) -> URL? {
    guard let str = input as? String else {
        return nil
    }
    return URL(string: str)
}

// TODO(stopachka)
// What if this throws?
// How will we parse more complicated structures?
func documentToUser(document : DocumentSnapshot) -> User {
    return User(
        uid: document["uid"] as! String,
        photoURL: coerceToURL(input: document["photoURL"]),
        displayName: document["displayName"] as? String
    );
}

//----
// DB Helpers

func updateUserInfo(user : User) {
    let db = Firestore.firestore()
    db.collection("userInfos").document(user.uid).setData([
        "uid": user.uid,
        "displayName": user.displayName as Any,
        "photoURL": user.photoURL?.absoluteString as Any
    ], merge: true)
    print("Saved \(user.uid) to db")
}

//----
// ContentView

struct ContentView : View {
    @State var isLoggingIn : Bool = true
    @State var error : String?
    @State var loggedInUser : User?
    @State var allUsers : [User] = []
    
    // TODO(stopachka)
    // Would be good to make sure that this only loads once
    func connect() {
        /**
         Connect to Firebase's Login State
         */
        Auth.auth().addStateDidChangeListener { (auth, fireUser) in
            guard let fireUser = fireUser else {
                self.loggedInUser = nil
                self.isLoggingIn = false
                return
            }
            let loggedInUser = User(
                uid: fireUser.uid,
                photoURL: fireUser.photoURL,
                displayName: fireUser.displayName
            )
            self.loggedInUser = loggedInUser
            self.isLoggingIn = false
            
            // Make sure that this user is _also_ stored in `userInfo`
            updateUserInfo(user: loggedInUser)
        }
        
        /**
         Connect into Firebase's "userInfo" state
         */
        Firestore.firestore().collection("userInfos")
            .addSnapshotListener { collectionSnapshot, error in
                guard let collection = collectionSnapshot else {
                    self.error = "Uh oh, we weren't able to find your friends."
                    print("Error fetching collection: \(error!)")
                    return
                }
                let users = collection.documents.map(documentToUser)
                print("allUsers: \(users)")
                self.allUsers = users
        }
    }
    
    func handleSignInWithFacebook(accessToken: AccessToken) {
        let credential =    FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
        self.isLoggingIn = true
        // Auth.auth().signIn will trigger
        // Auth.auth().addStateDidChangeListener
        // which will then turn isLoggingIn to false
        Auth.auth().signIn(with: credential)
    }
    
    func handleSignOut() {
        do {
            LoginManager().logOut()
            try Auth.auth().signOut()
        } catch {
            self.error = "Oi. we failed to log out"
            print("failed to log out")
        }
    }
    
    var body: some View {
        MainView(
            isLoggingIn: isLoggingIn,
            error: error,
            loggedInUser: loggedInUser,
            allUsers: allUsers,
            handleError: { err in self.error = err },
            handleSignInWithFacebook: { self.handleSignInWithFacebook(accessToken: $0) },
            handleSignOut: handleSignOut
        ).onAppear(perform: connect)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
