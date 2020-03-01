//
//  AckView.swift
//  wakey
//
//  Created by joe_averbukh on 2/29/20.
//  Copyright © 2020 js. All rights reserved.
//

import SwiftUI

class CaptureImageViewCoordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @Binding var isCoordinatorShown: Bool
    @Binding var imageInCoordinator: Image?
    init(isShown: Binding<Bool>, image: Binding<Image?>) {
      _isCoordinatorShown = isShown
      _imageInCoordinator = image
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                  didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
       guard let unwrapImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
       imageInCoordinator = Image(uiImage: unwrapImage)
       isCoordinatorShown = false
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
       isCoordinatorShown = false
    }
}

/**
     Wrap UIKit's UIImagePickerController into a SwiftUI View, we use this
     to present the camera to a user to take a photo
*/
struct CaptureImageView: UIViewControllerRepresentable {
    @Binding var isShown: Bool
    @Binding var image: Image?
    
    func makeCoordinator() -> CaptureImageViewCoordinator {
      return Coordinator(isShown: $isShown, image: $image)
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
    @State var showCaptureImageView: Bool = false
    @State var image: Image?
    
    var body : some View {
        Group {
            if (self.showCaptureImageView) {
                CaptureImageView(isShown: self.$showCaptureImageView, image: self.$image)
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
                    Button(action: { self.showCaptureImageView.toggle()}) {
                        Text("Take photo")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Button(action: { self.handleAck(WakeupAck(date: Date()))}) {
                        Text("I'm up")
                            .font(.headline)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }.padding()
            }
        }
    }
}

struct AckView_Previews: PreviewProvider {
    static var previews: some View {
        AckView(
            handleAck: { _ in }
        )
    }
}
