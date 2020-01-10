import SwiftUI
import Firebase
import FBSDKLoginKit

/**
 Wraps FB's FBLoginContainer into a `UIViewRepresentable`.
 This lets us embed this into SwiftUI components
 */
struct FBLoginContainer: UIViewRepresentable {
    func makeCoordinator() -> FBLoginContainer.Coordinator {
        return FBLoginContainer.Coordinator()
    }

    func makeUIView(context: UIViewRepresentableContext<FBLoginContainer>) -> FBLoginButton {
        let loginButton = FBLoginButton()
        loginButton.delegate = context.coordinator

        return loginButton
    }

    // Needed to conform to UIViewRepresentable's protocol, but not used
    func updateUIView(_ uiView: FBLoginButton, context: UIViewRepresentableContext<FBLoginContainer>) {}

    class Coordinator : NSObject, LoginButtonDelegate {
        func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
            if let error = error {
                print(error.localizedDescription)
                return
            }
            if let currentAccessToken = AccessToken.current {
                let credential = FacebookAuthProvider.credential(withAccessToken: currentAccessToken.tokenString)
                Auth.auth().signIn(with: credential)
            } else {
                print("uh oh, no access token")
            }
        }

        func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
            try! Auth.auth().signOut()
        }
    }
}
