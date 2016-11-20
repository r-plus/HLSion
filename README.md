# HLSion

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

HTTP Live Streaming (HLS) download manager to offline playback.

## Requirements

- iOS 10.0+
- Xcode 8.0+
- Swift 3.0+

## Installation

Add below to your `Cartfile`.

```ogdl
github "r-plus/HLSion" "master"
```

Thus build framework.

```bash
carthage update HLSion
```

## Usage

```swift
import HLSion

let url = URL(string: "https://...m3u8")!
let hlsion = HLSion(url: url, name: "identifier").download { (progressPercentage) in
    // call while each file downloaded.
}.finish { (relativePath) in
    // call when complete or cancel download task finish.
}.onError { (error) in
    // call when error finish.
}

// cancelable.
hlsion.cancelDownload()

// delete downloaded asset.
hlsion.deleteAsset()
```

Play after download.

```swift
guard let localUrl = hlsion.localUrl else {
    // This instance not yet downloaded.
    return
}
let localAsset = AVURLAsset(url: localUrl)
let playerItem = AVPlayerItem(asset: localAsset)
let player = AVPlayer(playerItem: playerItem)
player.play()
```

