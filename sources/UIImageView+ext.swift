
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

	public func loadRequest(request: NSURLRequest, filter: ImageLoader.Filter? = nil, handler: ((imageView: UIImageView, result: ImageLoader.Result) -> Void)? = nil) {

		let task = ImageLoader.shared.request(request, filter: filter) { [weak self] in
			guard let me = self else { return }
			me.image = $0.image
			if let h = handler { h(imageView: me, result: $0) }
			me.setAssociate("imageloadertask", value: nil)
		}

		setAssociate("imageloadertask", value: ILWTask(task: task))
	}

	public func loadURL(urls: String, headers: [String: String]? = nil, filter: ImageLoader.Filter? = nil, handler: ((imageView: UIImageView, result: ImageLoader.Result) -> Void)? = nil) {
		guard let req = HTTP.shared.createRequest(.GET, urls, params: nil, headers: headers) else { return }
		return loadRequest(req, filter: filter, handler: handler)
	}

}
