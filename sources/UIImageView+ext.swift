
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)

import EzHTTP
import UIKit

public extension UIImageView {
	class ILWTask: NSObject {
		let task: ImageLoader.Task?
		init(task: ImageLoader.Task?) { self.task = task }
		deinit { task?.cancel() }
	}

	func loadRequest(_ request: URLRequest, filter: ImageLoader.Filter? = nil, nocache: Bool, handler: ((_ imageView: UIImageView, _ result: ImageLoader.Result) -> Void)? = nil) {
		let task = ImageLoader.shared.request(request, filter: filter, nocache: nocache) { [weak self] in
			guard let me = self else { return }
			me.image = $0.image

			if let img = $0.image, let imgs = img.images {
				me.animationImages = imgs
				me.animationDuration = img.duration
				me.startAnimating()
			}

			if let h = handler { h(me, $0) }
			me.setAssociate("imageloadertask", value: nil)
		}

		setAssociate("imageloadertask", value: ILWTask(task: task))
	}

	func loadURL(_ urlstring: String, headers: [String: String]? = nil, filter: ImageLoader.Filter? = nil, nocache: Bool = false, handler: ((_ imageView: UIImageView, _ result: ImageLoader.Result) -> Void)? = nil) {
		guard let url = URL(string: urlstring) else { return }
		loadURL(url, headers: headers, filter: filter, nocache: nocache, handler: handler)
	}

	func loadURL(_ url: URL, headers: [String: String]? = nil, filter: ImageLoader.Filter? = nil, nocache: Bool = false, handler: ((_ imageView: UIImageView, _ result: ImageLoader.Result) -> Void)? = nil) {
		let req = HTTP.shared.createRequest(.GET, url, params: nil, headers: headers)
		return loadRequest(req, filter: filter, nocache: nocache, handler: handler)
	}

	func loadFadeinURL(_ urlstring: String, headers: [String: String]? = nil, filter: ImageLoader.Filter? = nil) {
		loadURL(urlstring, headers: headers, filter: filter, handler: UIImageView.fadeinHandler)
	}

	func loadFadeinURL(_ url: URL, headers: [String: String]? = nil, filter: ImageLoader.Filter? = nil) {
		loadURL(url, headers: headers, filter: filter, handler: UIImageView.fadeinHandler)
	}

	static func fadeinHandler(_ imageView: UIImageView, _ result: ImageLoader.Result) {
		if result.reason != .downloaded { return }
		imageView.alpha = 0
		UIView.animate(withDuration: 0.3) { imageView.alpha = 1 }
	}
}
