import AppKit

let modifiers = [
	["Meta"],
	["Shift", "Meta"],
	["Option", "Meta"],
	["Option", "Shift", "Meta"],
	["Control", "Meta"],
	["Control", "Shift", "Meta"],
	["Control", "Option", "Meta"],
	["Control", "Option", "Shift", "Meta"],
	[],
	["Shift"],
	["Option"],
	["Option", "Shift"],
	["Control"],
	["Control", "Shift"],
	["Control", "Option"],
	["Control", "Option", "Shift"],
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
				guard let title = getValue(
					of: menuItem as! AXUIElement,
					attribute: kAXTitleAttribute,
					as: String.self
				) else {
					continue
				}

				if title == "" {
					continue
				}

				guard let cmdchar = getValue(
					of: menuItem as! AXUIElement,
					attribute: kAXMenuItemCmdCharAttribute,
					as: String.self
				) else {
					continue
				}

				guard let cmdmod = getValue(
					of: menuItem as! AXUIElement,
					attribute: kAXMenuItemCmdModifiersAttribute,
					as: Int.self
				) else {
					continue
				}

				let shortcut: [String: Any] = [
					"group": group as Any,
					"title": title as Any,
					"char": cmdchar as Any,
					"mods": modifiers[cmdmod],
				]

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
