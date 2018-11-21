
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)

import ImageIO
import UIKit
// import webp

public extension UIImage {
	public func resize(_ size: CGSize, fill: Bool = true) -> UIImage {
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

	public static func decode(_ data: Data, memorized: Bool = true) -> UIImage? {
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
		let riff: [UInt8] = [0x52, 0x49, 0x46, 0x46]
		let webp: [UInt8] = [0x57, 0x45, 0x42, 0x50]
		return (memcmp((data as NSData).bytes, riff, 4) == 0 && memcmp((data as NSData).bytes + 8, webp, 4) == 0)
	}

	static func isGIFFormat(_ data: Data) -> Bool {
		if data.count < 4 { return false }
		let gif: [UInt8] = [0x47, 0x49, 0x46]
		return (memcmp((data as NSData).bytes, gif, 3) == 0)
	}

	static func isAPNGFormat(_ data: Data) -> Bool {
		if data.count < 64 { return false }
		let pngHeader: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
		let actlHeader: [UInt8] = [0x00, 0x00, 0x00, 0x08, 0x61, 0x63, 0x54, 0x4C] // acTL from 33 = 8(PNG)+25(IHDR)
		let ptr = (data as NSData).bytes
		return (memcmp(ptr, pngHeader, pngHeader.count) == 0) && (memcmp(ptr + 33, actlHeader, actlHeader.count) == 0)
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
				let gp = properties[kCGImagePropertyGIFDictionary] as? [AnyHashable: Any] {
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
				let p = gp[kCGImagePropertyGIFDelayTime] as? NSNumber {
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

		var duration: TimeInterval = 0.1 * Double(images.count)

		// read first frame duration
		let ptr = (data as NSData).bytes
		if data.count > 128 {
			let fctL: [UInt8] = [0x66, 0x63, 0x54, 0x4C] // fcTL
			if memcmp(ptr + 57, fctL, fctL.count) == 0 {
				// 8(PNG) + 25(IHDR) + 20(acTL) + 4(fcTL length) + 4(fcTL name)
				var vals: [UInt8] = [0, 0, 0, 0]
				for i in 0 ..< 4 { vals[i] = ptr.load(fromByteOffset: 61 + 20 + i, as: UInt8.self) }
				let dn = Int(vals[0]) * 256 + Int(vals[1])
				let dd = Int(vals[2]) * 256 + Int(vals[3])
				if dn > 0 && dd > 0 && dn < dd {
					duration = Double(dn) / Double(dd) * Double(images.count)
				}
			}
		}

		if let properties = CGImageSourceCopyProperties(source, nil) as? [AnyHashable: Any],
			let gp = properties[kCGImagePropertyPNGDictionary as String] as? [AnyHashable: Any],
			let dt = gp[kCGImagePropertyAPNGDelayTime as String] as? String,
			let d = Double(dt) { // may be not
			duration = d
		}

		return UIImage.animatedImage(with: images, duration: duration)
	}
}
