import SwiftUI
import Firebase
import FBSDKLoginKit
import AVFoundation

//----
// Data


struct WakeyAlarm {
    var hour: Int
    var minute: Int
    // TODO(stopacka)
    // We could have `repeatDays`, `snoozeConfig`, etc
}

struct User {
    let uid: String
    var photoURL: URL?
    var displayName: String?
    var alarm: WakeyAlarm?
}

//----
// Data Transformations

func coerceToWakeyAlarm(input : Any? ) -> WakeyAlarm? {
    guard let input = input else {
        return nil
    }
    let dict = input as! [String:Int]
    return WakeyAlarm(
        hour: dict["hour"]!,
        minute: dict["minute"]!
    )
}

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
        displayName: document["displayName"] as? String,
        alarm: coerceToWakeyAlarm(input: document["alarm"])
    )
}

//----
// DB Helpers

func saveFireUserInfo(uid: String, displayName: String?, photoURL: URL?) {
    let db = Firestore.firestore()
    db.collection("userInfos").document(uid).setData([
        "uid": uid,
        "displayName": displayName as Any,
        "photoURL": photoURL?.absoluteString as Any
    ], merge: true)
    print("Saved \(uid) to db")
}

func saveAlarm(loggedInUserUID: String, alarm: WakeyAlarm) {
    let db = Firestore.firestore()
    db.collection("userInfos").document(loggedInUserUID).setData([
        "alarm": [
            "hour": alarm.hour,
            "minute": alarm.minute
        ]
    ], merge: true)
    print("Saved \(loggedInUserUID)'s alarm to db")
}

//----
// MainViewContainer

struct MainViewContainer : View {
    @State var isLoggingIn : Bool = true
    @State var authorizationStatus : UNAuthorizationStatus?
    @State var error : String?
    @State var loggedInUserUID : String?
    @State var allUsers : [User] = []
    @State var audioPlayer: AVAudioPlayer?
    @State var handledWakeupMap: [String: Bool] = [String: Bool]()
    
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
            let uid = fireUser.uid
            self.loggedInUserUID = uid
            self.isLoggingIn = false
            
            // Make sure that this user is _also_ stored in `userInfo`
            saveFireUserInfo(uid: uid, displayName: fireUser.displayName, photoURL: fireUser.photoURL)
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
        }
        
        getAuthorizationStatus()
        
        configureAVAudioSession()
        
        self.playSilentAudio()
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { _ in
            guard let wakeupDate = self.getNextWakeupDate() else {
                print("Could not get next wake up")
                return
            }
            
            if !self.inRange(wakeupDate: wakeupDate) {
                print("wakeupDate not in range")
                print(wakeupDate.description)
                return
            }
            
            if self.hasHandledWakeup(wakeupDate: wakeupDate) {
                print("wakeUpDate: \(wakeupDate.description) already handled")
                return
            }
            
            self.updateWakeupMap(wakeupDate: wakeupDate)
            self.playAlarmAudio()
        })
        
    }
    
    func getAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            /**
             This is the top-level status.
             In the future, we can store more granular info, like "alert", "sound", settings etc
             This will be useful in dealing with a situation like:
                The user manually disabled sound or something
             */
            print(settings)
            self.authorizationStatus = settings.authorizationStatus
        })
    }
    
    // (TODO) Consider moving this into a utils file
    func currentUser() -> User? {
        guard let loggedInUserUID = loggedInUserUID else {
            return nil
        }
        
        let (user, _) = splitIntoLoggedInUserAndFriends(allUsers: self.allUsers, loggedInUserUID: loggedInUserUID)
        return user
    }
    
    //----
    // Wake-up Helpers
    
    func inRange(wakeupDate: Date) -> Bool {
        print("Difference in seconds \(wakeupDate.timeIntervalSinceNow.description)")
        return abs(wakeupDate.timeIntervalSinceNow) <= 30
    }
    
    func hasHandledWakeup(wakeupDate: Date) -> Bool {
        return self.handledWakeupMap[wakeupDate.description] ?? false
    }
    
    func getNextWakeupDate() -> Date? {
        guard let user = currentUser() else {
            return nil
        }
        
        guard let wakeyAlarm = user.alarm else {
            return nil
        }
        
        let now = Date()
        let oneMinuteAgo = Calendar.current.date(byAdding: .minute, value: -1, to: now)!
        print("One minute ago: \(oneMinuteAgo.description)")
        return wakeyAlarmToNextDate(wakeyAlarm: wakeyAlarm, baseDate: oneMinuteAgo)
    }
    
    func updateWakeupMap(wakeupDate: Date) {
        self.handledWakeupMap[wakeupDate.description] = true
    }
    
    //----
    // Audio Helpers
    func configureAVAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch let error as NSError {
            self.error = "Uh-oh. Could not set up audio player!"
            print(error.localizedDescription)
        }
    }
    
    func playSilentAudio() {
        let path = Bundle.main.path(forResource: "silent", ofType: "mp3")!
        playPath(path: path)
    }
    
    func playAlarmAudio() {
        let path = Bundle.main.path(forResource: "tickle", ofType: "mp3")!
        playPath(path: path)
    }
    
    func playPath(path: String) {
        if let oldAudioPlayer = self.audioPlayer {
            oldAudioPlayer.stop()
        }

        let url = URL(fileURLWithPath: path)
        print("In  starting to play, path: ", path)
        do {
            print("Setting up silent")
            let newAudioPlayer = try AVAudioPlayer(contentsOf: url)
            newAudioPlayer.prepareToPlay()
            newAudioPlayer.numberOfLoops = -1
            newAudioPlayer.play()
            self.audioPlayer = newAudioPlayer
        } catch let error as NSError {
            // File could not load
            self.error = "Uh-oh. Could not play sounds"
            print(error.localizedDescription)
        }
    }
    
    //----
    // Auth Helpers
    func handleRequestNotificationAuth() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound]) { _,_ in self.getAuthorizationStatus()
        }
    }
    
    func handleSignInWithFacebook(accessToken: AccessToken) {
        let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
        self.isLoggingIn = true
        // Auth.auth().signIn will trigger Auth.auth().addStateDidChangeListener
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
    
    func handleSaveAlarm(alarm: WakeyAlarm) {
        saveAlarm(
            // TODO(stopachka)
            // Unhappy that I have to force the uid here
            // Could have handleSaveAlarm pass it in, but that feels more off
            loggedInUserUID: loggedInUserUID!,
            alarm: alarm
        )
    }
    
    var body: some View {
        return MainView(
            isLoggingIn: isLoggingIn,
            authorizationStatus: authorizationStatus,
            loggedInUserUID: loggedInUserUID,
            allUsers: allUsers,
            error: error,
            handleError: { err in self.error = err },
            handleRequestNotificationAuth: self.handleRequestNotificationAuth,
            handleSignInWithFacebook: { self.handleSignInWithFacebook(accessToken: $0) },
            handleSignOut: handleSignOut,
            handleSaveAlarm: { self.handleSaveAlarm(alarm: $0) }
        )
            .onAppear(perform: connect)
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.willEnterForegroundNotification
                ),
                perform: { _ in self.getAuthorizationStatus() }
            )
    }
}

struct MainViewContainer_Previews: PreviewProvider {
    static var previews: some View {
        MainViewContainer()
    }
}
