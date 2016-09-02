
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)

import UIKit
import EzImageLoader

class ViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()

		let v = UIImageView(frame: view.bounds)
		view.addSubview(v)
		v.contentMode = .scaleAspectFit
		v.loadURL("https://httpbin.org/image/jpeg")
	}


}

