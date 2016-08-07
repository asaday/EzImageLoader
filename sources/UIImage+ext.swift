
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)

import UIKit
import ImageIO
//import webp

public extension UIImage {

	public func resize(size: CGSize, fill: Bool = true) -> UIImage {
		if size.width <= 0 || size.height <= 0 || size.width <= 0 || size.height <= 0 { return self }

		let xz = size.width / size.width
		let yz = size.height / size.height
		let z = ((xz < yz) != fill) ? xz : yz
		let twidth = ceil(size.width * z)
		let theight = ceil(size.height * z)
		let tx = floor((size.width - twidth)) / 2
		let ty = floor((size.height - theight)) / 2
		let rc = CGRect(x: tx, y: ty, width: twidth, height: theight)

		UIGraphicsBeginImageContextWithOptions(size, false, 0)
		let ctx = UIGraphicsGetCurrentContext()
		CGContextTranslateCTM(ctx, 0, size.height)
		CGContextScaleCTM(ctx, 1, -1)
		CGContextDrawImage(ctx, rc, CGImage)
		let ret = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return ret
	}

	public static func decode(data: NSData, memorized: Bool = true) -> UIImage? {
		if isWebpFormat(data) {
			return webpConv(data)
		}

		if isGIFFormat(data) {
			return gifImage(data)
		}

		guard let image = UIImage(data: data) else { return nil }

		if memorized == false { return image }

		// extract
		guard let imageRef: CGImageRef = image.CGImage else { return image }
		let alpha: CGImageAlphaInfo = CGImageGetAlphaInfo(imageRef)
		if alpha == .First || alpha == .Last || alpha == .PremultipliedFirst || alpha == .PremultipliedLast { return image }

		UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
		let ctx = UIGraphicsGetCurrentContext()

		CGContextTranslateCTM(ctx, 0, image.size.height)
		CGContextScaleCTM(ctx, 1, -1)
		CGContextDrawImage(ctx, CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height), image.CGImage)
		let ret = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return ret
	}

	static func isWebpFormat(data: NSData) -> Bool {
		if data.length < 16 { return false }
		let riff: [UInt8] = [0x52, 0x49, 0x46, 0x46]
		let webp: [UInt8] = [0x57, 0x45, 0x42, 0x50]
		return (memcmp(data.bytes, riff, 4) == 0 && memcmp(data.bytes + 8, webp, 4) == 0)
	}

	static func isGIFFormat(data: NSData) -> Bool {
		if data.length < 4 { return false }
		let gif: [UInt8] = [0x47, 0x49, 0x46]
		return (memcmp(data.bytes, gif, 3) == 0)
	}

	static func gifImage(data: NSData) -> UIImage? {
		guard let imgSource = CGImageSourceCreateWithData(data as CFDataRef, nil) else { return nil }
		let count = CGImageSourceGetCount(imgSource)

		var images: [UIImage] = []
		for i in 0 ..< count {
			if let ref: CGImageRef = CGImageSourceCreateImageAtIndex(imgSource, i, nil), img: UIImage = UIImage(CGImage: ref) {
				images.append(img)
			}
		}
		if images.count == 0 { return nil }

		return UIImage.animatedImageWithImages(images, duration: 0.5)
	}
}
