import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let name: String
    let loopMode: LottieLoopMode
    let animationSpeed: CGFloat
    var onAnimationComplete: (() -> Void)?
    var onAnimationNotFound: (() -> Void)?
    
    init(
        name: String,
        loopMode: LottieLoopMode = .playOnce,
        animationSpeed: CGFloat = 1.0,
        onAnimationComplete: (() -> Void)? = nil,
        onAnimationNotFound: (() -> Void)? = nil
    ) {
        self.name = name
        self.loopMode = loopMode
        self.animationSpeed = animationSpeed
        self.onAnimationComplete = onAnimationComplete
        self.onAnimationNotFound = onAnimationNotFound
    }
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        
        let animationView = LottieAnimationView()
        let animation = LottieAnimation.named(name)
        
        if animation != nil {
            animationView.animation = animation
            animationView.contentMode = UIView.ContentMode.scaleAspectFit
            animationView.loopMode = loopMode
            animationView.animationSpeed = animationSpeed
            animationView.play { finished in
                if finished {
                    onAnimationComplete?()
                }
            }
        } else {
            // Animation not found, notify parent and trigger completion
            onAnimationNotFound?()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onAnimationComplete?()
            }
        }
        
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        
        NSLayoutConstraint.activate([
            animationView.heightAnchor.constraint(equalTo: view.heightAnchor),
            animationView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Update if needed
    }
}

