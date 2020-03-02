import SwiftUI
import Firebase
import FBSDKLoginKit
import AVFoundation
import MediaPlayer

//----
// Data


struct WakeupAck {
    var date: Date
    var photoUrl: String?
}

struct Wakeup {
    var alarmDate: Date
    var ack: WakeupAck?
}

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
    var wakeups: [Wakeup]
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

func coerceToURL(input: Any?) -> URL? {
    guard let str = input as? String else {
        return nil
    }
    return URL(string: str)
}

func parseDate(isoString: String) -> Date {
    let dateFormatter = ISO8601DateFormatter()
    let date = dateFormatter.date(from: isoString)
    return date!
}

func formatDate(date: Date) -> String {
    let dateFormatter = ISO8601DateFormatter()
    return dateFormatter.string(from: date)
}

func coerceAck(input: Any?) -> WakeupAck? {
    guard let ackMap = input as? [String: Any] else {
        return nil
    }
    return WakeupAck(
        date: parseDate(isoString: ackMap["date"] as! String)
    )
}

// TODO(stopachka)
// What if this throws?
// How will we parse more complicated structures?

func documentToWakeup(document : DocumentSnapshot) -> (String, Wakeup) {
    let date = parseDate(isoString: document["alarmDate"] as! String)
    return (
        document["userUID"] as! String,
        Wakeup(
            alarmDate: date,
            ack: coerceAck(input: document["ack"])
        )
    )
}

