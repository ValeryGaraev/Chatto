//
// Copyright (c) Badoo Trading Limited, 2010-present. All rights reserved.
//

import Foundation
import UIKit

public enum KeyboardState {
    case hiding
    case hidden
    case showing
    case shown
}

public struct KeyboardStatus {
    public let keyboardFrame: CGRect
    public let state: KeyboardState

    public init(keyboardFrame: CGRect,
                state: KeyboardState) {
        self.keyboardFrame = keyboardFrame
        self.state = state
    }
}

public protocol KeyboardTrackerDelegate: AnyObject {
    func keyboardTracker(_ : KeyboardTrackerProtocol,
                         didUpdateTo: KeyboardStatus)
}

public protocol KeyboardTrackerProtocol: AnyObject {
    var keyboardStatus: KeyboardStatus { get }
    var delegate: KeyboardTrackerDelegate? { get set }
}

public final class KeyboardTracker: KeyboardTrackerProtocol {

    private let notificationCenter: NotificationCenter

    public weak var delegate: KeyboardTrackerDelegate?

    public private(set) var keyboardStatus: KeyboardStatus = .init(keyboardFrame: .zero, state: .hidden) {
        didSet {
            self.delegate?.keyboardTracker(self, didUpdateTo: self.keyboardStatus)
        }
    }

    public init(notificationCenter: NotificationCenter) {
        self.notificationCenter = notificationCenter

        self.setupNotifications()
    }

    private func setupNotifications() {
        self.notificationCenter.addObserver(
            self,
            selector: #selector(KeyboardTracker.keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        self.notificationCenter.addObserver(
            self,
            selector: #selector(KeyboardTracker.keyboardDidShow(_:)),
            name: UIResponder.keyboardDidShowNotification,
            object: nil
        )
        self.notificationCenter.addObserver(
            self,
            selector: #selector(KeyboardTracker.keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        self.notificationCenter.addObserver(
            self,
            selector: #selector(KeyboardTracker.keyboardDidHide(_:)),
            name: UIResponder.keyboardDidHideNotification,
            object: nil
        )
        self.notificationCenter.addObserver(
            self,
            selector: #selector(KeyboardTracker.keyboardWillChangeFrame(_:)),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )
    }

    @objc
    private func keyboardWillShow(_ notification: Notification) {
        let keyboardFrame = self.keyboardFrame(from: notification)
        guard keyboardFrame.height > 0 else { return } // Some keyboards may report initial willShow/DidShow notifications with invalid positions
        self.keyboardStatus = .init(keyboardFrame: keyboardFrame, state: .showing)
    }

    @objc
    private func keyboardDidShow(_ notification: Notification) {
        let keyboardFrame = self.keyboardFrame(from: notification)
        guard keyboardFrame.height > 0 else { return }  // Some keyboards may report initial willShow/DidShow notifications with invalid positions

        self.keyboardStatus = .init(keyboardFrame: keyboardFrame, state: .shown)
    }

    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        let keyboardFrame = self.keyboardFrame(from: notification)
        guard keyboardFrame.height == 0 else { return }

        self.keyboardStatus = .init(keyboardFrame: keyboardFrame, state: .hiding)
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        let keyboardFrame = self.keyboardFrame(from: notification)
        self.keyboardStatus = .init(keyboardFrame: keyboardFrame, state: .hiding)
    }

    @objc
    private func keyboardDidHide(_ notification: Notification) {
        let keyboardFrame = self.keyboardFrame(from: notification)
        self.keyboardStatus = .init(keyboardFrame: keyboardFrame, state: .hidden)
    }

    private func keyboardFrame(from notification: Notification) -> CGRect {
        let userInfo = (notification as NSNotification).userInfo
        let keyboardFrameEndUserInfo = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue

        return keyboardFrameEndUserInfo?.cgRectValue ?? .zero
    }
}
