import Foundation
import AVFoundation
import AVKit
import SwiftUI
import Combine
import FirebaseFirestore

@MainActor
class VideoPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playbackRate: Float = 1.0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isBuffering = false
    @Published var showControls = true
    
    var player: AVPlayer?
    var videoSourceType: VideoSourceType = .directURL
    var embedURL: URL?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var playerItem: AVPlayerItem?
    private var pipController: AVPictureInPictureController?
    
    let workout: Workout
    let dayId: String?
    let planViewModel: WorkoutPlanViewModel?
    private let videoService = VideoService.shared
    
    init(workout: Workout, dayId: String? = nil, planViewModel: WorkoutPlanViewModel? = nil) {
        self.workout = workout
        self.dayId = dayId
        self.planViewModel = planViewModel
        setupPlayer()
    }
    
    // MARK: - Player Setup
    
    func setupPlayer() {
        // Check if workout already has videoSourceType set
        if let sourceType = workout.videoSourceType {
            videoSourceType = sourceType
            
            switch sourceType {
            case .youtube:
                if let videoId = workout.videoId ?? extractVideoIdFromURL(workout.videoURL) {
                    embedURL = videoService.getYouTubeEmbedURL(videoId: videoId)
                    isLoading = true
                } else {
                    errorMessage = "Invalid YouTube video ID"
                }
            case .vimeo:
                if let videoId = workout.videoId ?? extractVideoIdFromURL(workout.videoURL) {
                    embedURL = videoService.getVimeoEmbedURL(videoId: videoId)
                    isLoading = true
                } else {
                    errorMessage = "Invalid Vimeo video ID"
                }
            case .directURL:
                setupDirectURLPlayer()
            }
        } else if let videoURLString = workout.videoURL {
            // Parse URL to determine source type
            let parsed = videoService.parseVideoURL(videoURLString)
            videoSourceType = parsed.type
            
            switch parsed.type {
            case .youtube, .vimeo:
                embedURL = parsed.url
                isLoading = true
            case .directURL:
                if let url = parsed.url {
                    loadVideo(url: url)
                } else {
                    // Fallback to sample video
                    if let sampleURL = VideoService.getSampleVideoURL() {
                        loadVideo(url: sampleURL)
                    } else {
                        errorMessage = "No video URL available"
                    }
                }
            }
        } else {
            // No video URL provided, use sample
            if let sampleURL = VideoService.getSampleVideoURL() {
                loadVideo(url: sampleURL)
            } else {
                errorMessage = "No video URL available"
            }
        }
    }
    
    private func setupDirectURLPlayer() {
        guard let videoURL = videoService.getVideoURL(from: workout.videoURL) else {
            // Use sample video if no URL provided
            if let sampleURL = VideoService.getSampleVideoURL() {
                loadVideo(url: sampleURL)
            } else {
                errorMessage = "No video URL available"
            }
            return
        }
        
        loadVideo(url: videoURL)
    }
    
    private func extractVideoIdFromURL(_ urlString: String?) -> String? {
        guard let urlString = urlString else { return nil }
        
        if let youtubeId = videoService.extractYouTubeVideoId(from: urlString) {
            return youtubeId
        }
        
        if let vimeoId = videoService.extractVimeoVideoId(from: urlString) {
            return vimeoId
        }
        
        return nil
    }
    
    func loadVideo(url: URL) {
        isLoading = true
        errorMessage = nil
        
        let asset = AVAsset(url: url)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        
        // Observe player item status
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            // Mark workout as completed when video finishes
            Task { @MainActor in
                await self?.markWorkoutComplete()
            }
        }
        
        // Use Timer to observe status and buffering
        Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updatePlayerStatus()
            }
            .store(in: &cancellables)
        
        // Add time observer
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
        }
        
        // Configure audio session
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        
        // Setup PiP if available
        setupPiP()
    }
    
    // MARK: - Picture-in-Picture
    
    func setupPiP() {
        // PiP setup will be done in the view where we have access to the player layer
        // This is a placeholder that can be called from the view
    }
    
    func setupPiP(with playerLayer: AVPlayerLayer) {
        guard AVPictureInPictureController.isPictureInPictureSupported() else {
            return
        }
        
        // Create PiP controller
        pipController = AVPictureInPictureController(playerLayer: playerLayer)
        pipController?.canStartPictureInPictureAutomaticallyFromInline = true
    }
    
    func startPiP() {
        guard let pipController = pipController,
              pipController.isPictureInPicturePossible else {
            return
        }
        pipController.startPictureInPicture()
    }
    
    func stopPiP() {
        pipController?.stopPictureInPicture()
    }
    
    private func updatePlayerStatus() {
        guard let playerItem = playerItem else { return }
        
        // Update status
        switch playerItem.status {
        case .readyToPlay:
            isLoading = false
            let duration = playerItem.duration
            if duration.isValid && !duration.isIndefinite {
                self.duration = duration.seconds
            }
        case .failed:
            isLoading = false
            errorMessage = playerItem.error?.localizedDescription ?? "Failed to load video"
        case .unknown:
            isLoading = true
        @unknown default:
            break
        }
        
        // Update buffering state
        isBuffering = !playerItem.isPlaybackLikelyToKeepUp
    }
    
    // MARK: - Playback Controls
    
    func play() {
        player?.play()
        player?.rate = playbackRate
        isPlaying = true
        HapticFeedback.impact(style: .light)
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        HapticFeedback.impact(style: .light)
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = time
    }
    
    func seekForward(seconds: Double = 10) {
        let newTime = min(currentTime + seconds, duration)
        seek(to: newTime)
        HapticFeedback.impact(style: .light)
    }
    
    func seekBackward(seconds: Double = 10) {
        let newTime = max(currentTime - seconds, 0)
        seek(to: newTime)
        HapticFeedback.impact(style: .light)
    }
    
    func setPlaybackRate(_ rate: Float) {
        playbackRate = rate
        if isPlaying {
            player?.rate = rate
        }
        HapticFeedback.impact(style: .light)
    }
    
    // MARK: - Progress Tracking
    
    func saveProgress() async {
        // Skip progress tracking for web videos (YouTube/Vimeo) as we can't accurately track time
        guard videoSourceType == .directURL else { return }
        guard let userId = AuthService.shared.getCurrentAuthUser()?.uid else { return }
        
        let progress: [String: Any] = [
            "workoutId": workout.id,
            "progress": duration > 0 ? currentTime / duration : 0,
            "currentTime": currentTime,
            "duration": duration,
            "lastUpdated": Timestamp(date: Date())
        ]
        
        do {
            let db = Firestore.firestore()
            try await db.collection("userProgress")
                .document(userId)
                .collection("completedWorkouts")
                .document(workout.id)
                .setData(progress, merge: true)
        } catch {
            print("Failed to save progress: \(error.localizedDescription)")
        }
    }
    
    func loadProgress() async {
        // Skip progress loading for web videos (YouTube/Vimeo) as we can't accurately seek
        guard videoSourceType == .directURL else { return }
        guard let userId = AuthService.shared.getCurrentAuthUser()?.uid else { return }
        
        do {
            let db = Firestore.firestore()
            let document = try await db.collection("userProgress")
                .document(userId)
                .collection("completedWorkouts")
                .document(workout.id)
                .getDocument()
            
            if let data = document.data(),
               let currentTime = data["currentTime"] as? Double,
               let duration = data["duration"] as? Double,
               duration > 0 {
                // Resume from last position if less than 90% complete
                if currentTime / duration < 0.9 {
                    seek(to: currentTime)
                }
            }
        } catch {
            print("Failed to load progress: \(error.localizedDescription)")
        }
    }
    
    func markWorkoutComplete() async {
        guard let userId = AuthService.shared.getCurrentAuthUser()?.uid else { return }
        
        // For web videos, use workout duration as estimated duration
        let finalDuration = videoSourceType == .directURL && duration > 0 ? duration : Double(workout.duration * 60)
        
        let progress: [String: Any] = [
            "workoutId": workout.id,
            "completed": true,
            "completedDate": Timestamp(date: Date()),
            "progress": 1.0,
            "currentTime": finalDuration,
            "duration": finalDuration,
            "lastUpdated": Timestamp(date: Date())
        ]
        
        do {
            let db = Firestore.firestore()
            try await db.collection("userProgress")
                .document(userId)
                .collection("completedWorkouts")
                .document(workout.id)
                .setData(progress, merge: true)
            
            // If this workout is part of a plan, mark the day as complete
            if let dayId = dayId, let planViewModel = planViewModel {
                await planViewModel.markWorkoutComplete(dayId: dayId)
            }
        } catch {
            print("Failed to mark workout as complete: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
        stopPiP()
        pipController = nil
        player?.pause()
        player = nil
        playerItem = nil
        
        // Deactivate audio session
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    
    // Note: No deinit needed - cleanup() is called explicitly from view's onDisappear
    // Having a deinit in a @MainActor class would require experimental Swift features
}