func documentToUserWithoutWakeups(document : DocumentSnapshot) -> User {
    return User(
        uid: document["uid"] as! String,
        photoURL: coerceToURL(input: document["photoURL"]),
        displayName: document["displayName"] as? String,
        alarm: coerceToWakeyAlarm(input: document["alarm"]),
        wakeups: []
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

/**
    TODO: research into how subcollections work
    Right now we treat wakeups as a different
 */
func saveWakeup(loggedInUserUID: String, wakeup: Wakeup) {
    let formattedAlarmDate = formatDate(date: wakeup.alarmDate)
    let db = Firestore.firestore()
    let ack = wakeup.ack
    let doc = db
        .collection("wakeups")
        .document("\(loggedInUserUID)-\(formattedAlarmDate)")
    doc.setData([
        "userUID": loggedInUserUID,
        "alarmDate": formattedAlarmDate,
    ], merge: true)
    if let ack = ack {
        doc.setData(
            ["ack": ["date": formatDate(date: ack.date), "photoUrl": ack.photoUrl]],
            merge: true
        )
    }
    print("Saved \(loggedInUserUID)'s wakeup to db")
}

/**
 */
let TRIGGER_ALARM_NOTIF_DELAY_SECS = 1.0
let TRIGGER_SOUND_DELAY_SECS = 1.0
let RENDER_VOLUME_PICKER_DELAY_SECS = 1.0

/**
 This view enables us to force set the vollume, we use this for when an alarm goes off
 to ensure the alarm sound plays
 */
struct ForceVolume: UIViewRepresentable {
    var level : Float?
    var handleComplete: () -> Void
    
    func makeUIView(context: Context) -> MPVolumeView {
        let volumeView = MPVolumeView()
        volumeView.showsVolumeSlider = false
        return volumeView
    }

    func updateUIView(_ view: MPVolumeView, context: Context) {
        print("Rendered MPVolumeView")
        guard let level = self.level else {
            print("no level to update")
            return
        }
        view.showsVolumeSlider = true
        Timer.scheduledTimer(withTimeInterval: RENDER_VOLUME_PICKER_DELAY_SECS, repeats: false, block: { _ in
            self.setVolume(view: view, level: level)
            view.showsVolumeSlider = false
            self.handleComplete()
        })
    }
    
    func setVolume(view: MPVolumeView, level: Float) {
        guard let volumeSlider = (
            view
                .subviews
                .filter { NSStringFromClass($0.classForCoder) == "MPVolumeSlider"}
                .first
            ) as? UISlider else {
                print(view)
                print("could not finid volume slider")
            return
        }
        print("Setting volume to \(level)")
        volumeSlider.setValue(level, animated: false)
    }
}
           
enum WakeyAudioPlayerType {
    case Silent
    case Alarm
}

struct WakeyAudioPlayer {
    var audioPlayer: AVAudioPlayer
    var type: WakeyAudioPlayerType
}

//----
// MainViewContainer

struct MainViewContainer : View {
    @State var isLoggingIn : Bool = true
    @State var authorizationStatus : UNAuthorizationStatus?
    @State var error : String?
    @State var loggedInUserUID : String?
    @State var userUIDToWakeups : [String : [Wakeup]] = [String : [Wakeup]]()
    @State var usersWithoutWakeups : [User] = []
    @State var audioPlayer: WakeyAudioPlayer?
    @State var volumeLevelToForce: Float?
    @State var alarmSoundFlag: Bool = false
    
    
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
        Firestore.firestore().collectionGroup("wakeups")
            .addSnapshotListener { collectionSnapshot, error in
                guard let collection = collectionSnapshot else {
                    self.error = "Uh oh, we weren't able to find your friends."
                    print("Error fetching collection: \(error!)")
                    return
                }
                var res = [String : [Wakeup]]()
                for tup in collection.documents.map(documentToWakeup) {
                    let (userUID, wakeup) = tup
                    var wakeups = res[userUID] ?? [Wakeup]()
                    wakeups.append(wakeup)
                    res[userUID] = wakeups
                }
                self.userUIDToWakeups = res
        }
        
        Firestore.firestore().collection("userInfos")
            .addSnapshotListener { collectionSnapshot, error in
                guard let collection = collectionSnapshot else {
                    self.error = "Uh oh, we weren't able to find your friends."
                    print("Error fetching collection: \(error!)")
                    return
                }
                self.usersWithoutWakeups = collection.documents.map(documentToUserWithoutWakeups)
        }
        
        getAuthorizationStatus()
        
        /**
         All the work related to taking action on an alarm
         (make sounds, vibrations, etc)
         TODO: factor into modules
         maybe: `AlarmActions play, silent`
         maybe: `ScheduleWorker` (runs and checks, etc)
         */
        configureAVAudioSession()
        
        var handledWakeupDates : Set<String> = []
        self.playSilentAudio()
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { _ in
            guard let wakeupDate = self.getNextWakeupDate() else {
                print("Could not get next wake up")
                return
            }
            let wakeupDateKey = wakeupDate.description
            print("wakeupDateKey: \(wakeupDateKey)")
            if !self.inRange(wakeupDate: wakeupDate) {
                print("wakeupDate not in range")
                return
            }
            
            if handledWakeupDates.contains(wakeupDateKey) {
                print("wakeUpDateKey: \(wakeupDateKey) already handled")
                return
            }
            handledWakeupDates.insert(wakeupDateKey)
            // TODO maybe move these into one function
            self.sendAlarmNotification(triggerTimeInterval: TRIGGER_ALARM_NOTIF_DELAY_SECS)
            self.volumeLevelToForce = 1.0 // set volume to max in advance of playing alarm sound
            self.alarmSoundFlag = true
            Timer.scheduledTimer(withTimeInterval: TRIGGER_SOUND_DELAY_SECS, repeats: false, block: { _ in
                self.playAlarmAudio()
                self.alarmSoundFlag = false
                // TODO: Maybe we can move all the logic that requires aa loggedInUser
                // Into one view, below "MainView"
                saveWakeup(
                    loggedInUserUID: self.loggedInUserUID!,
                    wakeup: Wakeup(alarmDate: wakeupDate, ack: nil)
                )
            })
        })
    }
    
    func allUsers() -> [User] {
        return usersWithoutWakeups.map { (user: User) -> User in
            var newUser = user
            newUser.wakeups = self.userUIDToWakeups[user.uid] ?? []
            return newUser
        }
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
        let (user, _) = splitIntoLoggedInUserAndFriends(
            allUsers: self.allUsers(),
            loggedInUserUID: loggedInUserUID
        )
        return user
    }
    
    //----
    // Wake-up Helpers
    
    func inRange(wakeupDate: Date) -> Bool {
        print("Difference in seconds \(wakeupDate.timeIntervalSinceNow.description)")
        return abs(wakeupDate.timeIntervalSinceNow) <= 30
    }
    
    func getNextWakeupDate() -> Date? {
        guard let user = currentUser() else {
            return nil
        }
        
        guard let wakeyAlarm = user.alarm else {
            return nil
        }
        
        let now = Date()
        let oneMinuteAgo = Calendar.current.date(
            byAdding: .minute, value: -1, to: now
        )!
        return wakeyAlarmToNextDate(wakeyAlarm: wakeyAlarm, baseDate: oneMinuteAgo)
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
        playPath(path: path, type: .Silent)
    }
    
    func playAlarmAudio() {
        let path = Bundle.main.path(forResource: "tickle", ofType: "mp3")!
        playPath(path: path, type: .Alarm)
    }
    
    func sendAlarmNotification(triggerTimeInterval: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Wakey"
        content.body = "☀️ Rise and shine. It's time to wake up :)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTimeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request)
    }
    
    func playPath(path: String, type: WakeyAudioPlayerType) {
        if let oldAudioPlayer = self.audioPlayer {
            oldAudioPlayer.audioPlayer.stop()
        }

        let url = URL(fileURLWithPath: path)
        print("In  starting to play, path: ", path)
        do {
            let newAudioPlayer = try AVAudioPlayer(contentsOf: url)
            newAudioPlayer.prepareToPlay()
            newAudioPlayer.numberOfLoops = -1
            newAudioPlayer.play()
            self.audioPlayer = WakeyAudioPlayer(audioPlayer: newAudioPlayer, type: type)
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
        ZStack {
            ForceVolume(
                level: self.volumeLevelToForce,
                handleComplete: { self.volumeLevelToForce = nil }
            ).frame(width: 0, height: 0)
            MainView(
                isLoggingIn: self.isLoggingIn,
                authorizationStatus: self.authorizationStatus,
                loggedInUserUID: self.loggedInUserUID,
                allUsers: self.allUsers(),
                activeAudioPlayerType: self.audioPlayer?.type,
                error: self.error,
                handleError: { err in self.error = err },
                handleRequestNotificationAuth: self.handleRequestNotificationAuth,
                handleSignInWithFacebook: { self.handleSignInWithFacebook(accessToken: $0) },
                handleSignOut: self.handleSignOut,
                handleSaveAlarm: { self.handleSaveAlarm(alarm: $0) },
                handleSilence: self.playSilentAudio
            )
        }
        .onAppear(perform: self.connect)
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
