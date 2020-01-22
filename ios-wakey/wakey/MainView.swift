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

struct MainView : View {
    var isLoggingIn : Bool = true
    var error : String?
    var loggedInUser : User?
    var allUsers : [User]
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
        guard let loggedInUser = loggedInUser else {
            return AnyView(
                LoginScreen(
                    handleError: handleError,
                    handleSignInWithFacebook: handleSignInWithFacebook,
                    handleSignOut: handleSignOut
                )
            )
        }
        // TODO(stopachka)
        // At this stage, we would actually want to implement navigation
        // and handle states like: "does the user need to provide a photo? etc"
        return AnyView(
            VStack {
                FriendFeed(
                    loggedInUser: loggedInUser,
                    allUsers: allUsers
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
                error: nil,
                loggedInUser: nil,
                allUsers: [],
                handleError: { _ in },
                handleSignInWithFacebook: { _ in },
                handleSignOut: { }
            ).previewDisplayName("Logging In")
            MainView(
                isLoggingIn: true,
                error: "This is an example error message",
                loggedInUser: nil,
                allUsers: [],
                handleError: { _ in },
                handleSignInWithFacebook: { _ in },
                handleSignOut: { }
            ).previewDisplayName("Error")
            MainView(
                isLoggingIn: false,
                error: nil,
                loggedInUser: nil,
                allUsers: [],
                handleError: { _ in },
                handleSignInWithFacebook: { _ in },
                handleSignOut: { }
            ).previewDisplayName("Sign In")
            MainView(
                isLoggingIn: false,
                error: nil,
                loggedInUser: TestUtils.joe,
                allUsers: [TestUtils.stopa, TestUtils.joe],
                handleError: { _ in },
                handleSignInWithFacebook: { _ in },
                handleSignOut: { }
            ).previewDisplayName("Friend Feed")
        }
    }
}
