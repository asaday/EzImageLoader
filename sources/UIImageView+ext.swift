
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)

import UIKit
import EzHTTP

public extension UIImageView {

	class ILWTask: NSObject {
		let task: ImageLoader.Task?
		init(task: ImageLoader.Task?) { self.task = task }
		deinit { task?.cancel() }
	}

	public func loadRequest(_ request: URLRequest, filter: ImageLoader.Filter? = nil, handler: ((_ imageView: UIImageView, _ result: ImageLoader.Result) -> Void)? = nil) {

		let task = ImageLoader.shared.request(request, filter: filter) { [weak self] in
			guard let me = self else { return }
			me.image = $0.image
			if let h = handler { h(me, $0) }
			me.setAssociate("imageloadertask", value: nil)
		}

		setAssociate("imageloadertask", value: ILWTask(task: task))
	}

	public func loadURL(_ urlstring: String, headers: [String: String]? = nil, filter: ImageLoader.Filter? = nil, handler: ((_ imageView: UIImageView, _ result: ImageLoader.Result) -> Void)? = nil) {
		guard let req = HTTP.createRequest(.GET, urlstring, params: nil, headers: headers) else { return }
		return loadRequest(req, filter: filter, handler: handler)
	}

	public func loadURL(_ url: URL, headers: [String: String]? = nil, filter: ImageLoader.Filter? = nil, handler: ((_ imageView: UIImageView, _ result: ImageLoader.Result) -> Void)? = nil) {
		guard let req = HTTP.createRequest(.GET, url, params: nil, headers: headers) else { return }
		return loadRequest(req, filter: filter, handler: handler)
	}

	public func loadFadeinURL(_ urlstring: String, headers: [String: String]? = nil, filter: ImageLoader.Filter? = nil) {
		loadURL(urlstring, headers: headers, filter: filter, handler: UIImageView.fadeinHandler)
	}

	public func loadFadeinURL(_ url: URL, headers: [String: String]? = nil, filter: ImageLoader.Filter? = nil) {
		loadURL(url, headers: headers, filter: filter, handler: UIImageView.fadeinHandler)
	}

	public static func fadeinHandler(_ imageView: UIImageView, _ result: ImageLoader.Result) {
		if result.reason != .downloaded { return }
		imageView.alpha = 0
		UIView.animate(withDuration: 0.3) { imageView.alpha = 1 }
	}
}
