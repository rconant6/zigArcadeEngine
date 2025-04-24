import Cocoa
import CKeyboardBridge

@MainActor
public final class KeyboardMonitor {
    static var shared = KeyboardMonitor()

    private var eventQueue: [kbKeyEvent] = []
    private let queueLock = NSLock()
    private var globalMonitor: Any? = nil
    private var pressedKeys = Set<UInt8>()

    private init() {}

    func processKeyEvent(_ event: NSEvent) {
        let keyEvent = kbKeyEvent(
            code: UInt8(event.keyCode),
            isPressed: event.type == .keyDown ? 1 : 0,
            timestamp: UInt64(event.timestamp * 1000) // Convert to milliseconds
        )
        queueLock.lock()
        defer { queueLock.unlock() }

        // Update pressed keys set
        if event.type == .keyDown {
            pressedKeys.insert(UInt8(event.keyCode))
        } else if event.type == .keyUp {
            pressedKeys.remove(UInt8(event.keyCode))
        }
        
        // Add event to queue
        eventQueue.append(keyEvent)
        
        // Keep queue from growing too large
        if eventQueue.count > 16 { // to match the fifo size in game
            eventQueue.removeFirst()
        }
    }

    func isKeyPressed(_ keyCode: UInt8) -> Bool {
        queueLock.lock()
        let isPressed = pressedKeys.contains(keyCode)
        queueLock.unlock()
        
        return isPressed
    }

    func pollEvent() -> (kbKeyEvent?, Bool) {
        queueLock.lock()
        defer { queueLock.unlock() }
        
        if eventQueue.isEmpty {
            return (nil, false)
        }
        
        // Get the next event and remove it from the queue
        let event = eventQueue.removeFirst()
        return (event, true)
    }
    
    func startMonitoring() -> Bool {
        // Already running
        if globalMonitor != nil {
            return true
        }
        
        // Create event mask for keyboard events
        let eventMask: NSEvent.EventTypeMask = [.keyDown, .keyUp]
        
        // Set up the global monitor
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.processKeyEvent(event)
        }
        
        return globalMonitor != nil
    }
    
    func stopMonitoring() {
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
        
        // Clear the queue
        queueLock.lock()
        eventQueue.removeAll()
        pressedKeys.removeAll()
        queueLock.unlock()
    }
}

// MARK: - C interface functions

@available(macOS 15.0, *)
@_cdecl("kb_startKeyboardMonitoring")
public func kb_startKeyboardMonitoring() -> UInt8 {
    DispatchQueue.main.async {
        _ = KeyboardMonitor.shared.startMonitoring()
    }
    return 1
}

@available(macOS 15.0, *)
@_cdecl("kb_stopKeyboardMonitoring")
public func kb_stopKeyboardMonitoring() {
    DispatchQueue.main.async {
        KeyboardMonitor.shared.stopMonitoring()
    }
}

@available(macOS 15.0, *)
@_cdecl("kb_pollKeyboardEvent")
public func kb_pollKeyboardEvent(_ outEvent: UnsafeMutablePointer<kbKeyEvent>) -> UInt8 {
    var result: (kbKeyEvent?, Bool) = (nil, false)
    let semaphore = DispatchSemaphore(value: 0)

    DispatchQueue.main.async {
        result = KeyboardMonitor.shared.pollEvent()
        semaphore.signal()
    }

    semaphore.wait()
    
    if result.1, let event = result.0 {
        outEvent.pointee = event
        return 1
    }
    return 0
}

@available(macOS 15.0, *)
@_cdecl("kb_isKeyPressed")
public func kb_isKeyPressed(_ keyCode: UInt8) -> UInt8 {
    var pressed = false
    let semaphore = DispatchSemaphore(value: 0)

    DispatchQueue.main.async {
        pressed = KeyboardMonitor.shared.isKeyPressed(keyCode)
        semaphore.signal()
    }

    semaphore.wait()
    return pressed ? 1 : 0
}
// C interface functions
// @available(macOS 15.0, *)
// @_cdecl("kb_startKeyboardMonitoring")
// public func kb_startKeyboardMonitoring() -> UInt8 {
//     // Use Task to run on main actor
//     let result = Task { @MainActor in
//         return KeyboardMonitor.shared.startMonitoring()
//     }.value
//
//     return result ? 1 : 0
// }
//
// @available(macOS 15.0, *)
// @_cdecl("kb_stopKeyboardMonitoring")
// public func kb_stopKeyboardMonitoring() {
//     Task { @MainActor in
//         KeyboardMonitor.shared.stopMonitoring()
//     }
// }
//
// @available(macOS 15.0, *)
// @_cdecl("kb_pollKeyboardEvent")
// public func kb_pollKeyboardEvent(_ outEvent: UnsafeMutablePointer<kbKeyEvent>) -> UInt8 {
//     let (maybeEvent, success) = Task { @MainActor in
//         return KeyboardMonitor.shared.pollEvent()
//     }.value
//
//     if success, let event = maybeEvent {
//         outEvent.pointee = event
//         return 1
//     }
//
//     return 0
// }
//
// @available(macOS 15.0, *)
// @_cdecl("kb_isKeyPressed")
// public func kb_isKeyPressed(_ keyCode: UInt8) -> UInt8 {
//     let isPressed = Task { @MainActor in
//             return KeyboardMonitor.shared.isKeyPressed(keyCode)
//      }.value
//     return isPressed ? 1 : 0
// }
