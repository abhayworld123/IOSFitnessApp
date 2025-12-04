import Foundation
import AVFoundation

class VideoService {
    static let shared = VideoService()
    
    private init() {}
    
    // MARK: - Video URL Management
    
    func getVideoURL(from urlString: String?) -> URL? {
        guard let urlString = urlString, !urlString.isEmpty else {
            return nil
        }
        
        // Check if it's a valid URL
        if let url = URL(string: urlString), url.scheme != nil {
            return url
        }
        
        return nil
    }
    
    // MARK: - Video URL Parsing
    
    func parseVideoURL(_ urlString: String) -> (type: VideoSourceType, id: String?, url: URL?) {
        guard !urlString.isEmpty else {
            return (.directURL, nil, nil)
        }
        
        // Check if it's a YouTube URL
        if let youtubeId = extractYouTubeVideoId(from: urlString) {
            return (.youtube, youtubeId, getYouTubeEmbedURL(videoId: youtubeId))
        }
        
        // Check if it's a Vimeo URL
        if let vimeoId = extractVimeoVideoId(from: urlString) {
            return (.vimeo, vimeoId, getVimeoEmbedURL(videoId: vimeoId))
        }
        
        // Default to direct URL
        if let url = URL(string: urlString), url.scheme != nil {
            return (.directURL, nil, url)
        }
        
        return (.directURL, nil, nil)
    }
    
    // MARK: - YouTube URL Detection and Parsing
    
    func isYouTubeURL(_ url: String) -> Bool {
        return extractYouTubeVideoId(from: url) != nil
    }
    
    func extractYouTubeVideoId(from urlString: String) -> String? {
        let patterns = [
            // youtube.com/watch?v=VIDEO_ID
            "youtube\\.com/watch\\?v=([a-zA-Z0-9_-]{11})",
            // youtu.be/VIDEO_ID
            "youtu\\.be/([a-zA-Z0-9_-]{11})",
            // youtube.com/embed/VIDEO_ID
            "youtube\\.com/embed/([a-zA-Z0-9_-]{11})",
            // youtube.com/v/VIDEO_ID
            "youtube\\.com/v/([a-zA-Z0-9_-]{11})"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(urlString.startIndex..., in: urlString)
                if let match = regex.firstMatch(in: urlString, options: [], range: range),
                   let idRange = Range(match.range(at: 1), in: urlString) {
                    return String(urlString[idRange])
                }
            }
        }
        
        return nil
    }
    
    func getYouTubeEmbedURL(videoId: String) -> URL? {
        let embedURLString = "https://www.youtube.com/embed/\(videoId)?playsinline=1&controls=1&modestbranding=1&rel=0"
        return URL(string: embedURLString)
    }
    
    // MARK: - Vimeo URL Detection and Parsing
    
    func isVimeoURL(_ url: String) -> Bool {
        return extractVimeoVideoId(from: url) != nil
    }
    
    func extractVimeoVideoId(from urlString: String) -> String? {
        let patterns = [
            // vimeo.com/VIDEO_ID
            "vimeo\\.com/(\\d+)",
            // player.vimeo.com/video/VIDEO_ID
            "player\\.vimeo\\.com/video/(\\d+)"
        ]
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(urlString.startIndex..., in: urlString)
                if let match = regex.firstMatch(in: urlString, options: [], range: range),
                   let idRange = Range(match.range(at: 1), in: urlString) {
                    return String(urlString[idRange])
                }
            }
        }
        
        return nil
    }
    
    func getVimeoEmbedURL(videoId: String) -> URL? {
        let embedURLString = "https://player.vimeo.com/video/\(videoId)?autoplay=0&controls=1&title=0&byline=0&portrait=0"
        return URL(string: embedURLString)
    }
    
    // MARK: - Video Validation
    
    func validateVideoURL(_ url: URL) async -> Bool {
        // Check if URL is reachable
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            return false
        }
        return false
    }
    
    // MARK: - HLS Support Check
    
    func isHLSStream(_ url: URL) -> Bool {
        return url.pathExtension == "m3u8" || url.absoluteString.contains(".m3u8")
    }
    
    // MARK: - Sample Video URLs (for development)
    
    static func getSampleVideoURL() -> URL? {
        // Using a sample video URL for testing
        // In production, these would come from Firestore
        return URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")
    }
}

