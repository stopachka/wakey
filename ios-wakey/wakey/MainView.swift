// Created by Stepan Parunashvili on 1/21/20.
// Copyright © 2020 Airbnb Inc. All rights reserved.

import SwiftUI
import FBSDKLoginKit

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
    var body : some View {
        Text("⏳").font(.largeTitle)
    }
}

struct LoginScreen : View {
    var handleError : (String) -> Void
    var handleSignInWithFacebook : (AccessToken) -> Void
    var handleSignOut : () -> Void
    var body : some View {
        VStack {
            Text("🎉 Welcome to Wakey")
                .font(.largeTitle)
                .padding(.bottom)
            Text("Log in with Facebook to get started")
                .font(.headline)
                .padding(.bottom)
            FBLoginContainer(
                handleError: handleError,
                handleSignIn: handleSignInWithFacebook,
                handleSignOut: handleSignOut
            )
                .frame(width: 0, height: 40, alignment: .center)
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

struct MainView : View {
    var isLoggingIn: Bool
    var isLoadingUserInfo: Bool
    var loggedInUserUID: String?
    var allUsers: [User]
    var error : String?
    var handleError : (String) -> Void
    var handleSignInWithFacebook : (AccessToken) -> Void
    var handleSignOut : () -> Void
    
    var body: some View {
        if let error = error {
            return AnyView(ErrorScreen(error: error))
        }
        if isLoggingIn {
            return AnyView(LoadingScreen())
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
        if isLoadingUserInfo {
            return AnyView(LoadingScreen())
        }
        let (potentialLoggedInUser, friends) = splitIntoLoggedInUserAndFriends(
            allUsers: allUsers,
            loggedInUserUID: loggedInUserUID
        )
        guard let loggedInUser = potentialLoggedInUser else {
            // TODO(stopachka)
            // This could happen in the following scenario:
                // User just signs up
                // We haven't written to the "userInfos" table yet
                // For some split second, we would have the user hit a loading state
            // We may want to do better here.
            // One idea could be to track the "saving user" state, or something like that
            // Another could be to do a separate call to fetch the "loggedInUser", and provide that from the top level
            return AnyView(LoadingScreen())
        }
        
        // TODO(stopachka)
        // At this stage, we would actually want to implement navigation
        // and handle states like: "does the user need to provide a photo? etc"
        return AnyView(
            VStack {
                FriendFeed(
                    loggedInUser: loggedInUser,
                    friends: friends
                )
                Button(action: handleSignOut) {
                    Text("Sign out")
                }
            }
        )
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainView(
                isLoggingIn: true,
                isLoadingUserInfo: true,
                loggedInUserUID: nil,
                allUsers: [],
                error: nil,
                handleError: { _ in },
                handleSignInWithFacebook: { _ in },
                handleSignOut: { }
            ).previewDisplayName("Logging In")
            MainView(
                isLoggingIn: true,
                isLoadingUserInfo: true,
                loggedInUserUID: nil,
                allUsers: [],
                error: "This is an example error message",
                handleError: { _ in },
                handleSignInWithFacebook: { _ in },
                handleSignOut: { }
            ).previewDisplayName("Error")
            MainView(
                isLoggingIn: false,
                isLoadingUserInfo: true,
                loggedInUserUID: nil,
                allUsers: [],
                handleError: { _ in },
                handleSignInWithFacebook: { _ in },
                handleSignOut: { }
            ).previewDisplayName("Sign In")
            MainView(
                isLoggingIn: false,
                isLoadingUserInfo: true,
                loggedInUserUID: TestUtils.joe.uid,
                allUsers: [],
                handleError: { _ in },
                handleSignInWithFacebook: { _ in },
                handleSignOut: { }
            ).previewDisplayName("Loading allUsers")
            MainView(
                isLoggingIn: false,
                isLoadingUserInfo: false,
                loggedInUserUID: TestUtils.joe.uid,
                allUsers: [TestUtils.stopa, TestUtils.joe],
                handleError: { _ in },
                handleSignInWithFacebook: { _ in },
                handleSignOut: { }
            ).previewDisplayName("Friend Feed")
        }
    }
}
