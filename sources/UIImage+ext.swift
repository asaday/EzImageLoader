
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)

import ImageIO
import UIKit
// import webp

public extension UIImage {
	func resize(_ size: CGSize, fill: Bool = true) -> UIImage {
		if size.width <= 0 || size.height <= 0 || size.width <= 0 || size.height <= 0 { return self }

		let xz = size.width / size.width
		let yz = size.height / size.height
		let z = ((xz < yz) != fill) ? xz : yz
		let twidth = size.width * z
		let theight = size.height * z
		let tx = (size.width - twidth) / 2
		let ty = (size.height - theight) / 2
		let rc = CGRect(x: tx, y: ty, width: twidth, height: theight).integral

		UIGraphicsBeginImageContextWithOptions(size, false, 0)
		let ctx = UIGraphicsGetCurrentContext()
		ctx?.translateBy(x: 0, y: size.height)
		ctx?.scaleBy(x: 1, y: -1)
		ctx?.draw(cgImage!, in: rc)
		let ret = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return ret ?? UIImage()
	}

	static func decode(_ data: Data, memorized: Bool = true) -> UIImage? {
		if isWebpFormat(data) {
			return webpConv(data)
		}

		if isGIFFormat(data) {
			return imageWithGIF(data: data)
		}

		if isAPNGFormat(data) {
			return imageWithAPNG(data: data)
		}

		guard let image = UIImage(data: data) else { return nil }

		if memorized == false { return image }

		// extract
		guard let imageRef: CGImage = image.cgImage else { return image }
		let alpha: CGImageAlphaInfo = imageRef.alphaInfo
		if alpha == .first || alpha == .last || alpha == .premultipliedFirst || alpha == .premultipliedLast { return image }

		UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
		let ctx = UIGraphicsGetCurrentContext()

		ctx?.translateBy(x: 0, y: image.size.height)
		ctx?.scaleBy(x: 1, y: -1)
		ctx?.draw(image.cgImage!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
		let ret = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return ret
	}

	static func isWebpFormat(_ data: Data) -> Bool {
		if data.count < 16 { return false }
		let riff = Data([0x52, 0x49, 0x46, 0x46])
		let webp = Data([0x57, 0x45, 0x42, 0x50])
		return data.subdata(in: 0 ..< 4) == riff && data.subdata(in: 8 ..< 12) == webp
	}

	static func isGIFFormat(_ data: Data) -> Bool {
		if data.count < 4 { return false }
		let gif = Data([0x47, 0x49, 0x46])
		return data.subdata(in: 0 ..< 3) == gif
	}

	static func isAPNGFormat(_ data: Data) -> Bool {
		if data.count < 64 { return false }
		let pngHeader = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])
		let actlHeader = Data([0x00, 0x00, 0x00, 0x08, 0x61, 0x63, 0x54, 0x4C]) // acTL from 33 = 8(PNG)+25(IHDR)
		return data.subdata(in: 0 ..< 8) == pngHeader && data.subdata(in: 33 ..< 41) == actlHeader
	}

	static func imageWithGIF(data: Data) -> UIImage? {
		guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
		var images: [UIImage] = []
		let count = CGImageSourceGetCount(source)

		var duration: TimeInterval = 0

		for i in 0 ..< count {
			guard let ref: CGImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
			images.append(UIImage(cgImage: ref))

			if let properties = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [AnyHashable: Any],
				let gp = properties[kCGImagePropertyGIFDictionary] as? [AnyHashable: Any]
			{
				if let p = gp[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber {
					duration += p.doubleValue
				} else if let p = gp[kCGImagePropertyGIFDelayTime] as? NSNumber {
					duration += p.doubleValue
				}
			}
		}

		if images.count == 0 { return nil }

		if duration == 0 {
			if let properties = CGImageSourceCopyProperties(source, nil) as? [AnyHashable: Any],
				let gp = properties[kCGImagePropertyGIFDictionary] as? [AnyHashable: Any],
				let p = gp[kCGImagePropertyGIFDelayTime] as? NSNumber
			{
				duration = p.doubleValue
			}
		}

		if duration == 0 {
			duration = 0.1 * Double(images.count)
		}

		return UIImage.animatedImage(with: images, duration: duration)
	}

	static func imageWithAPNG(data: Data) -> UIImage? {
		// CGImageSourceCreateImageAtIndex suuport APNG from iOS ver ??? (9? 8? 7?)
		guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

		var images: [UIImage] = []
		let count = CGImageSourceGetCount(source)
		for i in 0 ..< count {
			guard let ref: CGImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
			images.append(UIImage(cgImage: ref))
		}
		if images.count == 0 { return nil }

		if let properties = CGImageSourceCopyProperties(source, nil) as? [AnyHashable: Any],
			let gp = properties[kCGImagePropertyPNGDictionary as String] as? [AnyHashable: Any],
			let dt = gp[kCGImagePropertyAPNGDelayTime as String] as? String,
			let d = Double(dt)
		{ // may be not
			return UIImage.animatedImage(with: images, duration: d)
		}

		var duration: TimeInterval = 0
		var delays: [TimeInterval] = []
		var p: Int = 8
		while p + 8 < data.count {
			let len = UInt32(data[p + 0]) << 24 + UInt32(data[p + 1]) << 16 + UInt32(data[p + 2]) << 8 + UInt32(data[p + 3])
			let key = UInt32(data[p + 4]) << 24 + UInt32(data[p + 5]) << 16 + UInt32(data[p + 6]) << 8 + UInt32(data[p + 7])
			p = p + 8

			if key == 0x6663_544C { // fcTL
				let delay_num = UInt32(data[p + 20]) << 8 + UInt32(data[p + 21])
				let delay_den = UInt32(data[p + 22]) << 8 + UInt32(data[p + 23])
				let delay = TimeInterval(delay_num) / TimeInterval(delay_den)
				duration += delay
				delays.append(delay)
				// print("\(delay) \(delay_num) \(delay_den)")
			}
			p = p + Int(len) + 4
		}

		// no anime data
		if delays.count == 0 || delays.count != images.count {
			return UIImage.animatedImage(with: images, duration: 0.1 * Double(images.count)) // as default
		}

		// uiimage cant set each frame duration, so append frame as duration
		let min = delays.min() ?? delays[0]
		var nimgs: [UIImage] = []
		for (idx, d) in delays.enumerated() {
			let cnt = Int(d / min)
			for _ in 0 ..< cnt { nimgs.append(images[idx]) }
		}
		// print("frames \(images.count) to \(nimgs.count) frame duration \(min) total duration \(duration)")
		return UIImage.animatedImage(with: nimgs, duration: duration)
	}
}
