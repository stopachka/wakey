//
//  AckView.swift
//  wakey
//
//  Created by joe_averbukh on 2/29/20.
//  Copyright © 2020 js. All rights reserved.
//

import SwiftUI
import FirebaseStorage

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

enum AckViewScreenType {
    case Initial
    case Camera
}

struct AckView: View {
    var handleAck: (WakeupAck) -> Void
    var handleSilence: () -> Void
    var activeAudioPlayerType: WakeyAudioPlayerType?
    var loggedInUserUID: String
    @State var ackViewScreenType: AckViewScreenType = .Initial
    @State var image: Image?
    
    func handleImageSave(image: UIImage?) -> Void {
        print("In handleImageSave")
        guard let unwrapImage = image else {
            print("No image to unwrap, go back to ack screen")
            self.ackViewScreenType = .Initial
            return
        }
        
        let ackDate = Date()
        
        // Begin uploading photo
        // (TODO) Consider co-locating logic for saving photos in the same place where
        // we persist other data to Firebase
        print("Uploading....")
        let refIdentifier = "\(self.loggedInUserUID)_\(formatDate(date: ackDate))"
        let storageRef = Storage.storage().reference().child(refIdentifier)
        let uploadTask = storageRef.putData(unwrapImage.jpegData(compressionQuality: 0.1)!)
        
        // Update ack with photo url on success
        uploadTask.observe(.success) { _ in
            storageRef.downloadURL { (url, error) in
                guard let downloadURL = url else {
                    print("Uh-oh. For some reason could not get the download url")
                    return
                }
                print("Photo uploaded successfully!")
                // (TODO) There is a potential race condition here where last wake up may change
                // and as a result handleAck here will ack a different wakeup than the original
                // this is unlikely to happen but my be something we want to protect against
                self.handleAck(WakeupAck(
                    date: ackDate,
                    photoUrl: downloadURL.absoluteString
                ))
            }
        }
        
        // Save ack with date for now
        self.handleAck(WakeupAck(date: ackDate))
    }
    
    var body : some View {
        Group {
            if (self.ackViewScreenType == .Initial) {
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
                        Button(action: { self.ackViewScreenType = .Camera}) {
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
            if (self.ackViewScreenType == .Camera) {
                CaptureImageView(handleImageSave: self.handleImageSave)
                    .edgesIgnoringSafeArea(.all)
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
                activeAudioPlayerType: .Alarm,
                loggedInUserUID: TestUtils.joe.uid
            ).previewDisplayName("With alarm playing")
            AckView(
                handleAck: { _ in },
                handleSilence: { },
                activeAudioPlayerType: .Silent,
                loggedInUserUID: TestUtils.joe.uid
            ).previewDisplayName("With alarm silent")
            AckView(
                handleAck: { _ in },
                handleSilence: { },
                loggedInUserUID: TestUtils.joe.uid
            ).previewDisplayName("Without alarm set")
        }
    }
}
