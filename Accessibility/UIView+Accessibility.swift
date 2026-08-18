import UIKit
import SwiftUI

// MARK: - UIKit

extension UIView {
    /// VoiceOver（音声読み上げ）用の属性を一括設定。
    /// - Parameters:
    ///   - label: 要素の名前や目的（例: "音量", "閉じる"）。
    ///   - value: 要素の動的な値や状態（例: "50%", "オン"）。不要な場合は `nil`。
    ///   - hint: 要素の「次にどんな操作ができるか」を説明する補助テキスト。不要な場合は `nil`。
    ///   - traits: 要素の役割や状態。ボタンなどの標準読み上げ。（例: `.button`, `.header`）。
    public func configureVoiceOver(
        label: String?,
        value: String? = nil,
        hint: String? = nil,
        traits: UIAccessibilityTraits = .none
    ) {
        self.isAccessibilityElement = true
        self.accessibilityLabel = label
        self.accessibilityValue = value
        self.accessibilityHint = hint
        self.accessibilityTraits = traits
    }
    
    /// Voice Control（音声コントロール）用の発話キーワードを設定。
    /// - Parameter userInputs: Voice Control（音声コントロール）の発話キーワード。不要な場合は `nil`。
    public func configureVoiceControl(userInputs: [String]) {
        self.accessibilityUserInputLabels = userInputs
    }
    
    /// 要素をアクセシビリティ読み上げ対象可否を設定。
    /// - Parameter isHidden: `true` を指定するとアクセシビリティ対象外に設定。
    public func setAccessibilityHidden(_ isHidden: Bool) {
        self.isAccessibilityElement = !isHidden
        self.accessibilityElementsHidden = isHidden
    }
}

// MARK: - SwiftUI

extension View {
    /// VoiceOver（音声読み上げ）用の属性を一括設定。
    /// - Parameters:
    ///   - label: 要素の名前や目的（例: "音量", "閉じる"）。
    ///   - value: 要素の動的な値や状態（例: "50%", "オン"）。不要な場合は `nil`。
    ///   - hint: 要素の「次にどんな操作ができるか」を説明する補助テキスト。不要な場合は `nil`。
    ///   - traits: 要素の役割や状態。ボタンなどの標準読み上げ。（例: `.button`, `.header`）。
    @ViewBuilder
    public func configureVoiceOver(
        label: String?,
        value: String? = nil,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self.accessibilityElement(children: .combine)
            .accessibilityLabel(label ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Voice Control（音声コントロール）用の発話キーワードを設定。
    /// - Parameter userInputs: Voice Control（音声コントロール）の発話キーワード。不要な場合は `nil`。
    @ViewBuilder
    public func configureVoiceControl(userInputs: [String]) -> some View {
        self.accessibilityInputLabels(userInputs)
    }
    
}
