//
//  AsyncGate.swift
//  ts-molfair-tests
//
//  Created by Mykola Zabrotskyi on 18.11.2026.
//

import Foundation

/// Holds an async call until the test calls `open()`. Opening before the call arrives is safe:
/// the call then passes straight through, so the test never depends on timing.
final class AsyncGate {

    // MARK: - Properties

    private let lock = NSLock()
    private var isOpen = false
    private var continuation: CheckedContinuation<Void, Never>?

    // MARK: - Internal Methods

    func wait() async {
        await withCheckedContinuation { continuation in
            let canPass = lock.withLock { () -> Bool in
                if isOpen { return true }
                self.continuation = continuation
                return false
            }
            if canPass {
                continuation.resume()
            }
        }
    }

    func open() {
        let pending = lock.withLock { () -> CheckedContinuation<Void, Never>? in
            isOpen = true
            defer { continuation = nil }
            return continuation
        }
        pending?.resume()
    }
}
