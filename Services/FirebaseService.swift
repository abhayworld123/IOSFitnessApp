import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    
    private var db: Firestore?
    
    private init() {}
    
    func configure() {
        // Firebase will be configured automatically if GoogleService-Info.plist is in the bundle
        // For now, we'll check if Firebase is already configured
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db = Firestore.firestore()
        db?.settings = settings
    }
    
    func getFirestore() -> Firestore? {
        return db
    }
}

