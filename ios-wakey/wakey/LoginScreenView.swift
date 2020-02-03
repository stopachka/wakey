import SwiftUI
import FBSDKLoginKit


/*
Wraps FB's FBLoginButton into a `UIViewRepresentable`.
This lets us embed this into SwiftUI components
Also handles the glue into Firebase
*/

class FBLoginButtonCoordinator : NSObject, LoginButtonDelegate {
    var handleError : (String) -> Void
    var handleSignIn : (AccessToken) -> Void
    var handleSignOut : () -> Void

    init(
        handleError : @escaping (String) -> Void,
        handleSignIn : @escaping (AccessToken) -> Void,
        handleSignOut : @escaping () -> Void
    ) {
        self.handleError = handleError
        self.handleSignIn = handleSignIn
        self.handleSignOut = handleSignOut
    }
    
    func loginButton(
        _ loginButton: FBLoginButton,
        didCompleteWith result: LoginManagerLoginResult?,
        error: Error?
    ) {
        if let error = error {
            handleError("Facebook Auth returned an error")
            print(error.localizedDescription)
            return
        }
        guard let currentAccessToken = AccessToken.current else {
            print("Failed to get a facebook access token")
            return
        }
        handleSignIn(currentAccessToken)
    }

    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        handleSignOut()
    }
}

struct FBLoginContainer: UIViewRepresentable {
    var handleError : (String) -> Void
    var handleSignIn : (AccessToken) -> Void
    var handleSignOut : () -> Void
    
    func makeCoordinator() -> FBLoginButtonCoordinator {
        return FBLoginButtonCoordinator(
            handleError: handleError,
            handleSignIn: handleSignIn,
            handleSignOut: handleSignOut
        )
    }

    func makeUIView(context: UIViewRepresentableContext<FBLoginContainer>) -> FBLoginButton {
        let loginButton = FBLoginButton()
        loginButton.delegate = context.coordinator
        return loginButton
    }

    // Needed to conform to UIViewRepresentable's protocol, but not used
    func updateUIView(_ uiView: FBLoginButton, context: UIViewRepresentableContext<FBLoginContainer>) {}
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
            ).frame(width: 0, height: 40, alignment: .center)
        }
    }
}

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        LoginScreen(
            handleError: { _ in },
            handleSignInWithFacebook: { _ in },
            handleSignOut: {}
        )
    }
}
