
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)

import UIKit
// import CommonCrypto

struct Dispatch {
	// independent
	static func main(_ block: @escaping () -> Void) {
		return DispatchQueue.main.async(execute: block)
	}

	static func background(_ block: @escaping () -> Void) {
		return DispatchQueue.global(qos: DispatchQoS.QoSClass.background).async(execute: block)
	}

	// can select main or default
	static func doAsMain(_ isMain: Bool, block: () -> Void) {
		let queue: DispatchQueue = isMain ? DispatchQueue.main : DispatchQueue.global(qos: DispatchQoS.QoSClass.default)
		queue.sync(execute: block)
	}

	// use in main-thread, call this or ...ASync in async{}
	static func await<T>(_ block: @escaping () -> T?) -> T? {
		var result: T?
		var done = false

		background {
			result = block()
			done = true
		}

		while done == false { CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.02, false) }
		return result
	}

	static func async(_ block: @escaping () -> Void) {
		CFRunLoopPerformBlock(CFRunLoopGetCurrent(), CFRunLoopMode.commonModes as CFTypeRef, block)
	}
}

extension String {
	func to_ns() -> NSString { return (self as NSString) }

	func hasString(_ str: String) -> Bool {
		if let _ = range(of: str) { return true }
		return false
	}

	func appendPath(_ path: String) -> String {
		let result = to_ns().appendingPathComponent(path)

		if !hasString("://") { return result }
		guard var c = URLComponents(string: self) else { return result }

		if c.path == "" { c.path = "/" }
		c.path = c.path.to_ns().appendingPathComponent(path)
		return c.string ?? result
	}

	var md5: String {
		guard let data = data(using: String.Encoding.utf8) else { return "" }
		var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
		CC_MD5((data as NSData).bytes, CC_LONG(data.count), &hash)
		return hash.reduce("") { $0 + String(format: "%02X", $1) }
	}
}

extension NSObject {
	func removeNotifications() {
		NSObject.cancelPreviousPerformRequests(withTarget: self)
		NotificationCenter.default.removeObserver(self)
	}

	func addNotification(_ aSelector: Selector, name: Notification.Name) {
		NotificationCenter.default.addObserver(self, selector: aSelector, name: name, object: nil)
	}

	// black magic
	fileprivate struct AssociatedKeys { static var name = "name" }

	func getAssociate(_ key: String) -> Any? {
		guard let dic = objc_getAssociatedObject(self, &AssociatedKeys.name) as? [String: Any] else { return nil }
		return dic[key]
	}

	func setAssociate(_ key: String, value: Any?) {
		var dic = (objc_getAssociatedObject(self, &AssociatedKeys.name) as? [String: Any]) ?? [:]
		dic[key] = value
		objc_setAssociatedObject(self, &AssociatedKeys.name, dic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
}

extension Date {
	var lapTime: TimeInterval { return -timeIntervalSince(Date()) }
}

struct Path {
	static var caches: String { return NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0] }
	static func caches(_ path: String) -> String { return Path.caches.appendPath(path) }

	@discardableResult static func remove(_ path: String) -> Bool {
		do {
			try FileManager.default.removeItem(atPath: path)
		} catch { return false }
		return true
	}

	@discardableResult static func mkdir(_ path: String) -> Bool {
		do {
			try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
		} catch { return false }
		return true
	}

	static func files(_ path: String) -> [String] {
		return (try? FileManager.default.contentsOfDirectory(atPath: path)) ?? []
	}

	static func exists(_ path: String) -> Bool {
		return FileManager.default.fileExists(atPath: path)
	}

	static func isFile(_ path: String) -> Bool {
		var isdir: ObjCBool = false
		let exist = FileManager.default.fileExists(atPath: path, isDirectory: &isdir)
		return exist && !isdir.boolValue
	}

	static func isDir(_ path: String) -> Bool {
		var isdir: ObjCBool = false
		let exist = FileManager.default.fileExists(atPath: path, isDirectory: &isdir)
		return exist && isdir.boolValue
	}

	static func attributes(_ path: String) -> [FileAttributeKey: Any] {
		return (try? FileManager.default.attributesOfItem(atPath: path)) ?? [:]
	}
}
