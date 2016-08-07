
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)

import UIKit
//import CommonCrypto

struct Dispatch {
	private let block: dispatch_block_t

	// independent
	static func main(block: dispatch_block_t) {
		return dispatch_async(dispatch_get_main_queue(), block)
	}

	static func background(block: dispatch_block_t) {
		return dispatch_async(dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0), block)
	}

	// can select main or default
	static func doAsMain(isMain: Bool, block: dispatch_block_t) {
		let queue: dispatch_queue_t = isMain ? dispatch_get_main_queue() : dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
		dispatch_sync(queue, block)
	}

	// use in main-thread, call this or ...ASync in async{}
	static func await<T>(block: () -> T?) -> T? {
		var result: T?
		var done = false

		background {
			result = block()
			done = true
		}

		while done == false { CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.02, false) }
		return result
	}

	static func async(block: () -> Void) {
		CFRunLoopPerformBlock(CFRunLoopGetCurrent(), kCFRunLoopCommonModes, block)
	}

}

extension String {
	func to_ns() -> NSString { return (self as NSString) }

	func hasString(str: String) -> Bool {
		if let _ = rangeOfString(str) { return true }
		return false
	}

	func appendPath(path: String) -> String {
		let result = to_ns().stringByAppendingPathComponent(path)

		if !self.hasString("://") { return result }
		guard let c = NSURLComponents(string: self) else { return result }

		if c.path == nil { c.path = "/" }
		c.path = c.path?.to_ns().stringByAppendingPathComponent(path)
		return c.string ?? result
	}

	var md5: String {
		guard let data = dataUsingEncoding(NSUTF8StringEncoding) else { return "" }
		var hash = [UInt8](count: Int(CC_MD5_DIGEST_LENGTH), repeatedValue: 0)
		CC_MD5(data.bytes, CC_LONG(data.length), &hash)
		return hash.reduce("") { $0 + String(format: "%02X", $1) }

	}
}

extension NSObject {

	func removeNotifications() {
		NSObject.cancelPreviousPerformRequestsWithTarget(self)
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	func addNotification(aSelector: Selector, name aName: String) {
		NSNotificationCenter.defaultCenter().addObserver(self, selector: aSelector, name: aName, object: nil)
	}

	// black magic
	private struct AssociatedKeys { static var name = "name" }

	func getAssociate(key: String) -> AnyObject? {
		guard let dic = objc_getAssociatedObject(self, &AssociatedKeys.name) as? [String: AnyObject] else { return nil }
		return dic[key]
	}

	func setAssociate(key: String, value: AnyObject?) {
		var dic = (objc_getAssociatedObject(self, &AssociatedKeys.name) as? [String: AnyObject]) ?? [:]
		dic[key] = value
		objc_setAssociatedObject(self, &AssociatedKeys.name, dic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
	}
}

extension NSDate {

	var lapTime: NSTimeInterval { return -timeIntervalSinceDate(NSDate()) }
}

struct Path {
	static var documtnts: String { return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] }
	static var caches: String { return NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0] }
	static var library: String { return NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)[0] }
	static var support: String { return NSSearchPathForDirectoriesInDomains(.ApplicationSupportDirectory, .UserDomainMask, true)[0] }
	static var temp: String { return NSTemporaryDirectory() }
	static var resource: String { return NSBundle.mainBundle().resourcePath ?? "" }

	static func documtnts(path: String) -> String { return Path.documtnts.appendPath(path) }
	static func caches(path: String) -> String { return Path.caches.appendPath(path) }
	static func library(path: String) -> String { return Path.library.appendPath(path) }
	static func support(path: String) -> String { return Path.support.appendPath(path) }
	static func resource(path: String) -> String { return Path.resource.appendPath(path) }

	static func remove(path: String) -> Bool {
		do {
			try NSFileManager.defaultManager().removeItemAtPath(path)
		} catch { return false }
		return true
	}

	static func mkdir(path: String) -> Bool {
		do {
			try NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil)
		} catch { return false }
		return true
	}

	static func files(path: String) -> [String] {
		return (try? NSFileManager.defaultManager().contentsOfDirectoryAtPath(path)) ?? []
	}

	static func exists(path: String) -> Bool {
		return NSFileManager.defaultManager().fileExistsAtPath(path)
	}

	static func isFile(path: String) -> Bool {
		var isdir: ObjCBool = false
		let exist = NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isdir)
		return exist && !isdir
	}

	static func isDir(path: String) -> Bool {
		var isdir: ObjCBool = false
		let exist = NSFileManager.defaultManager().fileExistsAtPath(path, isDirectory: &isdir)
		return exist && isdir
	}

	static func attributes(path: String) -> [String: AnyObject] {
		return (try? NSFileManager.defaultManager().attributesOfItemAtPath(path)) ?? [:]
	}
}
