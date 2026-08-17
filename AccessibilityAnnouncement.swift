import Foundation

/// 音声読み上げメッセージの定義用プロトコル
public protocol AccessibilityAnnouncementMessage {
    var localizedMessage: String { get }
}

/// 音声読み上げメッセージ構造体
public struct AccessibilityAnnouncement: AccessibilityAnnouncementMessage {
    public let localizedMessage: String
    
    private init(_ message: String) {
        self.localizedMessage = message
    }
}

extension AccessibilityAnnouncement {
    /// アプリ全体で使う共通（汎用）メッセージ
    public struct Common {
        public static let success = AccessibilityAnnouncement("成功しました")
        public static let failure = AccessibilityAnnouncement("失敗しました")
    }
    
    /// ホーム画面用のメッセージ
    public struct Home {
        public static let timelineRefreshed = AccessibilityAnnouncement("タイムラインを更新しました")
        public static let profileTabOpened = AccessibilityAnnouncement("プロフィールを表示しました")
        
        // 💡 構造体にすることの最大のメリット：動的な引数（ユーザー名など）を簡単に埋め込める
        public static func welcome(userName: String) -> AccessibilityAnnouncement {
            return AccessibilityAnnouncement("ようこそ、\(userName)さん")
        }
    }
    
    /// 設定画面用のメッセージ
    public struct Setting {
        public static let cacheCleared = AccessibilityAnnouncement("キャッシュを削除しました")
    }
}
