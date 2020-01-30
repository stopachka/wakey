import SwiftUI

struct ProfilePhoto : View {
    var imageURL : URL?
    var body : some View {
        URLImage(url: imageURL)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white, lineWidth: 4))
    }
}

func friendlyName(displayName: String?, defaultValue: String) -> String {
    guard let displayName = displayName else {
        return defaultValue
    }
    if displayName.isEmpty {
        return defaultValue
    }
    
    let nameButLast = displayName.components(separatedBy: " ").dropLast().joined()
    if nameButLast.isEmpty {
        return defaultValue
    }
    
    return nameButLast
}

func friendlyAlarm(wakeyAlarm: WakeyAlarm) -> String {
    let date = wakeyAlarmToNextDate(wakeyAlarm: wakeyAlarm)
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    
    return formatter.string(from: date)
}

func feedAlarmText(wakeyAlarm: WakeyAlarm?) -> String {
    guard let wakeyAlarm = wakeyAlarm else {
        return "🙀 No Alarm"
    }
    return "⏰ \(friendlyAlarm(wakeyAlarm: wakeyAlarm))"
}

struct FeedItem : View {
    var user : User
    var body : some View {
        return HStack {
            VStack {
                ProfilePhoto(imageURL: user.photoURL)
                    .frame(width: 50, height: 50)
                Spacer()
            }
            VStack {
                Spacer()
                HStack {
                    Text(
                        feedAlarmText(wakeyAlarm: user.alarm)
                    )
                        .font(.headline)
                    Text(
                        friendlyName(displayName: user.displayName, defaultValue: "Nameless Buddy")
                    ).font(.headline)
                    Spacer()
                }.padding(.bottom)
                Spacer()
            }
        }
    }
}
struct FriendFeed : View {
    var loggedInUser : User
    var friends : [User]
    
    var body : some View {
        return ScrollView {
            VStack {
                ForEach(
                    ([loggedInUser] + friends),
                    id: \.self.uid
                ) { user in
                    FeedItem(user: user).padding(.bottom)
                }
                Spacer()
            }
        }
    }
}


struct FriendFeed_Previews: PreviewProvider {
    static var previews: some View {
        FriendFeed(
            loggedInUser: TestUtils.joeWith8AMAlarm,
            friends: [TestUtils.stopa]
        )
    }
}
