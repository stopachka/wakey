import Foundation
import SwiftUI

let ONE_DAY_IN_SECONDS : TimeInterval = 86400

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
func wakeyAlarmToNextDate(wakeyAlarm: WakeyAlarm) -> Date? {
    let now = Date()
    
    let referenceDate = isWakeyAlarmAheadOfDate(wakeyAlarm: wakeyAlarm, date: now)
        ? now.addingTimeInterval(ONE_DAY_IN_SECONDS)
        : now
    
    return Calendar.current.date(
        bySettingHour: wakeyAlarm.hour,
        minute: wakeyAlarm.minute,
        second: 0,
        of: referenceDate
    )
}

struct EmptyAlarmView : View {
    var body : some View {
        Text("New Alarm")
    }
}

struct HomeView : View {
    var wakeyAlarm : WakeyAlarm
    
    var body : some View {
        guard let date = wakeyAlarmToNextDate(wakeyAlarm: wakeyAlarm) else {
            return AnyView(
                ErrorScreen(error: "Uh oh. We couldn't parse this alarm")
            )
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return AnyView(
            VStack {
                // TODO(stopachka) let's style this : ) 
                HStack {
                    Text("\(formatter.string(from: date)    )")
                        .font(.largeTitle)
                        .bold()
                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color(red: 0, green: 0, blue: 0, opacity: 0.05))
                )
                Spacer()
            }
        )
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
         HomeView(wakeyAlarm: WakeyAlarm(hour: 17, minute: 55))
            .padding()
            .previewDisplayName("Example Alarm")
         HomeView(wakeyAlarm: WakeyAlarm(hour: 107, minute: 55))
            .padding()
            .previewDisplayName("Broken Time")
        }
    }
}
