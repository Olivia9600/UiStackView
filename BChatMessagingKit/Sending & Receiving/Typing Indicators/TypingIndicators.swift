//
//  Copyright (c) 2018 Open Whisper Systems. All rights reserved.
//

import Foundation

@objc(OWSTypingIndicators)
public protocol TypingIndicators : AnyObject {

    @objc
    func didStartTypingOutgoingInput(inThread thread: TSThread)

    @objc
    func didStopTypingOutgoingInput(inThread thread: TSThread)

    @objc
    func didSendOutgoingMessage(inThread thread: TSThread)

    @objc
    func didReceiveTypingStartedMessage(inThread thread: TSThread, recipientId: String, deviceId: UInt)

    @objc
    func didReceiveTypingStoppedMessage(inThread thread: TSThread, recipientId: String, deviceId: UInt)

    @objc
    func didReceiveIncomingMessage(inThread thread: TSThread, recipientId: String, deviceId: UInt)

    // Returns the recipient id of the user who should currently be shown typing for a given thread.
    //
    // If no one is typing in that thread, returns nil.
    // If multiple users are typing in that thread, returns the user to show.
    //
    // TODO: Use this method.
    @objc
    func typingRecipientId(forThread thread: TSThread) -> String?

    @objc
    func setTypingIndicatorsEnabled(value: Bool)

    @objc
    func areTypingIndicatorsEnabled() -> Bool
}

// MARK: -

@objc(OWSTypingIndicatorsImpl)
public class TypingIndicatorsImpl : NSObject, TypingIndicators {

    @objc
    public static let typingIndicatorStateDidChange = Notification.Name("typingIndicatorStateDidChange")

    private let kDatabaseCollection = "TypingIndicators"
    private let kDatabaseKey_TypingIndicatorsEnabled = "kDatabaseKey_TypingIndicatorsEnabled"

    private var _areTypingIndicatorsEnabled = false

    public override init() {
        super.init()

        AppReadiness.runNowOrWhenAppWillBecomeReady {
            self.setup()
        }
    }

    private func setup() {
        _areTypingIndicatorsEnabled = OWSPrimaryStorage.shared().dbReadConnection.bool(forKey: kDatabaseKey_TypingIndicatorsEnabled, inCollection: kDatabaseCollection, defaultValue: false)
    }

    // MARK: -

    @objc
    public func setTypingIndicatorsEnabled(value: Bool) {
        _areTypingIndicatorsEnabled = value

        OWSPrimaryStorage.shared().dbReadWriteConnection.setBool(value, forKey: kDatabaseKey_TypingIndicatorsEnabled, inCollection: kDatabaseCollection)

        NotificationCenter.default.postNotificationNameAsync(TypingIndicatorsImpl.typingIndicatorStateDidChange, object: nil)
    }

    @objc
    public func areTypingIndicatorsEnabled() -> Bool {
        return _areTypingIndicatorsEnabled
    }

    // MARK: -

    @objc
    public func didStartTypingOutgoingInput(inThread thread: TSThread) {
        guard let outgoingIndicators = ensureOutgoingIndicators(forThread: thread), !thread.isMessageRequest() else {
            return
        }
        outgoingIndicators.didStartTypingOutgoingInput()
    }

    @objc
    public func didStopTypingOutgoingInput(inThread thread: TSThread) {
        guard let outgoingIndicators = ensureOutgoingIndicators(forThread: thread), !thread.isMessageRequest() else {
            return
        }
        outgoingIndicators.didStopTypingOutgoingInput()
    }

    @objc
    public func didSendOutgoingMessage(inThread thread: TSThread) {
        guard let outgoingIndicators = ensureOutgoingIndicators(forThread: thread) else {
            return
        }
        outgoingIndicators.didSendOutgoingMessage()
    }

    @objc
    public func didReceiveTypingStartedMessage(inThread thread: TSThread, recipientId: String, deviceId: UInt) {
        let incomingIndicators = ensureIncomingIndicators(forThread: thread, recipientId: recipientId, deviceId: deviceId)
        incomingIndicators.didReceiveTypingStartedMessage()
    }

    @objc
    public func didReceiveTypingStoppedMessage(inThread thread: TSThread, recipientId: String, deviceId: UInt) {
        let incomingIndicators = ensureIncomingIndicators(forThread: thread, recipientId: recipientId, deviceId: deviceId)
        incomingIndicators.didReceiveTypingStoppedMessage()
    }

