import XCTest

@testable import AccessibilityApp

@MainActor
final class AccessibilityNotificationServiceTests: XCTestCase {

    private var service: AccessibilityNotificationService!
    private var postedNotifications: [AccessibilityNotificationService.iOS17AccessibilityNotification] = []

    override func setUp() {
        super.setUp()

        service = AccessibilityNotificationService.shared
        service.clear()
        service.isVoiceOverRunning = true
        service.iOS17NotificationPoster = { [weak self] notification in
            self?.postedNotifications.append(notification)
        }
    }

    override func tearDown() {
        service.clear()
        postedNotifications = []
        service = nil
        super.tearDown()
    }

    func test_postAnnouncement_with_lastWin_posts_an_announcement() async {
        service.postAnnouncement(AccessibilityAnnouncement.Common.success)

        await waitForAnnouncement()

        guard case let .announcement(message)? = postedNotifications.first else {
            return XCTFail("アナウンスが投稿されていません")
        }

        XCTAssertEqual(String(message.characters), "成功しました")
    }

    func test_postAnnouncement_with_queue_posts_a_low_priority_announcement() async {
        service.postAnnouncement(AccessibilityAnnouncement.Common.success, priority: .QUEUE)

        await waitForAnnouncement()

        guard case let .announcement(message)? = postedNotifications.first else {
            return XCTFail("アナウンスが投稿されていません")
        }

        XCTAssertEqual(message.accessibilitySpeechAnnouncementPriority, .low)
    }

    func test_postAnnouncement_with_firstWin_ignores_a_request_while_speaking() async {
        service.postAnnouncement(AccessibilityAnnouncement.Common.success, priority: .LAST_WIN)
        await waitForAnnouncement()

        service.postAnnouncement(AccessibilityAnnouncement.Common.failure, priority: .FIRST_WIN)
        await waitForAnnouncement()

        XCTAssertEqual(postedNotifications.count, 1)
    }

    func test_postAnnouncement_does_not_post_when_voiceOver_is_not_running() async {
        service.isVoiceOverRunning = false
        service.postAnnouncement(AccessibilityAnnouncement.Common.success)

        await waitForAnnouncement()

        XCTAssertTrue(postedNotifications.isEmpty)
    }

    func test_postLayoutChange_with_lastWin_posts_the_element() async {
        let element = NSObject()
        service.postLayoutChange(element: element)

        await waitForFocus()

        guard case let .layoutChanged(postedElement)? = postedNotifications.first else {
            return XCTFail("レイアウト変更が投稿されていません")
        }

        XCTAssertTrue((postedElement as AnyObject?) === element)
    }

    func test_postLayoutChange_with_firstWin_ignores_a_request_while_focusing() async {
        service.postLayoutChange(element: NSObject(), priority: .LAST_WIN)
        await waitForFocus()

        service.postLayoutChange(element: NSObject(), priority: .FIRST_WIN)
        await waitForFocus()

        XCTAssertEqual(postedNotifications.count, 1)
    }

    func test_postScreenChange_with_lastWin_posts_the_element() async {
        let element = NSObject()
        service.postScreenChange(element: element)

        await waitForFocus()

        guard case let .screenChanged(postedElement)? = postedNotifications.first else {
            return XCTFail("画面変更が投稿されていません")
        }

        XCTAssertTrue((postedElement as AnyObject?) === element)
    }

    func test_postScreenChange_with_firstWin_ignores_a_request_while_speaking() async {
        service.postAnnouncement(AccessibilityAnnouncement.Common.success, priority: .LAST_WIN)
        await waitForAnnouncement()

        service.postScreenChange(element: NSObject(), priority: .FIRST_WIN)
        await waitForFocus()

        XCTAssertEqual(postedNotifications.count, 1)
    }

    func test_postLayoutChange_does_not_post_without_an_element() async {
        service.postLayoutChange(element: nil)

        await waitForFocus()

        XCTAssertTrue(postedNotifications.isEmpty)
    }

    private func waitForAnnouncement() async {
        try? await Task.sleep(for: .milliseconds(250))
    }

    private func waitForFocus() async {
        try? await Task.sleep(for: .milliseconds(150))
    }
}
