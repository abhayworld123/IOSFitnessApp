import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerLayerView: UIViewRepresentable {
    let player: AVPlayer
    let viewModel: VideoPlayerViewModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(playerLayer)
        
        // Setup PiP with the player layer
        DispatchQueue.main.async {
            viewModel.setupPiP(with: playerLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let layer = uiView.layer.sublayers?.first as? AVPlayerLayer {
            layer.frame = uiView.bounds
        }
    }
}