    @objc
    public func didReceiveIncomingMessage(inThread thread: TSThread, recipientId: String, deviceId: UInt) {
        let incomingIndicators = ensureIncomingIndicators(forThread: thread, recipientId: recipientId, deviceId: deviceId)
        incomingIndicators.didReceiveIncomingMessage()
    }

    @objc
    public func typingRecipientId(forThread thread: TSThread) -> String? {
        guard areTypingIndicatorsEnabled() else {
            return nil
        }

        var firstRecipientId: String?
        var firstTimestamp: UInt64?

        let threadKey = incomingIndicatorsKey(forThread: thread)
        guard let deviceMap = incomingIndicatorsMap[threadKey] else {
            // No devices are typing in this thread.
            return nil
        }
        for incomingIndicators in deviceMap.values {
            guard incomingIndicators.isTyping else {
                continue
            }
            guard let startedTypingTimestamp = incomingIndicators.startedTypingTimestamp else {
                continue
            }
            if let firstTimestamp = firstTimestamp,
                firstTimestamp < startedTypingTimestamp {
                // More than one recipient/device is typing in this conversation;
                // prefer the one that started typing first.
                continue
            }
            firstRecipientId = incomingIndicators.recipientId
            firstTimestamp = startedTypingTimestamp
        }
        return firstRecipientId
    }

    // MARK: -

    // Map of thread id-to-OutgoingIndicators.
    private var outgoingIndicatorsMap = [String: OutgoingIndicators]()

    private func ensureOutgoingIndicators(forThread thread: TSThread) -> OutgoingIndicators? {
        guard let threadId = thread.uniqueId else {
            return nil
        }
        if let outgoingIndicators = outgoingIndicatorsMap[threadId] {
            return outgoingIndicators
        }
        let outgoingIndicators = OutgoingIndicators(delegate: self, thread: thread)
        outgoingIndicatorsMap[threadId] = outgoingIndicators
        return outgoingIndicators
    }

    // The sender maintains two timers per chat:
    //
    // A sendPause timer
    // A sendRefresh timer
    private class OutgoingIndicators {
        private weak var delegate: TypingIndicators?
        private let thread: TSThread
        private var sendPauseTimer: Timer?
        private var sendRefreshTimer: Timer?

        init(delegate: TypingIndicators, thread: TSThread) {
            self.delegate = delegate
            self.thread = thread
        }

        // MARK: -

        func didStartTypingOutgoingInput() {
            if sendRefreshTimer == nil {
                // If the user types a character into the compose box, and the sendRefresh timer isn’t running:

                sendTypingMessageIfNecessary(forThread: thread, action: .started)

                sendRefreshTimer?.invalidate()
                sendRefreshTimer = Timer.weakScheduledTimer(withTimeInterval: 10,
                                                            target: self,
                                                            selector: #selector(OutgoingIndicators.sendRefreshTimerDidFire),
                                                            userInfo: nil,
                                                            repeats: false)
            } else {
                // If the user types a character into the compose box, and the sendRefresh timer is running:
            }

            sendPauseTimer?.invalidate()
            sendPauseTimer = Timer.weakScheduledTimer(withTimeInterval: 3,
                                                      target: self,
                                                      selector: #selector(OutgoingIndicators.sendPauseTimerDidFire),
                                                      userInfo: nil,
                                                      repeats: false)
        }

        func didStopTypingOutgoingInput() {
            sendTypingMessageIfNecessary(forThread: thread, action: .stopped)

            sendRefreshTimer?.invalidate()
            sendRefreshTimer = nil

            sendPauseTimer?.invalidate()
            sendPauseTimer = nil
        }

        @objc
        func sendPauseTimerDidFire() {
            sendTypingMessageIfNecessary(forThread: thread, action: .stopped)

            sendRefreshTimer?.invalidate()
            sendRefreshTimer = nil

            sendPauseTimer?.invalidate()
            sendPauseTimer = nil
        }

        @objc
        func sendRefreshTimerDidFire() {
            sendTypingMessageIfNecessary(forThread: thread, action: .started)

            sendRefreshTimer?.invalidate()
            sendRefreshTimer = Timer.weakScheduledTimer(withTimeInterval: 10,
                                                        target: self,
                                                        selector: #selector(sendRefreshTimerDidFire),
                                                        userInfo: nil,
                                                        repeats: false)
        }

        func didSendOutgoingMessage() {
            sendRefreshTimer?.invalidate()
            sendRefreshTimer = nil

            sendPauseTimer?.invalidate()
            sendPauseTimer = nil
        }

