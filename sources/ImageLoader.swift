
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)

import UIKit
import EzHTTP

public class ImageLoader: NSObject {

	public static let shared = ImageLoader()

	public let cache: NSCache = NNCache()
	public let queue = NSOperationQueue() // for decode task
	public var cachePath: String = Path.caches("images")

	public var fileCacheLifeTime: NSTimeInterval = 86400 * 3
	public var disableMemoryCache: Bool = false
	public var disableFileCache: Bool = false
	public var debugWaitTime: NSTimeInterval = 0

	public var dummyImage: UIImage?
	public var dummyWait: NSTimeInterval = 0

	deinit {
		removeNotifications()
	}

	public override init() {
		super.init()

		queue.maxConcurrentOperationCount = 4
		cache.totalCostLimit = 1024 * 1024 // KB
		cache.countLimit = 200

		cleanCache()
		addNotification(#selector(cleanCache), name: UIApplicationDidEnterBackgroundNotification)
	}

	func request(request: NSURLRequest, filter: Filter?, completion: ResultHandler) -> Task? {

		if let dmy = dummyImage {
			completion(result: Result(image: dmy, reason: .MemoryCached))
			return nil
		}

		Bench.show += 1

		let key = "\(request.URL?.absoluteString)_\( filter?.identifier ?? "")".md5
		let path = cachePath.appendPath("\(request.URL?.absoluteString)".md5)

		if !disableMemoryCache {
			if let img = cache.objectForKey(key) as? UIImage {
				Bench.memoryhit += 1
				completion(result: Result(image: img, reason: .MemoryCached))
				return nil
			}
		}

		let isMain = NSThread.isMainThread()

		let op = Task(queue: queue, request: request, path: path, filter: filter) { [weak self] result in
			if let me = self, uimg = result.image { me.cache.setObject(uimg, forKey: key) }
			Dispatch.doAsMain(isMain) { completion(result: result) }
		}
		op.disableFileCache = disableFileCache
		op.debugWaitTime = debugWaitTime

		Dispatch.background { op.start() }

		weak var wop = op
		return wop
	}

	// called in applicationDidEnterBackground
	func cleanCache() {
		let now = NSDate()

		Path.mkdir(cachePath)
		let files = Path.files(cachePath)

		for file in files {
			let path = cachePath.appendPath(file)
			let atb = Path.attributes(path)
			if let dt = atb[NSFileCreationDate] as? NSDate {
				if now.timeIntervalSinceDate(dt) > fileCacheLifeTime {
					Path.remove(path)
				}
			}
		}
		cache.removeAllObjects()
	}

	// clear all cache and tasks
	func reset() {
		cache.removeAllObjects()
		queue.cancelAllOperations()
		Path.remove(cachePath)
		Path.mkdir(cachePath)
	}
}

// MARK:- static functions
public extension ImageLoader {

	// MARK:  normal get
	static func request(request: NSURLRequest, filter: Filter? = nil, completion: ResultHandler) -> Task? {
		return shared.request(request, filter: filter, completion: completion)
	}

	static func get(urls: String, headers: [String: String]? = nil, filter: Filter? = nil, completion: ResultHandler) -> Task? {
		guard let req = HTTP.shared.createRequest(.GET, urls, params: nil, headers: headers) else { return nil }
		return request(req, filter: filter, completion: completion)
	}

	// MARK:  sized get
	static func request(request: NSURLRequest, size: CGSize, completion: ResultHandler) -> Task? {
		return shared.request(request, filter: Filter.resizer(size), completion: completion)
	}

	static func get(urls: String, size: CGSize, headers: [String: String]? = nil, completion: ResultHandler) -> Task? {
		guard let req = HTTP.createRequest(.GET, urls, params: nil, headers: headers) else { return nil }
		return request(req, size: size, completion: completion)
	}

	// MARK: async get (dont call in main task)
	static func requestASync(request: NSURLRequest) -> UIImage? {
		var r: UIImage? = nil
		var done = false

		shared.request(request, filter: nil) { r = $0.image; done = true }
		while done == false { CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.02, false) }
		return r
	}

	static func getASync(urls: String, headers: [String: String]? = nil) -> UIImage? {
		guard let req = HTTP.shared.createRequest(.GET, urls, params: nil, headers: headers) else { return nil }
		return requestASync(req)
	}

	static func reset() {
		ImageLoader.shared.reset()
	}
}

// MARK: - result
public extension ImageLoader {
	enum ResultReason: Int {
		case Cancelled = -100 // do not callback
		case DecodeFailed
		case DownloadFailed
		case NoData

		case MemoryCached = 0
		case FileCached = 1
		case Downloaded = 2
	}

	struct Result {
		public let image: UIImage?
		public let reason: ResultReason
		public let decodeTime: NSTimeInterval
		public let downloadTime: NSTimeInterval

		init(image: UIImage?, reason: ResultReason, decodeTime: NSTimeInterval = 0, downloadTime: NSTimeInterval = 0) {
			self.image = image
			self.reason = reason
			self.decodeTime = decodeTime
			self.downloadTime = downloadTime
		}

		static func failed(reason: ResultReason) -> Result {
			return Result(image: nil, reason: reason)
		}
	}
}

// MARK: - filter
public extension ImageLoader {
	public struct Filter {
		public let identifier: String // for chache identifier
		public var param: [String: AnyObject] = [:]
		public var dataConverter: ((data: NSData, param: [String: AnyObject]) -> NSData?)? = nil
		public var imageConverter: ((image: UIImage, param: [String: AnyObject]) -> UIImage?)? = nil

