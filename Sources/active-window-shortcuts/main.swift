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
	let menuBar = getValue(of: app, attribute: kAXMenuBarAttribute, as: AnyObject.self)
	let items = getValue(of: menuBar as! AXUIElement, attribute: kAXChildrenAttribute, as: NSArray.self)

	for item in items ?? [] {
		let group = getValue(of: item as! AXUIElement, attribute: kAXTitleAttribute, as: String.self)
		let items2 = getValue(of: item as! AXUIElement, attribute: kAXChildrenAttribute, as: NSArray.self)

		if group == "Apple" {
			continue
		}

		for item2 in items2 ?? [] {
			let items3 = getValue(of: item2 as! AXUIElement, attribute: kAXChildrenAttribute, as: NSArray.self)

			for item3 in items3 ?? [] {
				let title3 = getValue(of: item3 as! AXUIElement, attribute: kAXTitleAttribute, as: String.self)
				let cmdchar = getValue(of: item3 as! AXUIElement, attribute: kAXMenuItemCmdCharAttribute, as: String.self)
				let cmdmod = getValue(of: item3 as! AXUIElement, attribute: kAXMenuItemCmdModifiersAttribute, as: Int.self)

				if title3 == "" {
					continue
				}

				if cmdchar == nil {
					continue
				}

				let shortcut: [String: Any] = [
					"group": group as Any,
					"title": title3 as Any,
					"char": cmdchar as Any,
					"mods": modifiers[cmdmod ?? 8],
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
