import AppKit
import Carbon.HIToolbox
import KikoCore
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private enum Key {
        static let enabled = "enabled"
        static let avatar = "avatar"
        static let size = "size"
        static let fadeTyping = "fadeWhileTyping"
        static let hideFullscreen = "hideInFullscreen"
        static let capturable = "capturable"
    }

    private static let sizes: [(name: String, scale: CGFloat)] = [("Small", 0.7), ("Medium", 0.85), ("Large", 1.1)]

    private let defaults = UserDefaults.standard
    private var overlay: Overlay!
    private var statusItem: NSStatusItem!
    private var hotKey: EventHotKeyRef?
    private var toggleSignal: DispatchSourceSignal?
    private var loginMenuItem: NSMenuItem?
    private var locked = false

    /// From --avatar: shows this character for one run without saving the choice.
    var avatarForThisRun: Avatar?

    /// What the settings held before the defaults went in, which is what a test walk puts back.
    private var avatarAtLaunch: String?
    private var walkingAvatarMenu = false

    private var enabled: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        avatarAtLaunch = defaults.string(forKey: Key.avatar)
        defaults.register(defaults: [
            Key.enabled: true,
            Key.avatar: Avatar.kiko.rawValue,
            Key.size: "Medium",
            Key.fadeTyping: true,
            Key.hideFullscreen: true,
            Key.capturable: false,
        ])

        overlay = Overlay()
        overlay.avatar = avatarForThisRun ?? defaults.string(forKey: Key.avatar).flatMap(Avatar.init) ?? .kiko
        overlay.scale = Self.sizes.first { $0.name == defaults.string(forKey: Key.size) }?.scale ?? 0.85
        overlay.fadeWhileTyping = defaults.bool(forKey: Key.fadeTyping)
        overlay.hideInFullscreen = defaults.bool(forKey: Key.hideFullscreen)
        overlay.capturable = defaults.bool(forKey: Key.capturable)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Kiko Cursor")
        rebuildMenu()

        registerHotKey()
        registerToggleSignal()
        observeSystem()
        // Opened while the screen is locked, no notification will ever say so.
        locked = (CGSessionCopyCurrentDictionary() as? [String: Any])?["CGSSessionScreenIsLocked"] as? Bool ?? false
        refresh()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if walkingAvatarMenu { defaults.set(avatarAtLaunch, forKey: Key.avatar) }
        overlay.setActive(false)
    }

    private func refresh() {
        overlay.setActive(enabled && !locked)
    }

    func dumpFrame(to url: URL) {
        overlay.dumpFrame(to: url)
    }

    var statusItemFrame: CGRect? {
        statusItem.button?.window?.frame
    }

    func simulatePointerReset() {
        overlay.hider.simulateSystemReset()
    }

    /// Picks each avatar through the real menu items, printing what the menu then shows and
    /// writing the frame on screen to a PNG. A test hook: it puts the saved choice back after.
    func walkAvatarMenu(savingFramesTo dir: URL, then finish: @escaping () -> Void) {
        walkingAvatarMenu = true
        func step(_ index: Int) {
            guard let submenu = statusItem.menu?.item(withTitle: "Avatar")?.submenu, index < submenu.numberOfItems else {
                finish()
                return
            }
            submenu.performActionForItem(at: index)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [self] in
                let name = overlay.avatar.rawValue
                dumpFrame(to: dir.appendingPathComponent("\(name).png"))
                let ticked = statusItem.menu?.item(withTitle: "Avatar")?.submenu?.items.filter { $0.state == .on }.map(\.title) ?? []
                let top = statusItem.menu?.items.first?.title ?? ""
                print("avatar-menu \(name) ticked=\(ticked) top=\"\(top)\" saved=\(defaults.string(forKey: Key.avatar) ?? "nil")")
                fflush(stdout)
                step(index + 1)
            }
        }
        step(0)
    }

    @objc func toggle() {
        enabled.toggle()
        refresh()
        rebuildMenu()
    }

    // MARK: Menu

    private func rebuildMenu() {
        let menu = NSMenu()

        let show = NSMenuItem(title: "Show \(overlay.avatar.name)", action: #selector(toggle), keyEquivalent: "k")
        show.keyEquivalentModifierMask = [.control, .option]
        show.target = self
        show.state = enabled ? .on : .off
        menu.addItem(show)

        let avatarItem = NSMenuItem(title: "Avatar", action: nil, keyEquivalent: "")
        let avatarMenu = NSMenu()
        for avatar in Avatar.allCases {
            let item = NSMenuItem(title: avatar.menuTitle, action: #selector(pickAvatar(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = avatar.rawValue
            item.state = avatar == overlay.avatar ? .on : .off
            avatarMenu.addItem(item)
        }
        avatarItem.submenu = avatarMenu
        menu.addItem(avatarItem)

        let sizeItem = NSMenuItem(title: "Size", action: nil, keyEquivalent: "")
        let sizeMenu = NSMenu()
        let current = defaults.string(forKey: Key.size)
        for size in Self.sizes {
            let item = NSMenuItem(title: size.name, action: #selector(pickSize(_:)), keyEquivalent: "")
            item.target = self
            item.state = size.name == current ? .on : .off
            sizeMenu.addItem(item)
        }
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)

        let login = flag("Start at Login", #selector(toggleLogin), LoginItem.isOn)
        loginMenuItem = login
        menu.addItem(login)

        menu.addItem(.separator())
        menu.addItem(flag("Fade While Typing", #selector(toggleFade), defaults.bool(forKey: Key.fadeTyping)))
        menu.addItem(flag("Hide When Idle in Full Screen", #selector(toggleFullscreen), defaults.bool(forKey: Key.hideFullscreen)))
        menu.addItem(flag("Show in Screenshots and Recordings", #selector(toggleCapture), defaults.bool(forKey: Key.capturable)))

        if !overlay.hider.canHideInBackground {
            menu.addItem(.separator())
            let note = NSMenuItem(title: "This macOS won't let \(overlay.avatar.name) hide the normal pointer", action: nil, keyEquivalent: "")
            note.isEnabled = false
            menu.addItem(note)
        }

        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit Kiko Cursor", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)

        menu.delegate = self
        statusItem.menu = menu
    }

    /// The login item can be switched off in System Settings, so check each time the menu opens.
    func menuNeedsUpdate(_ menu: NSMenu) {
        loginMenuItem?.state = LoginItem.isOn ? .on : .off
    }

    private func flag(_ title: String, _ action: Selector, _ on: Bool) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.state = on ? .on : .off
        return item
    }

    @objc private func pickAvatar(_ sender: NSMenuItem) {
        guard let raw = sender.representedObject as? String, let avatar = Avatar(rawValue: raw) else { return }
        defaults.set(avatar.rawValue, forKey: Key.avatar)
        overlay.avatar = avatar
        rebuildMenu()
    }

    @objc private func pickSize(_ sender: NSMenuItem) {
        defaults.set(sender.title, forKey: Key.size)
        overlay.scale = Self.sizes.first { $0.name == sender.title }?.scale ?? 0.85
        rebuildMenu()
    }

    @objc private func toggleLogin() {
        do {
            try LoginItem.set(!LoginItem.isOn)
        } catch {
            NSApp.activate(ignoringOtherApps: true)
            let alert = NSAlert()
            alert.messageText = "Kiko Cursor couldn't change Start at Login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
        if LoginItem.needsApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
        rebuildMenu()
    }

    @objc private func toggleFade() {
        let on = !defaults.bool(forKey: Key.fadeTyping)
        defaults.set(on, forKey: Key.fadeTyping)
        overlay.fadeWhileTyping = on
        rebuildMenu()
    }

    @objc private func toggleFullscreen() {
        let on = !defaults.bool(forKey: Key.hideFullscreen)
        defaults.set(on, forKey: Key.hideFullscreen)
        overlay.hideInFullscreen = on
        rebuildMenu()
    }

    @objc private func toggleCapture() {
        let on = !defaults.bool(forKey: Key.capturable)
        defaults.set(on, forKey: Key.capturable)
        overlay.capturable = on
        rebuildMenu()
    }

    // MARK: Global controls

    /// ⌃⌥K swaps back to the normal pointer from anywhere. Carbon hot keys need no permissions.
    private func registerHotKey() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let me = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { me.toggle() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)

        RegisterEventHotKey(UInt32(kVK_ANSI_K), UInt32(controlKey | optionKey),
                            EventHotKeyID(signature: OSType(0x4B494B4F), id: 1),
                            GetApplicationEventTarget(), 0, &hotKey)
    }

    /// `pkill -USR1 KikoCursor` does the same as the hot key, for scripts.
    private func registerToggleSignal() {
        signal(SIGUSR1, SIG_IGN)
        let source = DispatchSource.makeSignalSource(signal: SIGUSR1, queue: .main)
        source.setEventHandler { [weak self] in self?.toggle() }
        source.resume()
        toggleSignal = source
    }

    private func observeSystem() {
        // Never leave the login window without a pointer.
        let distributed = DistributedNotificationCenter.default()
        distributed.addObserver(self, selector: #selector(screenLocked), name: Notification.Name("com.apple.screenIsLocked"), object: nil)
        distributed.addObserver(self, selector: #selector(screenUnlocked), name: Notification.Name("com.apple.screenIsUnlocked"), object: nil)

        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(self, selector: #selector(screenLocked), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        workspace.addObserver(self, selector: #selector(screenUnlocked), name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
        workspace.addObserver(self, selector: #selector(reassert), name: NSWorkspace.didWakeNotification, object: nil)
        workspace.addObserver(self, selector: #selector(reassert), name: NSWorkspace.activeSpaceDidChangeNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(reassert), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    @objc private func screenLocked() {
        locked = true
        refresh()
    }

    @objc private func screenUnlocked() {
        locked = false
        refresh()
    }

    @objc private func reassert() {
        overlay.reassert()
    }
}
