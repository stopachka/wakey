import Foundation
import SwiftUI

struct AlarmEditor : View {
    // TODO(stopachka)
    // What should happen if the seed changes?
    // Should we "reset" the `editingDate`
    var seedWakeyAlarm : WakeyAlarm?
    var handleSave : (WakeyAlarm) -> Void
    var handleCancel : () -> Void
    
    @State var editingDate : Date?
    
    var body : some View {
        let dateBinding : Binding<Date> = Binding(
            get: {
                if let editingDate = self.editingDate {
                    return editingDate
                }
                return wakeyAlarmToNextDate(
                    wakeyAlarm: self.seedWakeyAlarm ?? WakeyAlarm(hour: 7, minute: 30)
                )
            },
            set: { date in
                self.editingDate = date
            }
        )
        
        return VStack {
            HStack {
                Text("⏰ Set your alarm :)")
                    .font(.title)
                Spacer()
            }
            DatePicker(
                selection: dateBinding,
                displayedComponents: .hourAndMinute,
                label: { Text("Alarm") }
            )
                .labelsHidden()
            Spacer()
            HStack {
                Button(action: { self.handleCancel() }) {
                    Text("Save").font(.headline).bold()
                }
                Spacer()
                Button(action: {
                    self.handleSave(
                        dateToWakeyAlarm(date: dateBinding.wrappedValue)
                    )
                }) {
                    Text("Save").font(.headline).bold()
                }
            }
        }
    }
}

struct AlarmEditor_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AlarmEditor(
                seedWakeyAlarm: nil,
                handleSave: { wakeyAlarm in
                    print("got!! \(wakeyAlarm.hour):\(wakeyAlarm.minute)")
                },
                handleCancel: { }
            )
                .padding()
                .previewDisplayName("Default Seed")
            AlarmEditor(
                seedWakeyAlarm: WakeyAlarm(hour: 8, minute: 5),
                handleSave: { _ in },
                handleCancel: { }
            )
                .padding()
                .previewDisplayName("8:05AM Seed")
        }
    }
}
