//
//  AckView.swift
//  wakey
//
//  Created by joe_averbukh on 2/29/20.
//  Copyright © 2020 js. All rights reserved.
//

import SwiftUI

class CaptureImageViewCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var handleImageSave: (UIImage?) -> Void
    
    init(handleImageSave: @escaping (UIImage?) -> Void) {
        self.handleImageSave = handleImageSave
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                  didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let unwrapImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            return
        }
        self.handleImageSave(unwrapImage)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.handleImageSave(nil)
    }
}

/**
     Wrap UIKit's UIImagePickerController into a SwiftUI View, we use this
     to present the camera to a user to take a photo
*/
struct CaptureImageView: UIViewControllerRepresentable {
    var handleImageSave: (UIImage?) -> Void
    
    func makeCoordinator() -> CaptureImageViewCoordinator {
        return Coordinator(handleImageSave: handleImageSave)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<CaptureImageView>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController,
                                context: UIViewControllerRepresentableContext<CaptureImageView>) {
    }
}

struct AckView: View {
    var handleAck: (WakeupAck) -> Void
    var handleSilence: () -> Void
    var activeAudioPlayerType: WakeyAudioPlayerType?
    @State var showCaptureImageView: Bool = false
    @State var image: Image?
    
    func handleImageSave(image: UIImage?) -> Void {
        self.handleAck(WakeupAck(date: Date()))
    }
    
    var body : some View {
        Group {
            if (self.showCaptureImageView) {
                CaptureImageView(handleImageSave: self.handleImageSave)
                    .edgesIgnoringSafeArea(.all)
            } else {
                VStack {
                    Spacer()
                    Text("🎈 Wake up! 🎈")
                        .font(.largeTitle)
                        .padding(.bottom)
                    Text("Click 👇 this button to realllly prove you're awake")
                        .padding(.bottom)
                        .multilineTextAlignment(.center)
                    if (self.activeAudioPlayerType == .Alarm) {
                        Button(action: {self.handleSilence()}) {
                            Text("🙌 Silence!")
                                .font(.headline)
                                .foregroundColor(.blue)
                                .padding()
                        }
                    } else {
                        Button(action: { self.showCaptureImageView.toggle()}) {
                            Text("Take photo")
                                .font(.headline)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .padding()
                        }
                    }
                    Spacer()
                }.padding()
            }
        }
    }
}

struct AckView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AckView(
                handleAck: { _ in },
                handleSilence: { },
                activeAudioPlayerType: .Alarm
            ).previewDisplayName("With alarm playing")
            AckView(
                handleAck: { _ in },
                handleSilence: { },
                activeAudioPlayerType: .Silent
            ).previewDisplayName("With alarm silent")
            AckView(
                handleAck: { _ in },
                handleSilence: { }
            ).previewDisplayName("Without alarm set")
        }
    }
}
