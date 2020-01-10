import SwiftUI

struct ContentView : View {
    @EnvironmentObject var sessionStore: SessionStore
    
    func getUser () {
        sessionStore.listen()
    }
    
    var body: some View {
        return Group {
            Text("Hello!")
            FBLoginContainer().frame(width: 150, height: 50)
        }.onAppear(perform: getUser)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SessionStore())
    }
}
