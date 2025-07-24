import CMouseBridge
import Cocoa

public final class MouseMonitor {
  static let shared = MouseMonitor()

  private var eventQueue: [mMouseEvent] = []
  private let queueLock = NSLock()

  private var globalMonitor: Any? = nil

  private var width: Int = 0
  private var height: Int = 0

  private let eventTypeMap: [NSEvent.EventType: (mEventType, mButton)] = [
    .leftMouseDown: (M_BUTTON_PRESS, M_BUTTON_LEFT),
    .leftMouseUp: (M_BUTTON_RELEASE, M_BUTTON_LEFT),
    .rightMouseDown: (M_BUTTON_PRESS, M_BUTTON_RIGHT),
    .rightMouseUp: (M_BUTTON_RELEASE, M_BUTTON_RIGHT),
    .otherMouseDown: (M_BUTTON_PRESS, M_BUTTON_MIDDLE),
    .otherMouseUp: (M_BUTTON_RELEASE, M_BUTTON_MIDDLE),
    .mouseMoved: (M_MOVE, M_BUTTON_NIL),
    .leftMouseDragged: (M_MOVE, M_BUTTON_NIL),
    .rightMouseDragged: (M_MOVE, M_BUTTON_NIL),
    .scrollWheel: (M_SCROLL, M_BUTTON_NIL),
    .mouseEntered: (M_ENTER_WINDOW, M_BUTTON_NIL),
    .mouseExited: (M_EXIT_WINDOW, M_BUTTON_NIL),
  ]

  private init() {}

  private func processMouseEvent(_ event: NSEvent) {
    guard let (eventType, button) = eventTypeMap[event.type] else { return }
    let mouseEvent = createMouseEvent(type: eventType, button: button, event: event)

    queueLock.lock()
    eventQueue.append(mouseEvent)
    queueLock.unlock()
  }

  private func createMouseEvent(type: mEventType, button: mButton, event: NSEvent) -> mMouseEvent {
    let fTimestamp = mTime(event.timestamp * 1000.0)
    let isPressed: mBool = (type == M_BUTTON_PRESS) ? 1 : 0

    let (gameX, gameY) = self.eventToGameCoords(event)
    let (windowX, windowY) = self.screenToWindow(event)

    let scrollX: Float = (type == M_SCROLL) ? Float(event.scrollingDeltaX) : 0.0
    let scrollY: Float = (type == M_SCROLL) ? Float(event.scrollingDeltaY) : 0.0

    let deltaX: Float = (type == M_MOVE) ? Float(event.deltaX) : 0.0
    let deltaY: Float = (type == M_MOVE) ? Float(event.deltaY) : 0.0

    let modifiers = event.modifierFlags
    var compactMods: UInt8 = 0

    if modifiers.contains(.shift) { compactMods |= 0x1 }
    if modifiers.contains(.control) { compactMods |= 0x2 }
    if modifiers.contains(.option) { compactMods |= 0x4 }
    if modifiers.contains(.command) { compactMods |= 0x8 }

    return mMouseEvent(
      eventType: type, timestamp: fTimestamp,
      windowX: windowX, windowY: windowY,
      gameX: gameX, gameY: gameY,
      deltaX: deltaX, deltaY: deltaY,
      scrollDeltaX: scrollX, scrollDeltaY: scrollY,
      button: button, isPressed: isPressed,
      modifiers: compactMods)
  }

  func startMonitoring() -> Bool {
    if globalMonitor != nil { return true }

    let eventMask: NSEvent.EventTypeMask = [
      .leftMouseDown, .rightMouseDown, .otherMouseDown,
      .leftMouseUp, .rightMouseUp, .otherMouseUp,
      .leftMouseDragged, .rightMouseDragged, .otherMouseDragged,
      .mouseEntered, .mouseExited, .mouseMoved, .scrollWheel,
    ]

    let localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
      self?.processMouseEvent(event)
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

  func pollMouseEventBatch(_ outBatch: UnsafeMutablePointer<mMouseEventBatch>) -> UInt8 {
    let MAX_MOUSE_EVENTS_PER_FRAME: Int32 = 8
    queueLock.lock()
    defer { queueLock.unlock() }

    let eventCount: Int32 = min(Int32(eventQueue.count), MAX_MOUSE_EVENTS_PER_FRAME)

    withUnsafeMutableBytes(of: &outBatch.pointee.events) { rawBuffer in
      for i in 0..<eventCount {
        let eventPtr = rawBuffer.baseAddress!.advanced(by: Int(i) * MemoryLayout<mMouseEvent>.size)
        eventPtr.copyMemory(from: &eventQueue[Int(i)], byteCount: MemoryLayout<mMouseEvent>.size)
      }
    }

    outBatch.pointee.eventCount = eventCount
    outBatch.pointee.overflow = eventQueue.count > Int(MAX_MOUSE_EVENTS_PER_FRAME) ? 1 : 0

    eventQueue.removeFirst(Int(eventCount))

    return eventCount > 0 ? 1 : 0
  }

  func setDimensions(_ width: Int, _ height: Int) {
    self.width = width
    self.height = height
  }
}

extension MouseMonitor: @unchecked Sendable {}

extension MouseMonitor {  // location helpers
  private func screenToWindow(_ event: NSEvent) -> (Float, Float) {
    let windowX = Float(event.locationInWindow.x)
    let windowY = Float(event.locationInWindow.y)

    return (windowX, windowY)
  }

  private func windowToGame(_ windowX: Float, _ windowY: Float) -> (Float, Float) {
    let gameX = (windowX * 20.0 / Float(width)) - 10.0
    let gameY = 10.0 - (windowY * 20.0 / Float(height))

    return (gameX, gameY)
  }

  private func eventToGameCoords(_ event: NSEvent) -> (Float, Float) {
    let (windowX, windowY) = screenToWindow(event)
    return windowToGame(windowX, windowY)
  }
}

// MARK: - C interface functions
// mBool m_startMouseMonitoring(void);
@MainActor
@_cdecl("m_startMouseMonitoring")
public func m_startMouseMonitoring() -> UInt8 {
  if Thread.isMainThread {
    let success = MouseMonitor.shared.startMonitoring()
    return success ? 1 : 0
  } else {
    var success = false
    let semaphore = DispatchSemaphore(value: 0)

    DispatchQueue.main.async {
      success = MouseMonitor.shared.startMonitoring()
      semaphore.signal()
    }

    semaphore.wait()
    return success ? 1 : 0
  }
}

// void m_stopMouseMonitoring(void);
@MainActor
@_cdecl("m_stopMouseMonitoring")
public func m_stopMouseMonitoring() {
  MouseMonitor.shared.stopMonitoring()
}

// mBool m_pollMouseEventBatch(mMouseEventBatch *outBatch);
@MainActor
@_cdecl("m_pollMouseEventBatch")
public func m_pollMouseEventBatch(_ outBatch: UnsafeMutablePointer<mMouseEventBatch>) -> UInt8 {
  return MouseMonitor.shared.pollMouseEventBatch(outBatch)
}

// void m_setWindowDimensions(int width, int height);
// @available(macOS 15.0, *)
@_cdecl("m_setWindowDimensions")
public func m_setWindowDimensions(_ width: Int, _ height: Int) {
  MouseMonitor.shared.setDimensions(width, height)
}
