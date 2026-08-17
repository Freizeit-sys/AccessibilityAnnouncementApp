import UIKit
import Combine

/// 音声読み上げの優先度定義
public enum AccessibilityAnnouncementPriority {
    /// 先勝ち（新しい読み上げを破棄するモード）
    case FAST_WIN
    /// 後勝ち（現在の読み上げを中断し、新しいメッセージを即座に読み上げ。iOSデフォルト）
    case LAST_WIN
    /// 後回し（現在の読み上げ完了を待機し順番に読み上げ）
    case QUEUE
}

/// アクセシビリティ音声アナウンスサービスが準拠する共通プロトコル。
public protocol AccessibilityAnnouncementServiceProtocol: AnyObject {
    /// VoiceOverが現在実行中であるかどうかを示すフラグ
    var isVoiceOverRunning: Bool { get }
    /// 指定された優先度に基づいて、VoiceOverによる音声読み上げを実行します。
    /// - Parameters:
    ///   - messageDefinition: 読み上げるメッセージの定義
    ///   - priority: 読み上げの優先度（デフォルトは `.LAST_WIN`）
    func announce<T: AccessibilityAnnouncementMessage>(_ messageDefinition: T, priority: AccessibilityAnnouncementPriority)
    /// 指定された優先度に基づいて、特定のUI要素にVoiceOverのフォーカスを強制移動させます。
    /// - Parameters:
    ///   - element: フォーカスを当てたいターゲット要素（UIViewやアクセシビリティ要素）
    ///   - priority: 読み上げの優先度（デフォルトは `.LAST_WIN`）
    func focusOnElement(_ element: Any?, priority: AccessibilityAnnouncementPriority)
    /// 指定された優先度に基づいて、特定のUI要素にVoiceOverのフォーカスを強制移動させます。
    /// - Parameters:
    ///   - element: フォーカスを当てたいターゲット要素（UIViewやアクセシビリティ要素）
    ///   - priority: 読み上げの優先度（デフォルトは `.LAST_WIN`）
    func focusOnScreen(_ element: Any?, priority: AccessibilityAnnouncementPriority)
}

/// VoiceOverの音声読み上げおよびフォーカス移動を包括的に管理するシングルトンクラス。
/// SwiftUIの `@ObservedObject` や `@StateObject` としてバインド可能なように `ObservableObject` に準拠。
@MainActor
public final class AccessibilityAnnouncementService: ObservableObject {
    
    // MARK: - Public Properties
    
    public static let shared = AccessibilityAnnouncementService()
    @Published public var isVoiceOverRunning: Bool = UIAccessibility.isVoiceOverRunning
    
    // MARK: - Private Properties
    
    /// 音声読み上げの競合を防ぐためのデフォルト遅延時間（秒）
    private let speechPostDelay: TimeInterval = 0.2
    /// フォーカス移動時の競合を防ぐためのデフォルト遅延時間（秒）
    private let focusPostDelay: TimeInterval = 0.2
    /// 音声読み上げ制御の衝突判定用フラグを追加
    private var isCurrentSpeaking: Bool = false
    /// フォーカス制御の衝突判定用フラグを追加
    private var isCurrentFocusing: Bool = false
    
    private var cancellables: Set<AnyCancellable> = []
    
    // MARK: - Internal Properties
    
    internal var notificationPoster: (UIAccessibility.Notification, Any?) -> Void = UIAccessibility.post(notification:argument:)
    
    // MARK: - Lifecycle
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    public func clear() {
        isCurrentSpeaking = false
        isCurrentFocusing = false
        notificationPoster = UIAccessibility.post(notification:argument:)
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        //  VoiceOverの状態変更通知
        NotificationCenter.default.publisher(for: UIAccessibility.voiceOverStatusDidChangeNotification)
            .sink { [weak self] _ in self?.isVoiceOverRunning = UIAccessibility.isVoiceOverRunning }
            .store(in: &cancellables)
        // 音声読み上げ完了通知
        NotificationCenter.default.publisher(for: UIAccessibility.announcementDidFinishNotification)
            .sink { [weak self] _ in
                print("finish annoucement")
                self?.isCurrentSpeaking = false
            }
            .store(in: &cancellables)
        // レイアウト変更（フォーカス）完了通知をフック
        NotificationCenter.default.publisher(for: UIAccessibility.elementFocusedNotification)
            .sink { [weak self] _ in
                print("finish focused")
                self?.isCurrentFocusing = false
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods (OS Version Routing)
    
    // 通常（即時割り込み・上書き）のアナウンスメントをOSに送信。
    /// - Parameter message: 読み上げるプレーンテキスト文字列
    private func postDefaultAnnouncement(message: String) {
        if #available(iOS 17.0, *) {
            let attributedString = AttributedString(message)
            AccessibilityNotification.Announcement(attributedString).post()
        } else {
            notificationPoster(.announcement, message)
        }
    }
    
    /// 順番待ち（キューイング）を指示するアナウンスメントをOSに送信。
    /// - Parameter message: 順番待ちキューに追加するプレーンテキスト文字列
    private func postQueueableAnnouncement(message: String) {
        if #available(iOS 17.0, *) {
            var attributedString = AttributedString(message)
            attributedString.accessibilitySpeechAnnouncementPriority = .low
            AccessibilityNotification.Announcement(attributedString).post()
        } else {
            let attributedString = NSAttributedString(
                string: message,
                attributes: [.accessibilitySpeechQueueAnnouncement: true]
            )
            notificationPoster(.announcement, attributedString)
        }
    }
}

