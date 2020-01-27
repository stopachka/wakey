import Foundation
import SwiftUI

// TODO(stopachka) consider moving these functions
// to something like AlarmUtils, etc

let ONE_DAY_IN_SECONDS : TimeInterval = 86400

func dateToWakeyAlarm(date: Date) -> WakeyAlarm {
    return WakeyAlarm(
        hour: Calendar.current.component(.hour, from: date),
        minute: Calendar.current.component(.minute, from: date)
    )
}

func isWakeyAlarmAheadOfDate(wakeyAlarm: WakeyAlarm, date: Date) -> Bool {
    let dateHour = Calendar.current.component(.hour, from: date)
    let dateMinute = Calendar.current.component(.minute, from: date)
    let alarmHour = wakeyAlarm.hour
    let alarmMinute = wakeyAlarm.minute
    return (
        // the hour has past
        (alarmHour > dateHour) ||
        // it's the same hour, but the minute has past
        (
            (alarmHour == dateHour) && (alarmMinute > dateMinute)
        )
    )
}

/**
    Given an alarm, returns the next date that the alarm would sound
 */
// TODO(stopachka)
// This _could_ error out, if for example WakeyAlarm contains an hour > 24
// How should we best deal with this case?
// If we make this optional, we'll effectively bleed this edge case throughout the code
func wakeyAlarmToNextDate(wakeyAlarm: WakeyAlarm) -> Date {
    let now = Date()
    
    let referenceDate = isWakeyAlarmAheadOfDate(wakeyAlarm: wakeyAlarm, date: now)
        ? now.addingTimeInterval(ONE_DAY_IN_SECONDS)
        : now
    
    return Calendar.current.date(
        bySettingHour: wakeyAlarm.hour,
        minute: wakeyAlarm.minute,
        second: 0,
        of: referenceDate
    )!
}


struct HomeView : View {
    var wakeyAlarm : WakeyAlarm
    var handleEdit : () -> Void
    var body : some View {
        let date = wakeyAlarmToNextDate(wakeyAlarm: wakeyAlarm)
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return AnyView(
            VStack {
                HStack {
                    Spacer()
                    Button(action: handleEdit) {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                }
                Spacer()
                Text("☀️ \(formatter.string(from: date))")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom)
                Text("You're alarm is set. Here's to a great day")
                    .font(.headline)
                    .padding(.bottom)
                Spacer()
            }
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(
            wakeyAlarm: WakeyAlarm(hour: 17, minute: 55),
            handleEdit: { }
        )
            .padding()
    }
}
