//
//  ViewController.swift
//  EzImageLoaderSample
//
//  Created by asada on 2019/06/22.
//  Copyright © 2019 asada. All rights reserved.
//

import EzHTTP
import EzImageLoader
import UIKit

class ViewController: UIViewController {
	override func viewDidLoad() {
		super.viewDidLoad()
		let iv1 = UIImageView(frame: CGRect(x: 0, y: 30, width: 200, height: 200))
		view.addSubview(iv1)
		iv1.contentMode = .scaleAspectFit
		iv1.loadURL("https://ics-creative.github.io/140930_apng/images/elephant_apng_zopfli.png")

		let iv2 = UIImageView(frame: CGRect(x: 0, y: 230, width: 200, height: 200))
		view.addSubview(iv2)
		iv2.contentMode = .scaleAspectFit
    
        //iv2.loadURL("https://httpbin.org/image/webp")
        iv2.loadURL("https://res.cloudinary.com/demo/image/upload/fl_awebp/cell_animation.webp")
        //https://mathiasbynens.be/demo/animated-webp-supported.webp")//https://httpbin.org/image/webp")
    }
}
