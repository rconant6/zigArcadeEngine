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
        print("[MACOS] - Processing event: keyCode=\(event.keyCode), type=\(event.type)")
    
        let keyEvent = kbKeyEvent(
         code: UInt8(event.keyCode),
         isPressed: event.type == .keyDown ? 1 : 0,
         timestamp: UInt64(event.timestamp * 1000)
        )
    
        queueLock.lock()
        defer { queueLock.unlock() }
    
        print("[MACOS] - Adding event to queue, current size: \(eventQueue.count)")
        eventQueue.append(keyEvent)
        print("[MACOS] - Queue size after adding: \(eventQueue.count)")
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

    func startMonitoring() -> Bool {
    print("[MACOS] - start monitor")
    // Already running
    if globalMonitor != nil {
        return true
    }
    
    // Create event mask for keyboard events
    let eventMask: NSEvent.EventTypeMask = [.keyDown, .keyUp]
    
    // Set up the local monitor (events from your app)
    let localMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
        print("[MACOS] - Local event captured: keyCode=\(event.keyCode)")
        self?.processKeyEvent(event)
        return event
    }
    
    // Store the local monitor in the globalMonitor property
    globalMonitor = localMonitor
    
    print("[MACOS] - monitor initialized: \(globalMonitor != nil)")
    return globalMonitor != nil
}
}
// MARK: - C interface functions
@MainActor
@_cdecl("kb_startKeyboardMonitoring")
public func kb_startKeyboardMonitoring() -> UInt8 {
    print("[MACOS] - kb_startKeyboardMonitoring called")
    if Thread.isMainThread {
        print("[MACOS] - on main thread, calling directly")
        let success = KeyboardMonitor.shared.startMonitoring()
        return success ? 1 : 0
    } else {
        print("[MACOS] - not on main thread, dispatching")
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

@available(macOS 15.0, *)
@_cdecl("kb_stopKeyboardMonitoring")
public func kb_stopKeyboardMonitoring() {
    DispatchQueue.main.async {
        KeyboardMonitor.shared.stopMonitoring()
    }
}

@MainActor
@_cdecl("kb_pollKeyboardEvent")
public func kb_pollKeyboardEvent(_ outEvent: UnsafeMutablePointer<kbKeyEvent>) -> UInt8 {
    let result = KeyboardMonitor.shared.pollEvent()

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

