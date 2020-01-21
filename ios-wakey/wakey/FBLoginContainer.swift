/*
 Wraps FB's FBLoginButton into a `UIViewRepresentable`.
 This lets us embed this into SwiftUI components
 Also handles the glue into Firebase
 */

import SwiftUI
import FBSDKLoginKit

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
            handleError("Failed to get a facebook access token")
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

struct FBLoginContainer_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Text("Log In")
            FBLoginContainer(
                handleError: { _ in },
                handleSignIn: { _ in },
                handleSignOut: {}
            ).frame(width: 0, height: 50, alignment: .center).padding()
        }
    }
}
