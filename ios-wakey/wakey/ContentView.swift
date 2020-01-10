import SwiftUI

struct ContentView : View {
    @EnvironmentObject var sessionStore: SessionStore
    
    func getUser () {
        sessionStore.listen()
    }
    
    var body: some View {
        return Group {
            if (sessionStore.loggedInUser != nil) {
                Text(sessionStore.loggedInUser!.uid)
                Text(sessionStore.loggedInUser!.photoURL!.absoluteString)
            }
            FBLoginContainer().frame(width: 150, height: 50)
        }.onAppear(perform: getUser)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SessionStore())
    }
}