        private func sendTypingMessageIfNecessary(forThread thread: TSThread, action: TypingIndicator.Kind) {
            guard let delegate = delegate else {
                return
            }
            // `areTypingIndicatorsEnabled` reflects the user-facing setting in the app preferences.
            // If it's disabled we don't want to emit "typing indicator" messages
            // or show typing indicators for other users.
            guard delegate.areTypingIndicatorsEnabled() else {
                return
            }

            if thread.isGroupThread() { return } // Don't send typing indicators in group threads

            let typingIndicator = TypingIndicator()
            typingIndicator.kind = action
            SNMessagingKitConfiguration.shared.storage.write { transaction in
                MessageSender.send(typingIndicator, in: thread, using: transaction as! YapDatabaseReadWriteTransaction)
            }
        }
    }

    // MARK: -

    // Map of (thread id)-to-(recipient id and device id)-to-IncomingIndicators.
    private var incomingIndicatorsMap = [String: [String: IncomingIndicators]]()

    private func incomingIndicatorsKey(forThread thread: TSThread) -> String {
        return String(describing: thread.uniqueId)
    }

    private func incomingIndicatorsKey(recipientId: String, deviceId: UInt) -> String {
        return "\(recipientId) \(deviceId)"
    }

    private func ensureIncomingIndicators(forThread thread: TSThread, recipientId: String, deviceId: UInt) -> IncomingIndicators {
        let threadKey = incomingIndicatorsKey(forThread: thread)
        let deviceKey = incomingIndicatorsKey(recipientId: recipientId, deviceId: deviceId)
        guard let deviceMap = incomingIndicatorsMap[threadKey] else {
            let incomingIndicators = IncomingIndicators(delegate: self, thread: thread, recipientId: recipientId, deviceId: deviceId)
            incomingIndicatorsMap[threadKey] = [deviceKey: incomingIndicators]
            return incomingIndicators
        }
        guard let incomingIndicators = deviceMap[deviceKey] else {
            let incomingIndicators = IncomingIndicators(delegate: self, thread: thread, recipientId: recipientId, deviceId: deviceId)
            var deviceMapCopy = deviceMap
            deviceMapCopy[deviceKey] = incomingIndicators
            incomingIndicatorsMap[threadKey] = deviceMapCopy
            return incomingIndicators
        }
        return incomingIndicators
    }

    // The receiver maintains one timer for each (sender, device) in a chat:
    private class IncomingIndicators {
        private weak var delegate: TypingIndicators?
        private let thread: TSThread
        fileprivate let recipientId: String
        private let deviceId: UInt
        private var displayTypingTimer: Timer?
        fileprivate var startedTypingTimestamp: UInt64?

        var isTyping = false {
            didSet {
                let didChange = oldValue != isTyping
                if didChange {
                    notifyIfNecessary()
                }
            }
        }

        init(delegate: TypingIndicators, thread: TSThread,
             recipientId: String, deviceId: UInt) {
            self.delegate = delegate
            self.thread = thread
            self.recipientId = recipientId
            self.deviceId = deviceId
        }

        func didReceiveTypingStartedMessage() {
            displayTypingTimer?.invalidate()
            displayTypingTimer = Timer.weakScheduledTimer(withTimeInterval: 5,
                                                          target: self,
                                                          selector: #selector(IncomingIndicators.displayTypingTimerDidFire),
                                                          userInfo: nil,
                                                          repeats: false)
            if !isTyping {
                startedTypingTimestamp = NSDate.ows_millisecondTimeStamp()
            }
            isTyping = true
        }

        func didReceiveTypingStoppedMessage() {
            clearTyping()
        }

        @objc
        func displayTypingTimerDidFire() {
            clearTyping()
        }

        func didReceiveIncomingMessage() {
            clearTyping()
        }

        private func clearTyping() {
            displayTypingTimer?.invalidate()
            displayTypingTimer = nil
            startedTypingTimestamp = nil
            isTyping = false
        }

        private func notifyIfNecessary() {
            guard let delegate = delegate else {
                return
            }
            // `areTypingIndicatorsEnabled` reflects the user-facing setting in the app preferences.
            // If it's disabled we don't want to emit "typing indicator" messages
            // or show typing indicators for other users.
            guard delegate.areTypingIndicatorsEnabled() else {
                return
            }
            guard let threadId = thread.uniqueId else {
                return
            }
            NotificationCenter.default.postNotificationNameAsync(TypingIndicatorsImpl.typingIndicatorStateDidChange, object: threadId)
        }
    }
}
