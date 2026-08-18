import Foundation

// MARK: - 音声読み上げ（VoiceOver）

/// VoiceOver の読み上げ設定を行うための共通プロトコル。
public protocol VoiceOverConfigurable {
    /// VoiceOver 用のアクセシビリティ属性の初期設定を行います。
    func setupVoiceOver()
}

// MARK: - 音声コントロール（Voice Control）

/// Voice Control 用の発話キーワードを設定するための共通プロトコル。
public protocol VoiceControlConfigurable {
    /// Voice Control 用のカスタム発話キーワード（UserInputLabels）の初期設定を行います。
    func setupVoiceControl()
}
