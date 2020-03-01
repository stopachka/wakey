//
//  AckView.swift
//  wakey
//
//  Created by joe_averbukh on 2/29/20.
//  Copyright © 2020 js. All rights reserved.
//

import SwiftUI

struct AckView: View {
    var handleAck: (WakeupAck) -> Void
    var body : some View {
        
        VStack {
            Text("🎈 Wake up! 🎈")
                .font(.largeTitle)
                .padding(.bottom)
            Text("Click 👇 this button to realllly prove you're awake")
                .padding(.bottom)
                .multilineTextAlignment(.center)
            Button(action: { self.handleAck(WakeupAck(date: Date()))}) {
                Text("I'm up")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .padding()
            }
            
        }
    }
}

struct AckView_Previews: PreviewProvider {
    static var previews: some View {
        AckView(handleAck: { _ in })
    }
}
