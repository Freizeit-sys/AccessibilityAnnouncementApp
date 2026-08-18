import UIKit

class ViewController: UIViewController {
    
    // speech
    @IBOutlet weak var fastwinButton: UIButton!
    @IBOutlet weak var lastwinButton: UIButton!
    @IBOutlet weak var queueButton: UIButton!
    
    // focus
    @IBOutlet weak var fastwinButton2: UIButton!
    @IBOutlet weak var lastwinButton2: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fastwinButton.accessibilityTraits = .none
        lastwinButton.accessibilityTraits = .none
        queueButton.accessibilityTraits = .none
        
        fastwinButton2.accessibilityTraits = .none
        lastwinButton2.accessibilityTraits = .none
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // speech
    
    @IBAction func fastwin(_ sender: Any) {
        AccessibilityNotificationService.shared.postAnnouncement(AccessibilityAnnouncement.Common.success)
        AccessibilityNotificationService.shared.postAnnouncement(AccessibilityAnnouncement.Common.failure, priority: .FIRST_WIN)
    }
    
    @IBAction func lastwin(_ sender: Any) {
        AccessibilityNotificationService.shared.postAnnouncement(AccessibilityAnnouncement.Common.failure)
        AccessibilityNotificationService.shared.postAnnouncement(AccessibilityAnnouncement.Common.success, priority: .LAST_WIN)
    }
    
    @IBAction func queue(_ sender: Any) {
        AccessibilityNotificationService.shared.postAnnouncement(AccessibilityAnnouncement.Common.failure, priority: .QUEUE)
        AccessibilityNotificationService.shared.postAnnouncement(AccessibilityAnnouncement.Common.success, priority: .QUEUE)
    }
    
    
    // focus
    
    @IBAction func fastwin2(_ sender: Any) {
        AccessibilityNotificationService.shared.postAnnouncement(AccessibilityAnnouncement.Home.timelineRefreshed)
        AccessibilityNotificationService.shared.postLayoutChange(element: lastwinButton, priority: .FIRST_WIN)
    }
    
    @IBAction func lastwin2(_ sender: Any) {
        AccessibilityNotificationService.shared.postLayoutChange(element: fastwinButton2)
        AccessibilityNotificationService.shared.postLayoutChange(element: lastwinButton2, priority: .LAST_WIN)
    }
    
}

extension ViewController: VoiceOverConfigurable {
    
    func setupVoiceOver() {
        
    }
}

extension ViewController: VoiceControlConfigurable {
    
    func setupVoiceControl() {
        
    }
}
