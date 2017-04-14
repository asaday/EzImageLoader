
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)

import UIKit
import EzHTTP

open class ImageLoader: NSObject {

	open static let shared = ImageLoader()

	open let cache: NSCache = NNCache()
	open let queue = OperationQueue() // for decode task
	open var cachePath: String = Path.caches("images")

	open var fileCacheLifeTime: TimeInterval = 86400 * 3
	open var disableMemoryCache: Bool = false
	open var disableFileCache: Bool = false
	open var debugWaitTime: TimeInterval = 0

	open var dummyImage: UIImage?
	open var dummyWait: TimeInterval = 0

	deinit {
		removeNotifications()
	}

	public override init() {
		super.init()

		queue.maxConcurrentOperationCount = 4
		cache.totalCostLimit = 1024 * 1024 // KB
		cache.countLimit = 200

		cleanCache()
		addNotification(#selector(cleanCache), name: Notification.Name.UIApplicationDidEnterBackground.rawValue)
	}

	@discardableResult func request(_ request: URLRequest, filter: Filter?, nocache: Bool, completion: @escaping ResultHandler) -> Task? {

		if let dmy = dummyImage {
			completion(Result(image: dmy, reason: .memoryCached))
			return nil
		}

		Bench.show += 1

		let key = "\(request.url?.absoluteString ?? "")_\(filter?.identifier ?? "")".md5
		let path = cachePath.appendPath("\(request.url?.absoluteString ?? "")".md5)

		if !disableMemoryCache && !nocache {
			if let img = cache.object(forKey: key as AnyObject) as? UIImage {
				Bench.memoryhit += 1
				completion(Result(image: img, reason: .memoryCached))
				return nil
			}
		}

		let isMain = Thread.isMainThread

		let op = Task(queue: queue, request: request, path: path, filter: filter) { [weak self] result in
			if let me = self, let uimg = result.image {
				if !me.disableMemoryCache && !nocache {
					me.cache.setObject(uimg, forKey: key as AnyObject)
				}
			}
			Dispatch.doAsMain(isMain) { completion(result) }
		}
		op.disableFileCache = disableFileCache || nocache
		op.debugWaitTime = debugWaitTime

		Dispatch.background { op.start() }

		weak var wop = op
		return wop
	}

	// called in applicationDidEnterBackground
	func cleanCache() {
		let now = Date()

		Path.mkdir(cachePath)
		let files = Path.files(cachePath)

		for file in files {
			let path = cachePath.appendPath(file)
			let atb = Path.attributes(path)

			if let dt = atb[FileAttributeKey.creationDate] as? Date {
				if now.timeIntervalSince(dt) > fileCacheLifeTime {
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

// MARK: - static functions
public extension ImageLoader {

	// MARK: normal get
	@discardableResult static func request(_ request: URLRequest, filter: Filter? = nil, nocache: Bool, completion: @escaping ResultHandler) -> Task? {
		return shared.request(request, filter: filter, nocache: nocache, completion: completion)
	}

	@discardableResult static func get(_ urlstring: String, headers: [String: String]? = nil, filter: Filter? = nil, nocache: Bool = false, completion: @escaping ResultHandler) -> Task? {
		guard let req = HTTP.createRequest(.GET, urlstring, params: nil, headers: headers) else { return nil }
		return request(req as URLRequest, filter: filter, nocache: nocache, completion: completion)
	}

	@discardableResult static func get(_ url: URL, headers: [String: String]? = nil, filter: Filter? = nil, nocache: Bool = false, completion: @escaping ResultHandler) -> Task? {
		guard let req = HTTP.createRequest(.GET, url, params: nil, headers: headers) else { return nil }
		return request(req as URLRequest, filter: filter, nocache: nocache, completion: completion)
	}

	// MARK: sized get
	@discardableResult static func request(_ request: URLRequest, size: CGSize, completion: @escaping ResultHandler) -> Task? {
		return shared.request(request, filter: Filter.resizer(size), nocache: false, completion: completion)
	}

	@discardableResult static func get(_ urls: String, size: CGSize, headers: [String: String]? = nil, completion: @escaping ResultHandler) -> Task? {
		guard let req = HTTP.createRequest(.GET, urls, params: nil, headers: headers) else { return nil }
		return request(req, size: size, completion: completion)
	}

	// MARK: async get (dont call in main task)
	@discardableResult static func requestASync(_ request: URLRequest) -> UIImage? {
		var r: UIImage?
		var done = false

		shared.request(request, filter: nil, nocache: false) { r = $0.image; done = true }
		while done == false { CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 0.02, false) }
		return r
	}

	static func getASync(_ urls: String, headers: [String: String]? = nil) -> UIImage? {
		guard let req = HTTP.createRequest(.GET, urls, params: nil, headers: headers) else { return nil }
		return requestASync(req)
	}

	static func reset() {
		ImageLoader.shared.reset()
	}
}

// MARK: - result
public extension ImageLoader {
	public enum ResultReason: Int {
		case cancelled = -100 // do not callback
		case decodeFailed
		case downloadFailed
		case noData

		case memoryCached = 0
		case fileCached = 1
		case downloaded = 2
	}

	public struct Result {
		public let image: UIImage?
		public let reason: ResultReason
		public let decodeTime: TimeInterval
		public let downloadTime: TimeInterval

		public init(image: UIImage?, reason: ResultReason, decodeTime: TimeInterval = 0, downloadTime: TimeInterval = 0) {
			self.image = image
			self.reason = reason
			self.decodeTime = decodeTime
			self.downloadTime = downloadTime
		}

		static func failed(_ reason: ResultReason) -> Result {
			return Result(image: nil, reason: reason)
		}
	}
}

// MARK: - filter
public extension ImageLoader {
	public struct Filter {
		public let identifier: String // for chache identifier
		public var param: [String: Any] = [:]
		public var dataConverter: ((_ data: Data, _ param: [String: Any]) -> Data?)?
		public var imageConverter: ((_ image: UIImage, _ param: [String: Any]) -> UIImage?)?

		public init(identifier: String) {
			self.identifier = identifier
		}

		public static func resizer(_ size: CGSize) -> Filter {
			var r = Filter(identifier: "\(size)")
			r.param["size"] = NSValue(cgSize: size)

			r.imageConverter = { simg, param in
				guard let sz = (param["size"] as? NSValue)?.cgSizeValue else { return nil }
				return simg.resize(sz)
			}
			return r
		}
	}
}

// MARK: - cache
extension ImageLoader {

	class NNCache: NSCache<AnyObject, AnyObject> {
		deinit {
			removeNotifications()
		}

		override init() {
			super.init()
			addNotification(#selector(removeAllObjects), name: Notification.Name.UIApplicationDidReceiveMemoryWarning.rawValue)
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
		public static var downtime: TimeInterval = 0
		public static var downsize: Int = 0
		public static var decoded: Int = 0
		public static var decodetime: TimeInterval = 0

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
	typealias ResultHandler = ((_ result: Result) -> Void)
	typealias DecryptHandler = ((_ data: Data?) -> Data?)

	class Task: NSObject {
		let request: URLRequest
		weak var queue: OperationQueue?
		let path: String
		var filter: Filter?
		var completion: ResultHandler?

		weak var downTask: HTTP.Task?
		weak var decodeTask: Operation?
		var retry: Int = 0
		var startTime: Date = Date()
		var cancelled: Bool = false
		var downloadTime: TimeInterval = 0

		var disableFileCache: Bool = false
		var debugWaitTime: TimeInterval = 0

		deinit {}

		init(queue: OperationQueue, request: URLRequest, path: String, filter: Filter?, completion: @escaping ResultHandler) {
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
			let deop = BlockOperation {
				self.decodeTask = nil
				if self.cancelled { return }

				if !self.disableFileCache {
					let data = try? Data(contentsOf: URL(fileURLWithPath: self.path))
					var decodeTime: TimeInterval = 0
					if let img = self.decodeImage(data, decodeTime: &decodeTime) {
						self.completion?(Result(image: img, reason: .fileCached, decodeTime: decodeTime))
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
			startTime = Date()
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
					self.completion?(.failed(.downloadFailed))
					self.completion = nil
					return
				}

				if $0.status < 200 || $0.status > 399 {
					self.completion?(.failed(.downloadFailed))
					self.completion = nil
					return
				}

				guard let data = $0.data else {
					self.completion?(.failed(.noData))
					self.completion = nil
					return
				}

				Bench.downsize += data.count

				// image decode
				let deop = BlockOperation {
					self.decodeTask = nil
					if self.cancelled { return }

					var decodeTime: TimeInterval = 0
					if let img = self.decodeImage(data, decodeTime: &decodeTime) {
						self.completion?(Result(image: img, reason: .downloaded, decodeTime: decodeTime, downloadTime: self.downloadTime))
						(data as NSData).write(toFile: self.path, atomically: true)
					} else {
						self.completion?(.failed(.decodeFailed))
					}
					self.completion = nil
				}
				self.queue?.addOperation(deop)
				self.decodeTask = deop
			}
			downTask = dlop
		}

		func decodeImage(_ data: Data?, decodeTime: inout TimeInterval) -> UIImage? {
			guard var data = data else { return nil }
			let startTime = Date()

			if let dhandler = filter?.dataConverter, let param = filter?.param {
				guard let da = dhandler(data, param) else { return nil }
				data = da
			}

			var rimg: UIImage?

			if let fhandler = filter?.imageConverter, let param = filter?.param {
				if let img = UIImage.decode(data, memorized: false) {
					rimg = fhandler(img, param)
				}
			} else {
				rimg = UIImage.decode(data, memorized: true)
			}
			decodeTime = startTime.lapTime

			Bench.decodetime += decodeTime
			Bench.decoded += 1

			if debugWaitTime > 0 { Thread.sleep(forTimeInterval: debugWaitTime) }

			return rimg
		}

		open func cancel() {
			cancelled = true
			decodeTask?.cancel()
			downTask?.cancel()
			completion = nil
			decodeTask = nil
			downTask = nil
		}
	}
}
