import Foundation
import UserNotifications

struct TestUtils {
    static let joe = User(
        uid: "uid-a", photoURL: nil, displayName: "Joe Averbukh", alarm: nil
    )
    static let stopa = User(
        uid: "uid-b", photoURL: nil, displayName: "Stepan Parunashvili", alarm: nil
    )
    static let joeWith8AMAlarm = User(
        uid: "uid-a", photoURL: nil, displayName: "Joe Averbukh", alarm: WakeyAlarm(hour: 8, minute: 0)
    )
}

