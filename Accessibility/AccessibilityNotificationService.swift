import UIKit
import Combine

/// 音声読み上げの優先度定義
public enum AccessibilityAnnouncementPriority {
    /// 先勝ち（新しい読み上げを破棄するモード）
    case FIRST_WIN
    /// 後勝ち（現在の読み上げを中断し、新しいメッセージを即座に読み上げ。iOSデフォルト）
    case LAST_WIN
    /// 後回し（現在の読み上げ完了を待機し順番に読み上げ）
    case QUEUE
}

/// フォーカスの優先度定義
public enum AccessibilityFocusPriority {
    /// 先勝ち（新しい読み上げを破棄するモード）
    case FIRST_WIN
    /// 後勝ち（現在の読み上げを中断し、新しいメッセージを即座に読み上げ。iOSデフォルト）
    case LAST_WIN
}

public protocol AccessibilityNotificationServiceProtocol: AnyObject {
    /// VoiceOverが現在実行中であるかどうかを示すフラグ
    var isVoiceOverRunning: Bool { get }
    /// 指定された優先度に基づいて、VoiceOverによる音声読み上げを実行します。
    /// - Parameters:
    ///   - messageDefinition: 読み上げるメッセージの定義
    ///   - priority: 読み上げの優先度（デフォルトは `.LAST_WIN`）
    func postAnnouncement<T: AccessibilityAnnouncementMessage>(_ messageDefinition: T, priority: AccessibilityAnnouncementPriority)
    /// 指定された優先度に基づいて、特定のUI要素にVoiceOverのフォーカスを強制移動させます。
    /// - Parameters:
    ///   - element: フォーカスを当てたいターゲット要素（UIViewやアクセシビリティ要素）
    ///   - priority: 読み上げの優先度（デフォルトは `.LAST_WIN`）
    func postLayoutChange(element: Any?, priority: AccessibilityFocusPriority)
    /// 指定された優先度に基づいて、特定のUI要素にVoiceOverのフォーカスを強制移動させます。
    /// - Parameters:
    ///   - element: フォーカスを当てたいターゲット要素（UIViewやアクセシビリティ要素）
    ///   - priority: 読み上げの優先度（デフォルトは `.LAST_WIN`）
    func postScreenChange(element: Any?, priority: AccessibilityFocusPriority)
}

@MainActor
public final class AccessibilityNotificationService: ObservableObject {
    
    public static let shared = AccessibilityNotificationService()
    
    @Published public var isVoiceOverRunning: Bool = UIAccessibility.isVoiceOverRunning
    
    /// 音声読み上げの競合を防ぐためのデフォルト遅延時間（秒）
    private let announcePostDelay: TimeInterval = 0.2
    /// フォーカス移動時の競合を防ぐためのデフォルト遅延時間（秒）
    private let focusPostDelay: TimeInterval = 0.1
    
    /// 音声読み上げ制御の衝突判定用フラグ
    private var isCurrentSpeaking: Bool = false
    /// フォーカス制御の衝突判定用フラグ
    private var isCurrentFocusing: Bool = false
    
    private var cancellables: Set<AnyCancellable> = []
    
    internal enum iOS17AccessibilityNotification {
        case announcement(AttributedString)
        case layoutChanged(Any?)
        case screenChanged(Any?)
    }
    
    @available(iOS 17.0, *)
    internal var iOS17NotificationPoster: (iOS17AccessibilityNotification) -> Void = { notification in
        switch notification {
        case let .announcement(message):
            AccessibilityNotification.Announcement(message).post()
            
        case let .layoutChanged(element):
            AccessibilityNotification.LayoutChanged(element).post()
            
        case let .screenChanged(element):
            AccessibilityNotification.ScreenChanged(element).post()
        }
    }
    
