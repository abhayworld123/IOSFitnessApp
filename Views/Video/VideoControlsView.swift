import SwiftUI
import AVKit

struct VideoControlsView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @State private var isDragging = false
    @State private var dragValue: Double = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Controls
            HStack {
                Spacer()
                
                // Playback Speed
                Menu {
                    Button("0.5x") {
                        viewModel.setPlaybackRate(0.5)
                    }
                    Button("1x") {
                        viewModel.setPlaybackRate(1.0)
                    }
                    Button("1.5x") {
                        viewModel.setPlaybackRate(1.5)
                    }
                    Button("2x") {
                        viewModel.setPlaybackRate(2.0)
                    }
                } label: {
                    Text("\(String(format: "%.1f", viewModel.playbackRate))x")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                }
            }
            .padding()
            
            Spacer()
            
            // Center Play/Pause Button
            Button(action: {
                viewModel.togglePlayPause()
            }) {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10)
            }
            .padding()
            
            Spacer()
            
            // Bottom Controls
            VStack(spacing: 12) {
                // Seek Bar
                VStack(spacing: 4) {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            Rectangle()
                                .fill(Color.white.opacity(0.3))
                                .frame(height: 4)
                            
                            // Progress
                            Rectangle()
                                .fill(AppConstants.Colors.primary)
                                .frame(
                                    width: geometry.size.width * progress,
                                    height: 4
                                )
                            
                            // Thumb
                            Circle()
                                .fill(Color.white)
                                .frame(width: 16, height: 16)
                                .offset(x: geometry.size.width * progress - 8)
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            isDragging = true
                                            let newProgress = max(0, min(1, value.location.x / geometry.size.width))
                                            dragValue = newProgress * viewModel.duration
                                        }
                                        .onEnded { _ in
                                            viewModel.seek(to: dragValue)
                                            isDragging = false
                                        }
                                )
                        }
                    }
                    .frame(height: 44)
                    
                    // Time Labels
                    HStack {
                        Text(formatTime(isDragging ? dragValue : viewModel.currentTime))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text(formatTime(viewModel.duration))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                // Control Buttons
                HStack(spacing: 20) {
                    // 10s Back
                    Button(action: {
                        viewModel.seekBackward(seconds: 10)
                    }) {
                        Image(systemName: "gobackward.10")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Play/Pause
                    Button(action: {
                        viewModel.togglePlayPause()
                    }) {
                        Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(AppConstants.Colors.primary)
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // 10s Forward
                    Button(action: {
                        viewModel.seekForward(seconds: 10)
                    }) {
                        Image(systemName: "goforward.10")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    // PiP Button (if supported)
                    if AVPictureInPictureController.isPictureInPictureSupported() {
                        Button(action: {
                            viewModel.startPiP()
                        }) {
                            Image(systemName: "pip")
                                .font(.system(size: 24))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.7)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }
    
    private var progress: Double {
        guard viewModel.duration > 0 else { return 0 }
        if isDragging {
            return dragValue / viewModel.duration
        }
        return viewModel.currentTime / viewModel.duration
    }
    
    private func formatTime(_ time: Double) -> String {
        guard !time.isNaN && !time.isInfinite else { return "0:00" }
        let totalSeconds = Int(time)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

#Preview {
    ZStack {
        Color.black
        VideoControlsView(viewModel: VideoPlayerViewModel(workout: Workout(
            title: "Test Workout",
            description: "Test",
            category: .strength,
            difficulty: .intermediate,
            duration: 30
        )))
    }
}

