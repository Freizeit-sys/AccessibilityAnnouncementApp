//
//  ViewController.swift
//  AccessibilityApp
//
//  Created by Yuki Morishita on 2026/08/16.
//

import UIKit

class ViewController: UIViewController {
    
    // speech
    @IBOutlet weak var fastwinButton: UIButton!
    @IBOutlet weak var lastwinButton: UIButton!
    @IBOutlet weak var queueButton: UIButton!
    
    // focus
    @IBOutlet weak var fastwinButton2: UIButton!
    @IBOutlet weak var lastwinButton2: UIButton!
    @IBOutlet weak var queueButton2: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        fastwinButton.accessibilityTraits = .none
        lastwinButton.accessibilityTraits = .none
        queueButton.accessibilityTraits = .none
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // speech
    
    @IBAction func fastwin(_ sender: Any) {
        AccessibilityAnnouncementService.shared.announce(AccessibilityAnnouncement.Common.success)
        AccessibilityAnnouncementService.shared.announce(AccessibilityAnnouncement.Common.failure, priority: .FAST_WIN)
    }
    
    @IBAction func lastwin(_ sender: Any) {
        AccessibilityAnnouncementService.shared.announce(AccessibilityAnnouncement.Common.failure)
        AccessibilityAnnouncementService.shared.announce(AccessibilityAnnouncement.Common.success, priority: .LAST_WIN)
    }
    
    @IBAction func queue(_ sender: Any) {
        AccessibilityAnnouncementService.shared.announce(AccessibilityAnnouncement.Common.failure, priority: .QUEUE)
        AccessibilityAnnouncementService.shared.announce(AccessibilityAnnouncement.Common.success, priority: .QUEUE)
    }
    
    
    // focus
    
    @IBAction func fastwin2(_ sender: Any) {
        AccessibilityAnnouncementService.shared.focusOnScreen(lastwinButton2)
        AccessibilityAnnouncementService.shared.focusOnScreen(fastwinButton2, priority: .FAST_WIN)
    }
    
    @IBAction func lastwin2(_ sender: Any) {
        AccessibilityAnnouncementService.shared.focusOnElement(fastwinButton2)
        AccessibilityAnnouncementService.shared.focusOnElement(lastwinButton2, priority: .LAST_WIN)
    }
    
    @IBAction func queue2(_ sender: Any) {
        AccessibilityAnnouncementService.shared.focusOnElement(fastwinButton2, priority: .QUEUE)
        AccessibilityAnnouncementService.shared.focusOnElement(lastwinButton2, priority: .QUEUE)
        AccessibilityAnnouncementService.shared.focusOnElement(queueButton2, priority: .QUEUE)
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