    internal var legacyNotificationPoster: (UIAccessibility.Notification, Any?) -> Void = UIAccessibility.post(notification:argument:)
    
#if DEBUG
    internal func clear() {
        isCurrentSpeaking = false
        isCurrentFocusing = false
    }
#endif
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        //  VoiceOverの状態変更通知
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning
                }
            }
            .store(in: &cancellables)
        // 音声読み上げ完了通知
        NotificationCenter.default.publisher(for: UIAccessibility.announcementDidFinishNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.isCurrentSpeaking = false
                    print("finish annouce")
                }
            }
            .store(in: &cancellables)
        // フォーカス移動完了通知
        NotificationCenter.default.publisher(for: UIAccessibility.elementFocusedNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.isCurrentFocusing = false
                    print("finish focused")
                }
            }
            .store(in: &cancellables)
    }
    
    private func postDefaultAnnouncement(message: String) {
        if #available(iOS 17.0, *) {
            let attributedString = AttributedString(message)
            iOS17NotificationPoster(.announcement(attributedString))
        } else {
            legacyNotificationPoster(.announcement, message)
        }
    }
    
    private func postQueueableAnnouncement(message: String) {
        if #available(iOS 17.0, *) {
            var attributedString = AttributedString(message)
            attributedString.accessibilitySpeechAnnouncementPriority = .low
            iOS17NotificationPoster(.announcement(attributedString))
        } else {
            let attributedString = NSAttributedString(
                string: message,
                attributes: [.accessibilitySpeechQueueAnnouncement: true]
            )
            legacyNotificationPoster(.announcement, attributedString)
        }
    }
    
    private func postLayoutChange(element: Any?) {
        if #available(iOS 17.0, *) {
            iOS17NotificationPoster(.layoutChanged(element))
        } else {
            legacyNotificationPoster(.layoutChanged, element)
        }
    }
    
    private func postScreenChange(element: Any?) {
        if #available(iOS 17.0, *) {
            iOS17NotificationPoster(.screenChanged(element))
        } else {
            legacyNotificationPoster(.screenChanged, element)
        }
    }
    
}

extension AccessibilityNotificationService: AccessibilityNotificationServiceProtocol {
    
    public func postAnnouncement<T: AccessibilityAnnouncementMessage>(_ messageDefinition: T, priority: AccessibilityAnnouncementPriority = .LAST_WIN) {
        guard isVoiceOverRunning else { return }
        
        let localizedMessage = messageDefinition.localizedMessage
        
        DispatchQueue.main.asyncAfter(deadline: .now() + announcePostDelay) { [weak self] in
            guard let self = self else { return }
            
            switch priority {
            case .FIRST_WIN:
                if isCurrentSpeaking { return }
                isCurrentSpeaking = true
                postDefaultAnnouncement(message: localizedMessage)
                
            case .LAST_WIN:
                isCurrentSpeaking = true
                postDefaultAnnouncement(message: localizedMessage)
                
            case .QUEUE:
                isCurrentSpeaking = true
                postQueueableAnnouncement(message: localizedMessage)
            }
        }
    }
    
    public func postLayoutChange(element: Any?, priority: AccessibilityFocusPriority = .LAST_WIN) {
        guard isVoiceOverRunning, let element = element else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + focusPostDelay) { [weak self] in
            guard let self = self else { return }
            
            switch priority {
            case .FIRST_WIN:
                if isCurrentFocusing || isCurrentSpeaking { return }
                isCurrentFocusing = true
                postLayoutChange(element: element)
                
            case .LAST_WIN:
                isCurrentFocusing = true
                postLayoutChange(element: element)
            }
        }
    }
    
    public func postScreenChange(element: Any?, priority: AccessibilityFocusPriority = .LAST_WIN) {
        guard isVoiceOverRunning else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + focusPostDelay) { [weak self] in
            guard let self = self else { return }
            
            switch priority {
            case .FIRST_WIN:
                if isCurrentFocusing || isCurrentSpeaking { return }
                isCurrentFocusing = true
                postScreenChange(element: element)
                
            case .LAST_WIN:
                isCurrentFocusing = true
                postScreenChange(element: element)
            }
        }
    }
    
}
