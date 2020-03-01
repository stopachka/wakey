import Foundation

struct TestUtils {
    static let activeWakeup = Wakeup(alarmDate: Date(), ack: nil)
    static let ackedWakeup = Wakeup(alarmDate: Date(), ack: WakeupAck(date: Date()))
    
    static let stopa = User(
        uid: "uid-b", photoURL: nil, displayName: "Stepan Parunashvili", alarm: nil, wakeups: []
    )
    static let joe = User(
        uid: "uid-a", photoURL: nil, displayName: "Joe Averbukh", alarm: nil, wakeups: []
    )
    static let joeWith8AMAlarm = User(
        uid: "uid-a", photoURL: nil, displayName: "Joe Averbukh", alarm: WakeyAlarm(hour: 8, minute: 0), wakeups: [TestUtils.ackedWakeup]
    )
    static let joeWithActiveWakeup = User(
        uid: "uid-a", photoURL: nil, displayName: "Joe Averbukh", alarm: WakeyAlarm(hour: 8, minute: 0), wakeups: [TestUtils.activeWakeup]
    )
    static let weirdName = User(
        uid: "uid-c", photoURL: nil, displayName: "Super Weird Name", alarm: WakeyAlarm(hour: 8, minute: 0), wakeups: []
    )
}

