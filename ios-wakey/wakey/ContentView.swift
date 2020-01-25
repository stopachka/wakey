import SwiftUI
import Firebase
import FBSDKLoginKit

//----
// Data

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
    @State var isLoadingUserInfo : Bool = true
    @State var error : String?
    @State var loggedInUserUID : String?
    @State var allUsers : [User] = []
    
    // TODO(stopachka)
    // Would be good to make sure that this only loads once
    func connect() {
        /**
         Connect to Firebase's Login State
         */
        Auth.auth().addStateDidChangeListener { (auth, fireUser) in
            guard let fireUser = fireUser else {
                self.loggedInUserUID = nil
                self.isLoggingIn = false
                return
            }
            let user = User(
                uid: fireUser.uid,
                photoURL: fireUser.photoURL,
                displayName: fireUser.displayName
            )
            self.loggedInUserUID = user.uid
            self.isLoggingIn = false
            
            // Make sure that this user is _also_ stored in `userInfo`
            updateUserInfo(user: user)
        }
        
        /**
         Connect into Firebase's "userInfo" state
         This is where we get all user data
         */
        Firestore.firestore().collection("userInfos")
            .addSnapshotListener { collectionSnapshot, error in
                guard let collection = collectionSnapshot else {
                    self.error = "Uh oh, we weren't able to find your friends."
                    print("Error fetching collection: \(error!)")
                    return
                }
                let users = collection.documents.map(documentToUser)
                self.allUsers = users
                self.isLoadingUserInfo = false
        }
    }
    
    func handleSignInWithFacebook(accessToken: AccessToken) {
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
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
        return MainView(
            isLoggingIn: isLoggingIn,
            isLoadingUserInfo: isLoadingUserInfo,
            loggedInUserUID: loggedInUserUID,
            allUsers: allUsers,
            error: error,
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
