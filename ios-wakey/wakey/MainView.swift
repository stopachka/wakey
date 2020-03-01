// Created by Stepan Parunashvili on 1/21/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import SwiftUI
import FBSDKLoginKit
import AVFoundation

struct NotificationRequestAuthView : View {
    var handleRequestNotificationAuth: () -> Void
    var body : some View {
        VStack {
            Text("⏰ Notifications")
                .font(.largeTitle)
                .padding(.bottom)
            Text("For Wakey to work, we need to enable notifications")
                .padding(.bottom)
            Text("Click 👇 this button to do that")
                .padding(.bottom)
            Button(action: handleRequestNotificationAuth) {
                Text("Enable Notifications")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .padding()
            }
            
        }
    }
}

struct NotificationAuthDeniedView : View {
    func handleOpenSettings() {
        UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
    
    var body : some View {
        VStack {
            Text("😅 Enable notifications")
                .font(.largeTitle)
                .padding(.bottom)
            Text("For Wakey to work, you need to enable Alerts and Sounds")
                .padding(.bottom)
            Text("Open your settings 👇 to do that")
                .padding(.bottom)
            Button(action: handleOpenSettings) {
                Text("Open Settings")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .padding()
            }
        }
    }
}

struct ErrorScreen : View {
    var error : String
    var body : some View {
        VStack {
            Text("🚧 😅")
                .font(.largeTitle).padding(.bottom)
            Text("We dun goofed. Sorry about that!")
                .font(.headline).padding(.bottom)
            Text("Please contact Joe & Stepan.").padding(.bottom)
            Text("Here's the error message:").padding(.bottom)
            HStack {
                Spacer()
                Text(error).padding()
                Spacer()
            }.background(Color(red: 0, green: 0, blue: 0, opacity: 0.05))
        }
    }
}


struct LoadingScreen : View {
    var description : String
    var body : some View {
        VStack {
            Text("⏳").font(.largeTitle).padding()
            Text(description).font(.caption)
        }
    }
}

func splitIntoLoggedInUserAndFriends(allUsers: [User], loggedInUserUID: String) -> (User?, [User]) {
    let friends = allUsers.filter { user in
        user.uid != loggedInUserUID
    }
    let loggedInUser = allUsers.filter { user in
        user.uid == loggedInUserUID
    }.first
    return (loggedInUser, friends)
}

func isActiveWakeup(wakeup: Wakeup) -> Bool {
    if wakeup.ack != nil {
        return false
    }
    
    let secondsSinceAlarmDate = abs(Date().timeIntervalSince(wakeup.alarmDate))
    if secondsSinceAlarmDate > (30 * 60) {
        return false
    }
    
    return true
}

enum WakeyTab {
    case Home
    case Friends
}

// TODO(stopachka)
// Consider moving out much of the view components here into their own files
struct MainView : View {
    var isLoggingIn: Bool
    var authorizationStatus: UNAuthorizationStatus?
    var loggedInUserUID: String?
    var allUsers: [User]
    var error : String?
    var handleError : (String) -> Void
    var handleRequestNotificationAuth : () -> Void
    var handleSignInWithFacebook : (AccessToken) -> Void
    var handleSignOut : () -> Void
    var handleSaveAlarm : (WakeyAlarm) -> Void
    
    @State var isEditingAlarm : Bool = false
    @State var activeTab : WakeyTab = .Home
    
