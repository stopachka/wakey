import SwiftUI

struct ContentView : View {
    @EnvironmentObject var sessionStore: SessionStore
    @EnvironmentObject var userInfoStore: UserInfoStore
    
    var body: some View {
        if sessionStore.isLoading {
            return AnyView(Text("Loading..."))
        }
        
        guard let loggedInUser = sessionStore.loggedInUser else {
            return AnyView(FBLoginContainer().frame(width: 150, height: 50))
        }
        let wakeyUsers = userInfoStore.users
        return AnyView(
            VStack {
                // TODO: Separate logged in user from user list
                // TODO: Flesh out proper friends list display
                    // * Load image
                    // * Design ListRow
                // TODO: Implement friends press -> photo
                Text("Loogged in user: \(loggedInUser.displayName!)")
                ForEach(wakeyUsers, id: \.self.uid) { wakeyUser in
                    Text(wakeyUser.displayName)
                }
            }
        )
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(SessionStore())
            .environmentObject(UserInfoStore())
    }
}