		public init(identifier: String) {
			self.identifier = identifier
		}

		public static func resizer(size: CGSize) -> Filter {
			var r = Filter(identifier: "\(size)")
			r.param["size"] = NSValue(CGSize: size)

			r.imageConverter = { simg, param in
				guard let sz = (param["size"] as? NSValue)?.CGSizeValue() else { return nil }
				return simg.resize(sz)
			}
			return r
		}
	}
}

// MARK: - cache
extension ImageLoader {

	class NNCache: NSCache {
		deinit {
			removeNotifications()
		}
		override init() {
			super.init()
			addNotification(#selector(removeAllObjects), name: UIApplicationDidReceiveMemoryWarningNotification)
		}
	}
}

// MARK: - bench
public extension ImageLoader {

	struct Bench {
		public static var show: Int = 0
		public static var memoryhit: Int = 0
		public static var filehit: Int = 0
		public static var download: Int = 0
		public static var downtime: NSTimeInterval = 0
		public static var downsize: Int = 0
		public static var decoded: Int = 0
		public static var decodetime: NSTimeInterval = 0

		public static func clear() {
			show = 0
			memoryhit = 0
			filehit = 0
			download = 0
			downtime = 0
			downsize = 0
			decoded = 0
			decodetime = 0
		}
	}
}

// MARK: - task
public extension ImageLoader {
	typealias ResultHandler = ((result: Result) -> Void)
	typealias DecryptHandler = ((data: NSData?) -> NSData?)

	class Task: NSObject {
		let request: NSURLRequest
		weak var queue: NSOperationQueue?
		let path: String
		var filter: Filter?
		var completion: ResultHandler?

		weak var downTask: HTTP.Task? = nil
		weak var decodeTask: NSOperation? = nil
		var retry: Int = 0
		var startTime: NSDate = NSDate()
		var cancelled: Bool = false
		var downloadTime: NSTimeInterval = 0

		var disableFileCache: Bool = false
		var debugWaitTime: NSTimeInterval = 0

		deinit { }

		init(queue: NSOperationQueue, request: NSURLRequest, path: String, filter: Filter?, completion: ResultHandler) {
			self.queue = queue
			self.request = request
			self.path = path
			self.filter = filter
			self.completion = completion
			super.init()
		}

		func start() {
			// file cache check
			if !Path.exists(path) {
				download()
				return
			}
			Bench.filehit += 1

			// image decode
			let deop = NSBlockOperation {
				self.decodeTask = nil
				if self.cancelled { return }

				if !self.disableFileCache {
					let data = NSData(contentsOfFile: self.path)
					var decodeTime: NSTimeInterval = 0
					if let img = self.decodeImage(data, decodeTime: &decodeTime) {
						self.completion?(result: Result(image: img, reason: .FileCached, decodeTime: decodeTime))
						self.completion = nil
						return
					}
				}
				self.download()
			}
			queue?.addOperation(deop)
			decodeTask = deop
		}

		func download() {
			startTime = NSDate()
			Bench.download += 1

			let dlop = HTTP.request(request) {
				self.downTask = nil
				if self.cancelled { return }

				self.downloadTime = self.startTime.lapTime
				Bench.downtime += self.downloadTime

				if let error = $0.error {
					if error.code == NSURLErrorNetworkConnectionLost { // include NSURLErrorCancelled , disconnect = -1009 NSURLErrorNotConnectedToInternet
						self.retry += 1
						if self.retry < 10 {
							self.download()
							return
						}
					}
					self.completion?(result: .failed(.DownloadFailed))
					self.completion = nil
					return
				}

				if $0.status < 200 || $0.status > 399 {
					self.completion?(result: .failed(.DownloadFailed))
					self.completion = nil
					return
				}

				guard let data = $0.data else {
					self.completion?(result: .failed(.NoData))
					self.completion = nil
					return
				}

				Bench.downsize += data.length

				// image decode
				let deop = NSBlockOperation {
					self.decodeTask = nil
					if self.cancelled { return }

					var decodeTime: NSTimeInterval = 0
					if let img = self.decodeImage(data, decodeTime: &decodeTime) {
						self.completion?(result: Result(image: img, reason: .Downloaded, decodeTime: decodeTime, downloadTime: self.downloadTime))
						data.writeToFile(self.path, atomically: true)
					} else {
						self.completion?(result: .failed(.DecodeFailed))
					}
					self.completion = nil
				}
				self.queue?.addOperation(deop)
				self.decodeTask = deop
			}
			downTask = dlop
		}

		func decodeImage(data: NSData?, inout decodeTime: NSTimeInterval) -> UIImage? {
			guard var data = data else { return nil }
			let startTime = NSDate()

			if let dhandler = filter?.dataConverter, param = filter?.param {
				guard let da = dhandler(data: data, param: param) else { return nil }
				data = da
			}

			var rimg: UIImage? = nil

			if let fhandler = filter?.imageConverter, param = filter?.param {
				if let img = UIImage.decode(data, memorized: false) {
					rimg = fhandler(image: img, param: param)
				}
			} else {
				rimg = UIImage.decode(data, memorized: true)
			}
			decodeTime = startTime.lapTime

			Bench.decodetime += decodeTime
			Bench.decoded += 1

			if debugWaitTime > 0 { NSThread.sleepForTimeInterval(debugWaitTime) }

			return rimg
		}

		public func cancel() {
			cancelled = true
			decodeTask?.cancel()
			downTask?.cancel()
			completion = nil
			decodeTask = nil
			downTask = nil
		}
	}
}

