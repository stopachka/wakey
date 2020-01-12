import SwiftUI

struct ContentView : View {
    @EnvironmentObject var sessionStore: SessionStore
    
    var body: some View {
        if sessionStore.isLoading {
            return AnyView(Text("Loading..."))
        }

        guard let loggedInUser = sessionStore.loggedInUser else {
            return AnyView(FBLoginContainer().frame(width: 150, height: 50))
        }
        return AnyView(
            Text(loggedInUser.uid)
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SessionStore())
    }
}
