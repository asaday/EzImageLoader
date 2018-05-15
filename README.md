# EzImageLoader

EzImageLoader is easy-to-use library for lading Images over HTTP/HTTPS. EzImageLoader is associated with [EzHTTP](https://github.com/asaday/EzHTTP).

## Features

- Simplest image loading
- Just write shorter code
- Support WebP
- Support GIF format: of course, supporting animated GIFs
- Extending UIImage and UIImageView
- HTTP/HTTPS requests using EzHTTP

## Requirements

- iOS 8.0+
- Xcode 8+ for Swift 3 and EzImageLoader v3.x

If you use Swift 2.x, use EzImageLoader v0.0.x.

## Installation

### CocoaPods
Add EzImageLoader to the dependencies in your Podfile.


```
pod 'EzImageLoader'
```


Sample Podfile is [here](https://github.com/asaday/EzImageLoader/blob/master/exsample/Podfile).




### Carthage
You can also install EzImageLoader with Carthage. Add this line in your Cartfile.


```
github "asaday/EzImageLoader"
```



## Usage

Begin by importing the EzImageLoader

```
import EzImageLoader
```

In addition, import [EzHTTP](https://github.com/asaday/EzHTTP) for creating URLRequest easily.

```
import EzHTTP
```

### Basic 

#### GET

Get for an image.

```
let iv = UIImageView(frame: view.bounds)
ImageLoader.get("https://httpbin.org/image/png") {iv.image = $0.image}
```

Get an image and resizing

```
let mSize = CGSize(width: 200, height: 200)
ImageLoader.get(urlStr, size: mSize) {iv.image = $0.image}
```


#### URLRequest

Get an image with NSURLRequest.  Note that "HTTP.createRequest()" creates URLRequest with EzHTTP.

```
let iv = UIImageView(frame: view.bounds)
let req = HTTP.createRequest(.GET, "https://httpbin.org/image/png", params: [:], headers: [:])
ImageLoader.request(req!) {iv.image = $0.image}
```

Request and resize the image.

```
let mSize = CGSize(width: 200, height: 200)
ImageLoader.request(req!, size:mSize) {iv.image = $0.image}
```

#### Result

You can get some information about a request. ResultReason is enumeration type and gives status of the result. 

- `$0.image` UIImage?
- `$0.reason` enum ResultReason
- `$0.decodeTime` TimeInterval
- `$0.downloadTime` TimeInterval


```
let iv = UIImageView(frame: view.bounds)
let mSize = CGSize(width: 300, height: 200)
ImageLoader.get("https://www.gstatic.com/webp/gallery/4.webp", size: mSize) {
    iv.image = $0.image
    print("Reason", $0.reason)
    print("Decode Time", $0.decodeTime)
    print("Download Time", $0.downloadTime)
}

// Reason downloaded
// Decode Time 0.0499059557914734
// Download Time 0.553457021713257
```

### Async

Async request `.requestASync()` or `.getASyinc()` for using in except main task.

```
let req = HTTP.createRequest(.GET, "https://httpbin.org/image/png", params: [:], headers: [:])
let img1:UIImage? = ImageLoader.requestASync(req!)

let img2:UIImage? = ImageLoader.getASync("https://httpbin.org/image/png")
let img3:UIImage? = ImageLoader.getASync(urlStr, headers: ["Custom-Content":":D"])
```


### UIImageView Extension

EzImageLoader extends UIImageView. It's very simple to use.

```
let iv = UIImageView(frame: view.bounds)
iv.loadURL("https://httpbin.org/image/webp")

// With additional headers
iv.loadURL("https://httpbin.org/image/png", headers: ["Custom-Content":"HAHAHA"])

// Apply Filter
let ilFilter = ImageLoader.Filter.resizer(CGSize(width: 320, height: 320))
iv.loadURL("https://httpbin.org/image/png", filter: ilFilter)
```

Use with URLRequest.

```
let iv = UIImageView(frame: view.bounds)
let req = HTTP.createRequest(.GET, "https://httpbin.org/image/png", params: [:], headers: [:])
iv.loadRequest(req!)

// Apply Filter
let ilFilter = ImageLoader.Filter.resizer(CGSize(width: 280, height: 280))
iv.loadRequest(req!, filter: ilFilter)
```


### UIImage Extension

Resizing a image for UIImage.

```
let img:UIImage = #imageLiteral(resourceName: "SpImage").resize(CGSize(width: 280, height: 280))
```

Get an image as Data and decode to UIImage. You can use animation GIFs and WebPs well.

```
let gifURL = "https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif"
HTTP.get(gifURL) {
    let img = UIImage.decode($0.data!)
    iv.image = img
}
```