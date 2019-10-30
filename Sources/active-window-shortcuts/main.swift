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

	let shortcut = [
		"group": group as Any,
		"title": title as Any,
		"char": cmdchar.lowercased() as Any,
		"mods": modifiers[cmdmod],
	]

	return shortcut
}

func getMenuItems(app: NSRunningApplication) -> NSMutableArray {
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

let frontmostAppPID = NSWorkspace.shared.frontmostApplication!.processIdentifier
let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as! [[String: Any]]

for window in windows {
	let windowOwnerPID = window[kCGWindowOwnerPID as String] as! Int

	if windowOwnerPID != frontmostAppPID {
		continue
	}

	// Skip transparent windows, like with Chrome
	if (window[kCGWindowAlpha as String] as! Double) == 0 {
		continue
	}

	let bounds = CGRect(dictionaryRepresentation: window[kCGWindowBounds as String] as! CFDictionary)!

	// Skip tiny windows, like the Chrome link hover statusbar
	let minWinSize: CGFloat = 50
	if bounds.width < minWinSize || bounds.height < minWinSize {
		continue
	}

	let appPid = window[kCGWindowOwnerPID as String] as! pid_t
	let app = NSRunningApplication(processIdentifier: appPid)!
	let dict: [String: Any] = [
		"app": window[kCGWindowOwnerName as String] as! String,
		"shortcuts": getMenuItems(app: app),
	]

	print(try! toJson(dict))
	exit(0)
}

print("null")
exit(0)
