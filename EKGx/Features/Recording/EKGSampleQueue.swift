import Foundation

/// Lock-free, thread-safe FIFO sample queue for 12-lead ECG data.
/// Writers: BLE / filter callback (any thread).
/// Readers: render queue — call `dequeue` from one thread at a time.
final class EKGSampleQueue {

    static let leadCount = 12

    private var queues: [[Int16]]
    private var lock = os_unfair_lock()

    init() {
        queues = Array(repeating: [], count: Self.leadCount)
        for i in 0..<Self.leadCount { queues[i].reserveCapacity(512) }
    }

    func enqueue(_ frame: [[Int16]]) {
        let n = min(frame.count, Self.leadCount)
        os_unfair_lock_lock(&lock)
        for i in 0..<n { queues[i].append(contentsOf: frame[i]) }
        os_unfair_lock_unlock(&lock)
    }

    /// Dequeues up to `max` samples for a lead. Returns empty if nothing available.
    func dequeue(lead: Int, max count: Int) -> [Int16] {
        os_unfair_lock_lock(&lock)
        defer { os_unfair_lock_unlock(&lock) }
        let n = min(count, queues[lead].count)
        guard n > 0 else { return [] }
        let out = Array(queues[lead].prefix(n))
        queues[lead].removeFirst(n)
        return out
    }

    func reset() {
        os_unfair_lock_lock(&lock)
        for i in 0..<Self.leadCount { queues[i].removeAll(keepingCapacity: true) }
        os_unfair_lock_unlock(&lock)
    }
}
