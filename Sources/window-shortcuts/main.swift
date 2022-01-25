import AppKit

let modifiers = [
    ["Meta"],
    ["Shift", "Meta"],
    ["Alt", "Meta"],
    ["Alt", "Shift", "Meta"],
    ["Control", "Meta"],
    ["Control", "Shift", "Meta"],
    ["Control", "Alt", "Meta"],
    ["Control", "Alt", "Shift", "Meta"],
    [],
    ["Shift"],
    ["Alt"],
    ["Alt", "Shift"],
    ["Control"],
    ["Control", "Shift"],
    ["Control", "Alt"],
    ["Control", "Alt", "Shift"],
    [],
    [],
    [],
    [],
    [],
    [],
    [],
    [],
    ["Fn"],
]

func toJson<T>(_ data: T) throws -> String {
	let json = try JSONSerialization.data(withJSONObject: data)
	return String(data: json, encoding: .utf8)!
}

func getValue<T>(of element: AXUIElement, attribute: String, as type: T.Type) -> T? {
	var value: AnyObject?
	let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

	if result == .success, let typedValue = value as? T {
		return typedValue
	}

	return nil
}

func getShortcut(menuItem: AXUIElement, group: String) -> [String: Any]? {
	guard let title = getValue(
		of: menuItem,
		attribute: kAXTitleAttribute,
		as: String.self
	) else {
		return nil
	}

	if title == "" {
		return nil
	}

	guard let cmdchar = getValue(
		of: menuItem,
		attribute: kAXMenuItemCmdCharAttribute,
		as: String.self
	) else {
		return nil
	}

	guard let cmdmod = getValue(
		of: menuItem,
		attribute: kAXMenuItemCmdModifiersAttribute,
		as: Int.self
	) else {
		return nil
	}
    
    if modifiers.indices.contains(cmdmod) && modifiers[cmdmod].count != 0 {
        let shortcut = [
            "group": group as Any,
            "title": title as Any,
            "keys": modifiers[cmdmod] + [cmdchar.lowercased() as Any],
        ]
        
        return shortcut
    } else {
        print("Shortcut '\(title)' is missing modifiers at index '\(cmdmod)'")
    }
    
    return nil
}

func getShortcuts(app: NSRunningApplication) -> NSMutableArray {
	let shortcuts = [] as NSMutableArray
	let app = AXUIElementCreateApplication(app.processIdentifier)

	guard let menuBar = getValue(
		of: app,
		attribute: kAXMenuBarAttribute,
		as: AXUIElement.self
	) else {
		return shortcuts
	}

	guard let menuBarItems = getValue(
		of: menuBar,
		attribute: kAXChildrenAttribute,
		as: NSArray.self
	) else {
		return shortcuts
	}

	for menuBarItem in menuBarItems {
		guard let group = getValue(
			of: menuBarItem as! AXUIElement,
			attribute: kAXTitleAttribute,
			as: String.self
		) else {
			continue
		}

		if group == "Apple" {
			continue
		}

		guard let menus = getValue(
			of: menuBarItem as! AXUIElement,
			attribute: kAXChildrenAttribute,
			as: NSArray.self
		) else {
			continue
		}

		for menu in menus {
			guard let menuItems = getValue(
				of: menu as! AXUIElement,
				attribute: kAXChildrenAttribute,
				as: NSArray.self
			) else {
				continue
			}

			for menuItem in menuItems {
				guard let subMenus = getValue(
					of: menuItem as! AXUIElement,
					attribute: kAXChildrenAttribute,
					as: NSArray.self
				) else {
					continue
				}

				guard let subGroup = getValue(
					of: menuItem as! AXUIElement,
					attribute: kAXTitleAttribute,
					as: String.self
				) else {
					continue
				}

				if subMenus.count > 0 {
					for subMenu in subMenus {
						guard let subMenusItems = getValue(
							of: subMenu as! AXUIElement,
							attribute: kAXChildrenAttribute,
							as: NSArray.self
						) else {
							continue
						}

						for subMenusItem in subMenusItems {
							guard let subShortcut = getShortcut(menuItem: subMenusItem as! AXUIElement, group: subGroup) else {
								continue
							}

							shortcuts.add(subShortcut)
						}
					}
				}

				guard let shortcut = getShortcut(menuItem: menuItem as! AXUIElement, group: group) else {
					continue
				}

				shortcuts.add(shortcut)
			}
		}
	}

	return shortcuts
}

let arguments = CommandLine.arguments

if arguments.count < 2 {
	print(try! toJson([
		"error": "Missing argument.",
	]))
	exit(0)
}

let appName = arguments[1]
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]

guard
	let window = windows.first(where: { ($0[kCGWindowOwnerName as String] as? String) == appName })
else {
	print(try! toJson([
		"error": "No active window found for »\(appName)«",
	]))
	exit(0)
}

let appPid = window[kCGWindowOwnerPID as String] as! pid_t
let app = NSRunningApplication(processIdentifier: appPid)!
let shortcuts = getShortcuts(app: app)

print(try! toJson(shortcuts))
exit(0)
