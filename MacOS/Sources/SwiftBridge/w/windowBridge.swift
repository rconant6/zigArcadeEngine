import Cocoa
import CWindowBridge

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {}
}

class KeyHandlingView: NSView {
    override var acceptsFirstResponder: Bool { return true }
    
    override func keyDown(with event: NSEvent) {
        // Instead of calling super, which would trigger the system beep,
        // just capture the event for your keyboard monitoring system
        // No need to call super.keyDown(with:)
    }
    
    override func keyUp(with event: NSEvent) {
        // Similarly, capture without passing to super
        // No need to call super.keyUp(with:)
    }
}

class RenderView: KeyHandlingView {
    var imageBuffer: UnsafeMutablePointer<UInt8>? = nil
    var bitmapContext: CGContext? = nil
    var width: Int = 0
    var height: Int = 0
    
    func setupBitmapContext(width: Int, height: Int) {
        self.width = width
        self.height = height
        
        // Free old buffer if it exists
        if let buffer = imageBuffer {
            buffer.deallocate()
            imageBuffer = nil
        }
        
        // Allocate new buffer
        imageBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height * 4)
        imageBuffer!.initialize(repeating: 0, count: width * height * 4)
        
        // Create CGContext
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        bitmapContext = CGContext(
            data: imageBuffer,
            width: width, height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }
    
    func updateFromColors(colors: UnsafePointer<Color>, width: Int, height: Int) {
        guard let buffer = imageBuffer else { return }
        guard width == self.width && height == self.height else { return }
        
        // Convert float colors to 8-bit RGBA
        for i in 0..<(width * height) {
            let color = colors[i]
            buffer[i*4 + 0] = UInt8(min(255, max(0, color.r * 255)))
            buffer[i*4 + 1] = UInt8(min(255, max(0, color.g * 255)))
            buffer[i*4 + 2] = UInt8(min(255, max(0, color.b * 255)))
            buffer[i*4 + 3] = UInt8(min(255, max(0, color.a * 255)))
        }
        
        // Trigger redraw
        self.needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        
        if let cgImage = bitmapContext?.makeImage() {
            // Draw the image
            context.draw(cgImage, in: self.bounds)
        }
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
        let windowID = nextWindowID
        nextWindowID += 1

        let width = CGFloat(config.width)
        let height = CGFloat(config.height)
        let rect = NSRect(x: 0, y: 0, width: width, height: height)

        let styleMask: NSWindow.StyleMask = [.titled, .closable]
        let window = NSWindow(
            contentRect: rect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )

        window.title = String(cString: config.title)
        window.isReleasedWhenClosed = false
        window.backgroundColor = NSColor.systemBlue  // Make it visibly blue for testing
    
    
        // Then in your createWindow function, replace the content view with:
        let contentView = KeyHandlingView(frame: rect)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.systemRed.cgColor
        window.contentView = contentView


        // Make it the first responder
        window.makeFirstResponder(contentView)

        // Position window in center of screen
        window.center()
    
        // Ensure window is visible and key (active)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()  // This forces it to the front even if app isn't active
        window.preventsApplicationTerminationWhenModal = false
        
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
    
    func updateWindowPixels(windowID: UInt32, colors: UnsafePointer<Color>, width: Int, height: Int) {
        guard let window = windows[windowID] else { return }
    
        var renderView: RenderView
        
        // Make sure we have a RenderView
        if let existingView = window.contentView as? RenderView {
            renderView = existingView
        } else {
            // Create a new RenderView
            let frame = window.contentView?.frame ?? NSRect.zero
            renderView = RenderView(frame: frame)
            renderView.setupBitmapContext(width: width, height: height)
            window.contentView = renderView
            window.makeFirstResponder(renderView)
        }
    
        // Update the pixels
        renderView.updateFromColors(colors: colors, width: width, height: height)
    }


}

@MainActor
@_cdecl("wb_updateWindowPixels")
public func wb_updateWindowPixels(_ windowID: UInt32, _ colors: UnsafePointer<Color>, width: Int32, height: Int32) {
    if Thread.isMainThread {
        WindowManager.shared.updateWindowPixels(
            windowID: windowID,
            colors: colors,
            width: Int(width),
            height: Int(height),
        )
    } else {
        DispatchQueue.main.async {
            WindowManager.shared.updateWindowPixels(
                windowID: windowID,
                colors: colors,
                width: Int(width),
                height: Int(height),
            )
        }
    }
}

@MainActor
@_cdecl("wb_initApplication")
public func wb_initApplication() -> UInt8 {
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

