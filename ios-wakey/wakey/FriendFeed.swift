import SwiftUI

struct ProfilePhoto : View {
    var imageURL : URL?
    var body : some View {
        URLImage(url: imageURL)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
    }
}

struct FriendFeed : View {
    var loggedInUser : User
    var friends : [User]
    
    var body : some View {
        ScrollView {
            VStack {
                ForEach(
                    ([loggedInUser] + friends),
                    id: \.self.uid
                ) { user in
                    HStack {
                        ProfilePhoto(imageURL: user.photoURL)
                            .frame(width: 50, height: 50)
                        Text(user.displayName ?? "Buddy without a name")
                        Spacer()
                    }
                }
                Spacer()
            }
        }
    }
}


struct FriendFeed_Previews: PreviewProvider {
    static var previews: some View {
        FriendFeed(
            loggedInUser: TestUtils.joe,
            friends: [TestUtils.stopa]
        )
    }
}
