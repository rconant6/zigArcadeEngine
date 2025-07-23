import CKeyboardBridge
import Cocoa

public final class KeyboardMonitor {
  static let shared = KeyboardMonitor()

  private var eventQueue: [kbKeyEvent] = []
  private let queueLock = NSLock()

  private var globalMonitor: Any? = nil

  private init() {}

  private func processKeyEvent(_ event: NSEvent) {
    let kbType: kbEventType = event.type == .keyDown ? KB_KEY_PRESS : KB_KEY_RELEASE
    let keyEvent = createKeyEvent(type: kbType, event: event)

    queueLock.lock()
    eventQueue.append(keyEvent)
    queueLock.unlock()
  }

  private func createKeyEvent(type: kbEventType, event: NSEvent) -> kbKeyEvent {
    let fTimestamp = kbTime(event.timestamp * 1000.0)
    let modifiers = event.modifierFlags
    var compactMods: UInt8 = 0

    if modifiers.contains(.shift) { compactMods |= 0x1 }
    if modifiers.contains(.control) { compactMods |= 0x2 }
    if modifiers.contains(.option) { compactMods |= 0x4 }
    if modifiers.contains(.command) { compactMods |= 0x8 }

    return kbKeyEvent(
      eventType: type,
      timestamp: fTimestamp,
      code: UInt8(event.keyCode),
      modifiers: compactMods,
    )
  }

  func startMonitoring() -> Bool {
    if globalMonitor != nil { return true }

    let eventMask: NSEvent.EventTypeMask = [
      .keyDown, .keyUp,
    ]

    let localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
      self?.processKeyEvent(event)
      return event
    }
    globalMonitor = localMonitor

    return globalMonitor != nil
  }

  func stopMonitoring() {
    if let monitor = globalMonitor {
      NSEvent.removeMonitor(monitor)
      globalMonitor = nil
    }

    queueLock.lock()
    defer { queueLock.unlock() }
    eventQueue.removeAll()
  }

  func pollKeyboardEventBatch(_ outBatch: UnsafeMutablePointer<kbEventBatch>) -> UInt8 {
    queueLock.lock()
    defer { queueLock.unlock() }

    let eventCount: Int32 = min(Int32(eventQueue.count), MAX_KB_EVENTS_PER_FRAME)

    withUnsafeMutableBytes(of: &outBatch.pointee.events) { rawBuffer in
      for i in 0..<eventCount {
        let eventPtr = rawBuffer.baseAddress!.advanced(by: Int(i) * MemoryLayout<kbKeyEvent>.size)
        eventPtr.copyMemory(from: &eventQueue[Int(i)], byteCount: MemoryLayout<kbKeyEvent>.size)
      }
    }

    outBatch.pointee.eventCount = eventCount
    outBatch.pointee.overflow = eventQueue.count > Int(MAX_KB_EVENTS_PER_FRAME) ? 1 : 0

    eventQueue.removeFirst(Int(eventCount))

    return eventCount > 0 ? 1 : 0
  }
}

extension KeyboardMonitor: @unchecked Sendable {}

// MARK: - C interface functions
// kbBool kb_startKeyboardMonitoring(void);
@MainActor
@_cdecl("kb_startKeyboardMonitoring")
public func kb_startKeyboardMonitoring() -> UInt8 {
  if Thread.isMainThread {
    let success = KeyboardMonitor.shared.startMonitoring()
    return success ? 1 : 0
  } else {
    var success = false
    let semaphore = DispatchSemaphore(value: 0)

    DispatchQueue.main.async {
      success = KeyboardMonitor.shared.startMonitoring()
      semaphore.signal()
    }

    semaphore.wait()
    return success ? 1 : 0
  }
}

// void kb_stopKeyboardMonitoring(void);
@MainActor
@_cdecl("kb_stopKeyboardMonitoring")
public func kb_stopKeyboardMonitoring() {
  KeyboardMonitor.shared.stopMonitoring()
}

// kbBool kb_pollKeyboardEventBatch(kbEventBatch *outBatch);
@MainActor
@_cdecl("kb_pollKeyboardEventBatch")
public func kb_pollKeyboardEventBatch(_ outBatch: UnsafeMutablePointer<kbEventBatch>) -> UInt8 {
  return KeyboardMonitor.shared.pollKeyboardEventBatch(outBatch)
}
