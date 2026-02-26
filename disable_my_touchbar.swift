import Cocoa
import CoreGraphics
import ObjectiveC

// API 探针
@objc protocol NSTouchBarPrivate {
    @objc optional static func minimizeSystemModalFunctionBar(_ touchBar: NSTouchBar?)
    @objc optional static func dismissSystemModalTouchBar(_ touchBar: NSTouchBar?)
    @objc optional static func dismissSystemModalFunctionBar(_ touchBar: NSTouchBar?)
}

let TOGGLE_INTERVAL: TimeInterval = 0.4
var lastCmdPressTime: TimeInterval = 0
var isTouchBarDisabled = false

// 保持在内存中的黑屏 Touch Bar
var blackTouchBar: NSTouchBar?

func setupBlackTouchBar() -> NSTouchBar {
    let touchBar = NSTouchBar()
    let identifier = NSTouchBarItem.Identifier("com.local.blank")
    let item = NSCustomTouchBarItem(identifier: identifier)
    
    let view = NSView()
    view.wantsLayer = true
    view.layer?.backgroundColor = NSColor.black.cgColor
    item.view = view
    
    touchBar.templateItems = [item]
    touchBar.defaultItemIdentifiers = [identifier]
    return touchBar
}

func toggleTouchBar() {
    isTouchBarDisabled.toggle()
    
    guard let touchBarClass: AnyClass = NSClassFromString("NSTouchBar") else { return }
    let target: AnyObject = touchBarClass as AnyObject
    let tb = blackTouchBar!
    let idStr = "com.local.blank" as NSString
    
    if isTouchBarDisabled {
        // 关闭（展示纯黑屏幕）
        let sel3 = NSSelectorFromString("presentSystemModalTouchBar:placement:systemTrayItemIdentifier:")
        let sel1 = NSSelectorFromString("presentSystemModalFunctionBar:placement:systemTrayItemIdentifier:")
        
        typealias Func3Args = @convention(c) (AnyObject, Selector, AnyObject, Int64, AnyObject) -> Void
        if target.responds(to: sel3) {
            let fn = unsafeBitCast(target.method(for: sel3), to: Func3Args.self)
            fn(target, sel3, tb, 1, idStr)
        } else if target.responds(to: sel1) {
            let fn = unsafeBitCast(target.method(for: sel1), to: Func3Args.self)
            fn(target, sel1, tb, 1, idStr)
        }
        NSLog("⛔ Touch Bar BLANKED")
    } else {
        // 恢复（隐藏黑屏）
        let sel3 = NSSelectorFromString("dismissSystemModalTouchBar:")
        let sel1 = NSSelectorFromString("minimizeSystemModalFunctionBar:")
        
        typealias Func1Arg = @convention(c) (AnyObject, Selector, AnyObject) -> Void
        if target.responds(to: sel3) {
            let fn = unsafeBitCast(target.method(for: sel3), to: Func1Arg.self)
            fn(target, sel3, tb)
        } else if target.responds(to: sel1) {
            let fn = unsafeBitCast(target.method(for: sel1), to: Func1Arg.self)
            fn(target, sel1, tb)
        }
        NSLog("✅ Touch Bar RESTORED")
    }
}

// ── CGEventTap 回调 ───────────────────────────────────────────
let callback: CGEventTapCallBack = { proxy, type, event, _ in
    guard type == .flagsChanged else { return Unmanaged.passRetained(event) }

    let flags = event.flags
    let now = Date.timeIntervalSinceReferenceDate

    let cmdOnly = flags.contains(.maskCommand)
        && !flags.contains(.maskShift)
        && !flags.contains(.maskControl)
        && !flags.contains(.maskAlternate)
        && !flags.contains(.maskSecondaryFn)

    if cmdOnly {
        let delta = now - lastCmdPressTime
        if delta < TOGGLE_INTERVAL && delta > 0.05 {
            NSLog("Double-Cmd detected! Toggling internal Touch Bar…")
            DispatchQueue.main.async { toggleTouchBar() }
            lastCmdPressTime = 0
        } else {
            lastCmdPressTime = now
        }
    }
    return Unmanaged.passRetained(event)
}

// ── 检查 Accessibility 权限 ──────────────────────────────────
func checkAccessibilityPermission() -> Bool {
    let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
    return AXIsProcessTrustedWithOptions(opts)
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        guard checkAccessibilityPermission() else {
            NSLog("⚠️ Accessibility Permission Denied")
            exit(1)
        }
        
        blackTouchBar = setupBlackTouchBar()
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.flagsChanged.rawValue),
            callback: callback,
            userInfo: nil
        ) else {
            NSLog("❌ 无法创建 EventTap")
            exit(1)
        }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        
        NSLog("✅ 完美双击监听已启动（无副作用模式）")
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
