import SwiftUI

func loggedInUserFirst(allUsers: [User], loggedInUser: User) -> [User] {
    let rest = allUsers.filter { user in
        user.uid != loggedInUser.uid
    }
    let first = allUsers.filter { user in
        user.uid == loggedInUser.uid
    }
    return first + rest
}

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
    var allUsers : [User]
    
    var body : some View {
        VStack {
            ForEach(
                loggedInUserFirst(allUsers: allUsers, loggedInUser: loggedInUser),
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


struct FriendFeed_Previews: PreviewProvider {
    static var previews: some View {
        let joe = User(
            uid: "uid-a", photoURL: nil, displayName: "Joe Averbukh"
        )
        let stopa = User(
            uid: "uid-b", photoURL: nil, displayName: "Stepan Parunashvili"
        )
        return FriendFeed(
            loggedInUser: joe,
            allUsers: [stopa, joe]
        )
    }
}
