import XCTest

@testable import AccessibilityApp

@MainActor
final class AccessibilityAnnouncementServiceTests: XCTestCase {
    
    var service: AccessibilityAnnouncementService?
    var postedNotification: UIAccessibility.Notification?
    var postedArgument: Any?
    
    override func setUp() {
        super.setUp()
        
        let shared = AccessibilityAnnouncementService.shared
        
        shared.notificationPoster = { [weak self] notification, argument in
            self?.postedNotification = notification
            self?.postedArgument = argument
        }
        
        self.service = shared
    }
    
    override func tearDown() {
        service?.clear()
        service = nil
        postedNotification = nil
        postedArgument = nil
        super.tearDown()
    }

    func test_announce_with_queue_priority_attaches_attribute() {
        guard let service = service else {
            XCTFail("サービスの初期化に失敗しています")
            return
        }
        let localizedMessage = AccessibilityAnnouncement.Common.success
        
        // When
        service.announce(localizedMessage, priority: .QUEUE)
        
        // Then
        XCTAssertEqual(postedNotification, .announcement)
        
        if let attributedString = postedArgument as? NSAttributedString {
            let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
            let isQueued = attributes[.accessibilitySpeechQueueAnnouncement] as? Bool
            XCTAssertEqual(isQueued, true, "後回し（queue）時は、この値がtrueである必要があります")
        } else {
            XCTFail("queue指定時はNSAttributedStringでポストされる必要があります")
        }
    }
}