extension AccessibilityAnnouncementService: AccessibilityAnnouncementServiceProtocol {
    /// 指定された優先度に基づいて、VoiceOverによる音声読み上げを実行します。
    ///
    /// - `.QUEUE` モードは 通知の音声読み上げキューです。フォーカスなどによるシステムの音声読み上げと重複する場合、中断上書きされます。
    ///
    /// - Parameters:
    ///   - messageDefinition: 読み上げるメッセージ（`AccessibilitySpeechMessagesDefinition` 準拠）
    ///   - priority: 読み上げの挙動を制御する優先度。デフォルトは `.LAST_WIN`（後勝ち）です。iOSのデフォルト挙動。
    public func announce<T: AccessibilityAnnouncementMessage>(_ messageDefinition: T, priority: AccessibilityAnnouncementPriority = .LAST_WIN) {
        guard isVoiceOverRunning else { return }
        
        let localizedMessage = messageDefinition.localizedMessage
                
        DispatchQueue.main.asyncAfter(deadline: .now() + speechPostDelay) { [weak self] in
            guard let self = self else { return }
            
            switch priority {
            case .FAST_WIN:
                print("voice over fast win: \(localizedMessage)")
                if isCurrentSpeaking { print("cancel"); return }
                postDefaultAnnouncement(message: localizedMessage)
                
            case .LAST_WIN:
                print("voice over last win: \(localizedMessage)")
                isCurrentSpeaking = true
                postDefaultAnnouncement(message: localizedMessage)
                
            case .QUEUE:
                print("voice over queue: \(localizedMessage)")
                isCurrentSpeaking = true
                postQueueableAnnouncement(message: localizedMessage)
            }
        }
    }
    
    /// 指定された優先度に基づいて、特定のUI要素にVoiceOverのフォーカスを強制移動させます。
    /// タブの切り替え、ポップオーバー、要素の動的追加（通知時にシステム音は鳴らない）
    /// - Parameters:
    ///   - element: フォーカスを当てる対象（UIViewやUIAccessibilityElement）
    ///   - priority: フォーカス移動の優先度。デフォルトは `.LAST_WIN`（後勝ち）です。
    public func focusOnElement(_ element: Any?, priority: AccessibilityAnnouncementPriority = .LAST_WIN) {
        guard isVoiceOverRunning, let element = element else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + focusPostDelay) { [weak self] in
            guard let self = self else { return }
            
            switch priority {
            case .FAST_WIN:
                print("focus: fast win")
                if isCurrentFocusing || isCurrentSpeaking { print("focus cancel"); return }
                isCurrentFocusing = true
                notificationPoster(.layoutChanged, element)
                
            case .LAST_WIN:
                print("focus: last win")
                isCurrentFocusing = true
                notificationPoster(.layoutChanged, element)
                
            case .QUEUE:
                print("focus: queue")
                return
            }
        }
    }
    
    /// 指定された優先度に基づいて、特定のUI要素にVoiceOverのフォーカスを強制移動させます。
    /// モーダル表示、画面遷移など画面全体の変化、スイッチ（通知時にシステム音が鳴る）
    /// - Parameters:
    ///   - element: フォーカスを当てる対象（UIViewやUIAccessibilityElement、自動判定はnil）
    ///   - priority: フォーカス移動の優先度。デフォルトは `.LAST_WIN`（後勝ち）です。
    public func focusOnScreen(_ element: Any?, priority: AccessibilityAnnouncementPriority = .LAST_WIN) {
        guard isVoiceOverRunning else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + focusPostDelay) { [weak self] in
            guard let self = self else { return }
            
            switch priority {
            case .FAST_WIN:
                print("focusOnScreen: fast win")
                if isCurrentFocusing || isCurrentSpeaking { print("focusOnScreen cancel"); return }
                isCurrentFocusing = true
                notificationPoster(.screenChanged, element)
                
            case .LAST_WIN:
                print("focusOnScreen: last win")
                isCurrentFocusing = true
                notificationPoster(.screenChanged, element)
                
            case .QUEUE:
                print("focusOnScreen: queue")
                return
            }
        }
    }
}
