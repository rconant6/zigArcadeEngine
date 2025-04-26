import Cocoa
import CWindowBridge

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("[MACOS-WIN] - Application did finish launching")
    }
}

@MainActor
public final class WindowManager {
    static var shared = WindowManager()
    static var appDelegate: AppDelegate? = nil
    
    var windows: [UInt32: NSWindow] = [:]
    private var nextWindowID: UInt32 = 1

    private init() {}

    func createWindow(config: wbWindowConfig) -> UInt32 {
        print("[MACOS-WIN] - Creating window, width: \(config.width), height: \(config.height)")
        let windowID = nextWindowID
        nextWindowID += 1

        let width = CGFloat(config.width)
        let height = CGFloat(config.height)
        let rect = NSRect(x: 0, y: 0, width: width, height: height)

        let styleMask: NSWindow.StyleMask = [.titled, .closable, .resizable]
        let window = NSWindow(
            contentRect: rect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        window.title = String(cString: config.title)
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor.systemBlue  // Make it visibly blue for testing
    
        // Create a content view for the window - this is often needed
        let contentView = NSView(frame: rect)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.systemRed.cgColor  // Red for visibility
        window.contentView = contentView
    
        // Position window in center of screen
        window.center()
    
        // Ensure window is visible and key (active)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()  // This forces it to the front even if app isn't active
        
        print("[MACOS-WIN] - Window created, ID: \(windowID)")
    
        // Force application to foreground
        NSApplication.shared.activate(ignoringOtherApps: true)
    
        windows[windowID] = window
        return windowID
    }

    func destroyWindow(windowID: UInt32) {
        if let window = windows[windowID] {
            window.close()
            windows.removeValue(forKey: windowID)
        }
    }

    func shouldWindowClose(windowID: UInt32) -> Bool {
        return windows[windowID] == nil || (windows[windowID]?.isVisible == false)
    }

    func processEvents() {
        let app = NSApplication.shared
        while let event = app.nextEvent(matching: .any, until: nil, inMode: .default, dequeue: true) {
            app.sendEvent(event)
        }
    }
}

@MainActor
@_cdecl("wb_initApplication")
public func wb_initApplication() -> UInt8 {
    print("[MACOS-WIN] - Starting init")
        
    if Thread.isMainThread {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)

        let delegate = AppDelegate()
        app.delegate = delegate
        WindowManager.appDelegate = delegate

        app.finishLaunching()
        app.activate(ignoringOtherApps: true)

        print("[MACOS-WIN] - Application init directly")
        return 1
    } else {
        var success: UInt8 = 0
        let semaphore = DispatchSemaphore(value: 0)


        DispatchQueue.main.async {
            let app = NSApplication.shared
            app.setActivationPolicy(.regular)
            
            // Create and set app delegate
            let delegate = AppDelegate()
            app.delegate = delegate
            WindowManager.appDelegate = delegate
            
            // Start the app
            app.finishLaunching()
            app.activate(ignoringOtherApps: true)
            print("[MACOS-WIN] - Application initialized via dispatch")
        
            success = 1
            semaphore.signal()
        }

        let runLoopMode = RunLoop.Mode.default
        let timeout = Date(timeIntervalSinceNow: 0.1)
        RunLoop.main.run(mode: runLoopMode, before: timeout)

        let waitResult = semaphore.wait(timeout: .now() + 3.0)
        if waitResult == .timedOut {
            print("[MACOS-WIN] - Warning: Init timed out")
            return 0
        }

        return success
    }
}

@MainActor
@_cdecl("wb_createWindow")
public func wb_createWindow(_ config: wbWindowConfig) -> UInt32 {
    if Thread.isMainThread {
        return WindowManager.shared.createWindow(config: config)
    } else {
        var windowID: UInt32 = 0
        let semaphore = DispatchSemaphore(value: 0)

        DispatchQueue.main.async {
            windowID = WindowManager.shared.createWindow(config: config)
            semaphore.signal()
        }

        semaphore.wait()
        return windowID
    }
}

@_cdecl("wb_destroyWindow")
public func wb_destroyWindow(_ windowID: UInt32) {
    DispatchQueue.main.async {
        WindowManager.shared.destroyWindow(windowID: windowID)
    }
}

@MainActor
@_cdecl("wb_shouldWindowClose")
public func wb_shouldWindowClose(_ windowID: UInt32) -> UInt8 {
    if Thread.isMainThread {
        let shouldClose = WindowManager.shared.shouldWindowClose(windowID: windowID)
        return shouldClose ? 1 : 0
    } else {
        var shouldClose = false
        let semaphore = DispatchSemaphore(value: 0)
        
        DispatchQueue.main.async {
            shouldClose = WindowManager.shared.shouldWindowClose(windowID: windowID)
            semaphore.signal()
        }
        
        // Process main runloop for a moment
        let runLoopMode = RunLoop.Mode.default
        let timeout = Date(timeIntervalSinceNow: 0.1)
        RunLoop.main.run(mode: runLoopMode, before: timeout)
        
        // Wait with timeout
        let waitResult = semaphore.wait(timeout: .now() + 3.0)
        if waitResult == .timedOut {
            return 0
        }
        
        return shouldClose ? 1 : 0
    }
}

@MainActor
@_cdecl("wb_makeApplicationVisible")
public func wb_makeApplicationVisible() -> UInt8 {
    if Thread.isMainThread {
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Force all windows to front
        for window in WindowManager.shared.windows.values {
            window.orderFrontRegardless()
        }
        
        return 1
    } else {
        let semaphore = DispatchSemaphore(value: 0)
        var success: UInt8 = 0
        
        DispatchQueue.main.async {
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            // Force all windows to front
            for window in WindowManager.shared.windows.values {
                window.orderFrontRegardless()
            }
            
            success = 1
            semaphore.signal()
        }
        
        // Process main runloop for a moment
        let runLoopMode = RunLoop.Mode.default
        let timeout = Date(timeIntervalSinceNow: 0.1)
        RunLoop.main.run(mode: runLoopMode, before: timeout)
        
        _ = semaphore.wait(timeout: .now() + 1.0)
        return success
    }
}

@MainActor
@_cdecl("wb_processEvents")
public func wb_processEvents() {
    if Thread.isMainThread {
        let app = NSApplication.shared
        // Limit to 10 events per call to avoid blocking
        for _ in 0..<10 {
            if let event = app.nextEvent(matching: .any, until: nil, inMode: .default, dequeue: true) {
                app.sendEvent(event)
            } else {
                break  // No more events
            }
        }
    } else {
        // If not on main thread, dispatch and wait
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.main.async {
            let app = NSApplication.shared
            // Process a few events
            for _ in 0..<10 {
                if let event = app.nextEvent(matching: .any, until: nil, inMode: .default, dequeue: true) {
                    app.sendEvent(event)
                } else {
                    break  // No more events
                }
            }
            semaphore.signal()
        }
        
        // Give enough time for events to process
        _ = semaphore.wait(timeout: .now() + 0.1)
    }
}

