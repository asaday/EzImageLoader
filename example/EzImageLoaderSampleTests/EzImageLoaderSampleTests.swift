
// Copyright (c) NagisaWorks asaday
// The MIT License (MIT)

import XCTest
import EzHTTP
import EzImageLoader

class EzImageLoaderSampleTests: XCTestCase {

	var src = "https://httpbin.org/image"

	override func setUp() {
		super.setUp()
		// Put setup code here. This method is called before the invocation of each test method in the class.
	}

	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
		super.tearDown()
	}

	func testGet() {
		let expectation = self.expectation(description: "")
		ImageLoader.get(src + "/png") { res in
			XCTAssertGreaterThanOrEqual(res.reason.rawValue, 0)
			XCTAssertNotNil(res.image)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}

	func testGetJpeg() {
		let expectation = self.expectation(description: "")
		ImageLoader.get(src + "/jpeg") { res in
			XCTAssertGreaterThanOrEqual(res.reason.rawValue, 0)
			XCTAssertNotNil(res.image)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}

	func testGetWebP() {
		let expectation = self.expectation(description: "")
		ImageLoader.get(src + "/webp") { res in
			XCTAssertGreaterThanOrEqual(res.reason.rawValue, 0)
			XCTAssertNotNil(res.image)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}

	func testGetWithResizing() {
		let expectation = self.expectation(description: "")
		let mSize = CGSize(width: 200, height: 200)
		ImageLoader.get(src + "/png", size: mSize) { res in
			XCTAssertGreaterThanOrEqual(res.reason.rawValue, 0)
			XCTAssertNotNil(res.image)
			XCTAssertEqual(res.image?.size, mSize)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}

	func testGetRequest() {
		let expectation = self.expectation(description: "")
		ImageLoader.get(src + "/png") { res in
			XCTAssertGreaterThanOrEqual(res.reason.rawValue, 0)
			XCTAssertNotNil(res.image)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}

	func testGetWithHeader() {
		let expectation = self.expectation(description: "")
		ImageLoader.get(src, headers: ["Accept": "image/jpeg"]) { res in
			XCTAssertGreaterThanOrEqual(res.reason.rawValue, 0)
			XCTAssertNotNil(res.image)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}

	func testUIImageViewLoad() {
		let expectation = self.expectation(description: "")
		let iv = UIImageView(frame: UIScreen.main.bounds)
		iv.loadURL(src + "/png") { view, res in
			XCTAssertGreaterThanOrEqual(res.reason.rawValue, 0)
			XCTAssertNotNil(view.image)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}

	func testUIImageVieLoadWithFilter() {
		let expectation = self.expectation(description: "")
		let mSyze = CGSize(width: 64, height: 64)
		let ilFilter = ImageLoader.Filter.resizer(mSyze)
		let iv = UIImageView(frame: UIScreen.main.bounds)
		iv.loadURL(src + "/png", filter: ilFilter) { view, res in
			XCTAssertGreaterThanOrEqual(res.reason.rawValue, 0)
			XCTAssertNotNil(view.image)
			XCTAssertEqual(view.image?.size, mSyze)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}

	func testUIImageResize() {
		let expectation = self.expectation(description: "")
		ImageLoader.get(src + "/png") { res in
			XCTAssertNotNil(res.image)
			let mSize = CGSize(width: 200, height: 200)
			let img: UIImage? = res.image?.resize(mSize)
			XCTAssertNotNil(img)
			XCTAssertEqual(img?.size, mSize)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}

	func testUiimageDecode() {
		let expectation = self.expectation(description: "")
		HTTP.get(src + "/webp") {
			let img = UIImage.decode($0.dataValue)
			XCTAssertNotNil(img)
			expectation.fulfill()
		}
		waitForExpectations(timeout: 5, handler: nil)
	}
}