    var body: some View {
        /**
         TODO(stopachka)
         This view has a _lot_ of logic
         Some are warranted
            i.e we _must_ be logged in to show anything
         but some may be better respresented as "routes"
         Considering solutions to refactoring this at some point
         **/
        /**
         Exit early and show an error if we have it
         */
        if let error = error {
            return AnyView(ErrorScreen(error: error))
        }
        /**
         Make sure we've logged in
        */
        if isLoggingIn {
            return AnyView(LoadingScreen(description: "Logging in..."))
        }
        guard let loggedInUserUID = loggedInUserUID else {
            return AnyView(
                LoginScreen(
                    handleError: handleError,
                    handleSignInWithFacebook: handleSignInWithFacebook,
                    handleSignOut: handleSignOut
                )
            )
        }
        /**
         Make sure notification settings are enabled
        */
        guard let authorizationStatus = authorizationStatus else {
            return AnyView(
                LoadingScreen(description: "Finding notification settings")
            )
        }
        if authorizationStatus == .notDetermined {
            return AnyView(
                NotificationRequestAuthView(
                    handleRequestNotificationAuth: handleRequestNotificationAuth
                ).padding()
            )
        }
        if authorizationStatus != .authorized {
            return AnyView(
                NotificationAuthDeniedView().padding()
            )
        }
        /**
         Make sure we've fetched user info
        */
        let (potentialLoggedInUser, friends) = splitIntoLoggedInUserAndFriends(
            allUsers: allUsers,
            loggedInUserUID: loggedInUserUID
        )
        guard let loggedInUser = potentialLoggedInUser else {
            /**
             TODO(stopachka)
             This could happen in the following scenario:
                User just signs up
                We haven't connected tothe userInfos table yet, or
                We haven't written the new user to the "userInfos" table yet
             We may want to do better here.
             One idea could be to track the "saving user" state, or something like that
             Another could be to do a separate call to fetch the "loggedInUser",
             and provide that from the top level
            */
            return AnyView(LoadingScreen(description: "Grabbing your info..."))
        }
        /**
         Create an alarm if we don't have it
        */
        guard let alarm = loggedInUser.alarm else {
            return AnyView(
                CreateAlarm(
                    handleSave: self.handleSaveAlarm
                ).padding()
            )
        }
        
        /**
         Show screen to acknolwedge wake-up
        */
        let lastWakeup = loggedInUser.wakeups.last
        if lastWakeup != nil && isActiveWakeup(wakeup: lastWakeup!) {
            return AnyView(
                AckView(handleAck: { ack in
                    var updatedWakeup = lastWakeup!
                    updatedWakeup.ack = ack
                    saveWakeup(loggedInUserUID: loggedInUserUID, wakeup: updatedWakeup)
                })
                    .padding()
            )
        }

        /**
         Show the editing alarm view if that's the case
        */
        if isEditingAlarm {
            return AnyView(
                EditAlarm(
                    seedWakeyAlarm: alarm,
                    handleSave: {
                        self.handleSaveAlarm($0)
                        self.isEditingAlarm = false
                        
                    },
                    handleCancel: {
                        self.isEditingAlarm = false
                    }
                ).padding()
            )
        }
        /**
         Show the tab view otherwise
        */
        return AnyView(
            TabView(selection: $activeTab) {
                HomeView(
                    wakeyAlarm: alarm,
                    handleEdit: {
                        self.isEditingAlarm = true
                    }
                ).tabItem {
                    VStack {
                        if activeTab == .Home {
                            Image(systemName: "house.fill")
                        } else {
                            Image(systemName: "house")
                        }
                        Text("Home")
                    }
                }.padding().tag(WakeyTab.Home)
                VStack {
                    FriendFeed(
                        loggedInUser: loggedInUser,
                        friends: friends
                    )
                    Button(action: { self.handleSignOut() }) {
                        Text("Sign out")
                    }
                }.padding().tabItem {
                    VStack {
                        if activeTab == .Friends {
                            Image(systemName: "person.3.fill")
                        } else {
                            Image(systemName: "person.3")
                        }
                        Text("Friends")
                    }
                }.tag(WakeyTab.Friends)
            }
        )
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Group {
                MainView(
                    isLoggingIn: true,
                    authorizationStatus: nil,
                    loggedInUserUID: nil,
                    allUsers: [],
                    error: nil,
                    handleError: { _ in },
                    handleRequestNotificationAuth: {},
                    handleSignInWithFacebook: { _ in },
                    handleSignOut: { },
                    handleSaveAlarm: { _ in }
                ).previewDisplayName("Logging In")
                MainView(
                    isLoggingIn: true,
                    authorizationStatus: nil,
                    loggedInUserUID: nil,
                    allUsers: [],
                    error: "This is an example error message",
                    handleError: { _ in },
                    handleRequestNotificationAuth: {},
                    handleSignInWithFacebook: { _ in },
                    handleSignOut: { },
                    handleSaveAlarm: { _ in }
                ).previewDisplayName("Error")
                MainView(
                    isLoggingIn: false,
                    authorizationStatus: nil,
                    loggedInUserUID: nil,
                    allUsers: [],
                    handleError: { _ in },
                    handleRequestNotificationAuth: {},
                    handleSignInWithFacebook: { _ in },
                    handleSignOut: { },
                    handleSaveAlarm: { _ in }
                ).previewDisplayName("Sign In")
                MainView(
                    isLoggingIn: false,
                    authorizationStatus: .notDetermined,
                    loggedInUserUID: TestUtils.joe.uid,
                    allUsers: [],
                    handleError: { _ in },
                    handleRequestNotificationAuth: {},
                    handleSignInWithFacebook: { _ in },
                    handleSignOut: { },
                    handleSaveAlarm: { _ in }
                ).previewDisplayName("Enable Notifications")
            }
            Group {
                MainView(
                    isLoggingIn: false,
                    authorizationStatus: .denied,
                    loggedInUserUID: TestUtils.joe.uid,
                    allUsers: [],
                    handleError: { _ in },
                    handleRequestNotificationAuth: {},
                    handleSignInWithFacebook: { _ in },
                    handleSignOut: { },
                    handleSaveAlarm: { _ in }
                ).previewDisplayName("Denied Notifications")
                MainView(
                    isLoggingIn: false,
                    authorizationStatus: .authorized,
                    loggedInUserUID: TestUtils.joe.uid,
                    allUsers: [],
                    handleError: { _ in },
                    handleRequestNotificationAuth: {},
                    handleSignInWithFacebook: { _ in },
                    handleSignOut: { },
                    handleSaveAlarm: { _ in }
                ).previewDisplayName("Loading allUsers")
                MainView(
                    isLoggingIn: false,
                    authorizationStatus: .authorized,
                    loggedInUserUID: TestUtils.joe.uid,
                    allUsers: [TestUtils.stopa, TestUtils.joe],
                    handleError: { _ in },
                    handleRequestNotificationAuth: {},
                    handleSignInWithFacebook: { _ in },
                    handleSignOut: { },
                    handleSaveAlarm: { _ in }
                ).previewDisplayName("No Alarm Set")
                MainView(
                    isLoggingIn: false,
                    authorizationStatus: .authorized,
                    loggedInUserUID: TestUtils.joe.uid,
                    allUsers: [TestUtils.stopa, TestUtils.joeWith8AMAlarm],
                    handleError: { _ in },
                    handleRequestNotificationAuth: {},
                    handleSignInWithFacebook: { _ in },
                    handleSignOut: { },
                    handleSaveAlarm: { _ in }
                ).previewDisplayName("With Alarm")
                MainView(
                    isLoggingIn: false,
                    authorizationStatus: .authorized,
                    loggedInUserUID: TestUtils.joe.uid,
                    allUsers: [TestUtils.stopa, TestUtils.joeWith8AMAlarm],
                    handleError: { _ in },
                    handleRequestNotificationAuth: {},
                    handleSignInWithFacebook: { _ in },
                    handleSignOut: { },
                    handleSaveAlarm: { _ in },
                    isEditingAlarm: true
                ).previewDisplayName("Editing Alarm")
                MainView(
                    isLoggingIn: false,
                    authorizationStatus: .authorized,
                    loggedInUserUID: TestUtils.joe.uid,
                    allUsers: [TestUtils.stopa, TestUtils.joeWithActiveWakeup],
                    handleError: { _ in },
                    handleRequestNotificationAuth: {},
                    handleSignInWithFacebook: { _ in },
                    handleSignOut: { },
                    handleSaveAlarm: { _ in },
                    activeTab: .Friends
                ).previewDisplayName("Ack View")
                MainView(
                    isLoggingIn: false,
                    authorizationStatus: .authorized,
                    loggedInUserUID: TestUtils.joe.uid,
                    allUsers: [TestUtils.stopa, TestUtils.joeWith8AMAlarm],
                    handleError: { _ in },
                    handleRequestNotificationAuth: {},
                    handleSignInWithFacebook: { _ in },
                    handleSignOut: { },
                    handleSaveAlarm: { _ in },
                    activeTab: .Friends
                ).previewDisplayName("Friends Feed")
            }
        }
    }
}
