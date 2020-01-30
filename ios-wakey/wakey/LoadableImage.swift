import Foundation
import SwiftUI
import Combine

struct LoadableImage : View {
    var uiImage : UIImage?
    var body : some View {
        if let uiImage = uiImage {
            return AnyView(Image(uiImage: uiImage))
        } else {
            return AnyView(Rectangle().fill(Color.secondary))
        }
    }
}

struct URLImage : View {
    var url : URL?
    @State var loadedImage : UIImage?
    
    // TODO(stopachka)
    // We may want to introduce a type of cached fetcher here
    // Maybe it should be an `EnvironmentObject`
    func load() {
        // TODO(stopachka)
        // what if _url_ changes?
        // This would _not_ fetch, because this only happens `onAppear`
        // Using the cached fetcher approach may be best as a result
        guard let url = url else {
            return
        }
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Failed to load image", url)
                return
            }
            self.loadedImage = UIImage(data: data)
        }.resume()
    }
    
    var body : some View {
        LoadableImage(uiImage: loadedImage).onAppear(perform: load)
    }
}

struct LoadableImage_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadableImage(uiImage: nil)
                .frame(width: 100, height: 100, alignment: .center)
                .previewDisplayName("No Image")
            LoadableImage(uiImage: UIImage(systemName: "photo"))
                .frame(width: 100, height: 100, alignment: .center)
                .previewDisplayName("With Image")
        }
    }
}
