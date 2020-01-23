import Foundation
import SwiftUI

struct HomeView : View {
    var alarm : WakeyAlarm
    
    var body : some View {
        Text("\(alarm.hour):\(alarm.minute)")
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(alarm: WakeyAlarm(hour: 8, minute: 55))
    }
}
