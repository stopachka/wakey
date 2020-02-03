import Foundation
import SwiftUI


struct AlarmEditor : View {
    @Binding var wakeyAlarm : WakeyAlarm
    
    var body : some View {
        let dateBinding : Binding<Date> = Binding(
            get: {
                wakeyAlarmToNextDate(wakeyAlarm: self.wakeyAlarm)
            },
            set: { date in
                self.wakeyAlarm = dateToWakeyAlarm(date: date)
            }
        )
        
        return DatePicker(
                selection: dateBinding,
                displayedComponents: .hourAndMinute,
                label: { Text("Alarm") }
        ).labelsHidden()
    }
}

struct AlarmActionButton : View {
    var action : () -> Void
    var label : String
    var body : some View {
        Button(action: action) {
            Text(label).font(.headline).bold()
        }
    }
}

struct CreateAlarm : View {
    var handleSave : (WakeyAlarm) -> Void
    @State var wakeyAlarm : WakeyAlarm = WakeyAlarm(hour: 7, minute: 30)
    var body: some View {
        VStack {
            Spacer()
            Text("🤗 Let's get you started")
                .font(.largeTitle)
                .padding(.bottom)
            Text("When would you like to wake up?")
                .font(.headline)
                .padding(.bottom)
            AlarmEditor(
                wakeyAlarm: $wakeyAlarm
            )
            Spacer()
            AlarmActionButton(
                action: { self.handleSave(self.wakeyAlarm) },
                label: "🚀 Get Started"
            )
        }
    }
}

struct EditAlarm : View {
    var seedWakeyAlarm : WakeyAlarm
    var handleSave : (WakeyAlarm) -> Void
    var handleCancel : () -> Void
    
    @State var editingWakeyAlarm : WakeyAlarm?
    var body : some View {
        let alarmBinding = Binding(
            get: {
                return self.editingWakeyAlarm ?? self.seedWakeyAlarm
            },
            set: {
                self.editingWakeyAlarm = $0
            }
        )
        return VStack {
            Spacer()
            Text("👌 Let's edit your alarm")
                .font(.largeTitle)
                .padding(.bottom)
            Text("When would you like to wake up?")
                .font(.headline)
                .padding(.bottom)
            AlarmEditor(
                wakeyAlarm: alarmBinding
            )
            Spacer()
            HStack {
                AlarmActionButton(
                    action: handleCancel,
                    label: "Cancel"
                )
                Spacer()
                AlarmActionButton(
                    action: { self.handleSave(alarmBinding.wrappedValue) },
                    label: "Save"
                )
            }
        }
    }
}

struct AlarmEditor_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CreateAlarm(
                handleSave: { _ in }
            ).padding().previewDisplayName("Create Alarm")
            EditAlarm(
                seedWakeyAlarm: WakeyAlarm(hour: 7, minute: 0),
                handleSave: { _ in },
                handleCancel: { }
            ).padding().previewDisplayName("Edit Alarm")
        }
    }
}
