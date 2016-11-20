//
//  HLSion.swift
//  HLSion
//
//  Created by hyde on 2016/11/12.
//  Copyright © 2016年 r-plus. All rights reserved.
//

import Foundation
import AVFoundation

public typealias ProgressParameter = (Double) -> Void
public typealias FinishParameter = (String) -> Void
public typealias ErrorParameter = (Error) -> Void

    enum Result {
        case success
        case failure(Error)
    }

public class HLSion {
    
    public enum State: String {
        case notDownloaded
        case downloading
        case downloaded
    }
    
    // MARK: Properties
    
    /// Identifier name.
    public let name: String
    /// Target AVURLAsset that have HLS URL.
    public let urlAsset: AVURLAsset
    /// Local url path that saved for offline playback. return nil if not downloaded.
    public var localUrl: URL? {
        guard let relativePath = AssetStore.path(forName: name) else { return nil }
        return SessionManager.shared.homeDirectoryURL.appendingPathComponent(relativePath)
    }
    /// Download state.
    public var state: State {
        if SessionManager.shared.assetExists(forName: name) {
            return .downloaded
        }
        if let _ = SessionManager.shared.downloadingMap.first(where: { $1 == self }) {
            return .downloading
        }
        return .notDownloaded
    }
    /// File size of downloaded HLS asset.
    public var offlineAssetSize: UInt64 {
        guard state == .downloaded else { return 0 }
        guard let relativePath = AssetStore.path(forName: name) else { return 0 }
        let bundleURL = SessionManager.shared.homeDirectoryURL.appendingPathComponent(relativePath)
        guard let subpaths = try? FileManager.default.subpathsOfDirectory(atPath: bundleURL.path) else { return 0 }
        let size: UInt64 = subpaths.reduce(0) {
            let filePath = bundleURL.appendingPathComponent($1).path
            guard let fileAttribute = try? FileManager.default.attributesOfItem(atPath: filePath) else { return $0 }
            guard let size = fileAttribute[FileAttributeKey.size] as? NSNumber else { return $0 }
            return $0 + size.uint64Value
        }
        return size
    }
    
    internal var result: Result?
    internal var progressClosure: ProgressParameter?
    internal var finishClosure: FinishParameter?
    internal var errorClosure: ErrorParameter?
//    internal var resolvedMediaSelection: AVMediaSelection?
    
    // MARK: Intialization
    
    internal init(asset: AVURLAsset, description: String) {
        name = description
        urlAsset = asset
    }
    
    /// Initialize HLSion
    ///
    /// - Parameters:
    ///   - url: HLS(m3u8) URL.
    ///   - options: AVURLAsset options.
    ///   - name: Identifier name.
    public convenience init(url: URL, options: [String: Any]? = nil, name: String) {
        let urlAsset = AVURLAsset(url: url, options: options)
        self.init(asset: urlAsset, description: name)
    }
    
    // MARK: Method
    
    /// Restore downloading tasks. You should call this method in AppDelegate.
    public static func restoreDownloadsTasks() {
        _ = SessionManager.shared
    }
    
    /// Start download HLS stream data as asset. Should delete asset when you want to re-download HLS stream, simply ignore if exist same HLSion.
    ///
    /// - Parameter closure: Progress closure.
    /// - Returns: Chainable self instance.
    @discardableResult
    public func download(progress closure: ProgressParameter? = nil) -> Self {
        progressClosure = closure
        SessionManager.shared.downloadStream(self)
        return self
    }
    
    /// Set progress closure.
    ///
    /// - Parameter closure: Progress closure that will invoke when download each time range files.
    /// - Returns: Chainable self instance.
    @discardableResult
    public func progress(progress closure: @escaping ProgressParameter) -> Self {
        progressClosure = closure
        return self
    }
    
    /// Set finish(success) closure.
    ///
    /// - Parameter closure: Finish closure that will invoke when successfully finished download media.
    /// - Returns: Chainable self instance.
    @discardableResult
    public func finish(relativePath closure: @escaping FinishParameter) -> Self {
        finishClosure = closure
        if let result = result, case .success = result {
            closure(AssetStore.path(forName: name)!)
        }
        return self
    }
    
    /// Set failure closure.
    ///
    /// - Parameter closure: Finish closure that will invoke when failure finished download media.
    /// - Returns: Chainable self instance.
    @discardableResult
    public func onError(error closure: @escaping ErrorParameter) -> Self {
        errorClosure = closure
        if let result = result, case .failure(let err) = result {
            closure(err)
        }
        return self
    }
    
    /// Cancel download.
    public func cancelDownload() {
        SessionManager.shared.cancelDownload(self)
    }
    
    /// Delete local stored HLS asset.
    ///
    /// - Throws: FileManager file delete exception.
    public func deleteAsset() throws {
        try SessionManager.shared.deleteAsset(forName: name)
    }
    
    /// Additional downloadable media selection group and option. Return empty array if not yet download to local or completly downloaded all medias.
    ///
    /// - Returns: media group and options.
//    public func downloadableAdditionalMedias() -> [(AVMediaSelectionGroup, AVMediaSelectionOption)] {
//        var result = [(AVMediaSelectionGroup, AVMediaSelectionOption)]()
//        guard let assetCache = urlAsset.assetCache else { return result }
//        
//        let mediaCharacteristics = [AVMediaCharacteristicAudible, AVMediaCharacteristicLegible]
//        
//        for mediaCharacteristic in mediaCharacteristics {
//            guard let mediaSelectionGroup = urlAsset.mediaSelectionGroup(forMediaCharacteristic: mediaCharacteristic) else { continue }
//            let savedOptions = assetCache.mediaSelectionOptions(in: mediaSelectionGroup)
//            for option in mediaSelectionGroup.options where !savedOptions.contains(option) {
//                result.append((mediaSelectionGroup, option))
//            }
//        }
//        
//        return result
//    }
    
    /// Download additional media.
    ///
    /// - Parameter media: Selected pair from `downloadableAdditionalMedias`
    /// - Returns: Chainable self instance. WARN: progress and finish closures are shared.
//    @discardableResult
//    public func downloadAdditional(media: (AVMediaSelectionGroup, AVMediaSelectionOption)) -> Self {
//        guard state == .downloaded else { return self }
//        completed = false
//        let dummy = HLSion(url: urlAsset.url, name: "jp.HLSion.dummy")
//        dummy.download(progress: { (percent) in
//            print(percent)
//        }).finish { [weak dummy] _ in
//            guard let dummyMediaSelection = dummy?.resolvedMediaSelection else { return }
//            let mediaSelection = dummyMediaSelection.mutableCopy() as! AVMutableMediaSelection
//            mediaSelection.select(media.1, in: media.0)
//            
//            SessionManager.shared.downloadAdditional(media: mediaSelection, hlsion: self)
//        }
//        return self
//    }
}

extension HLSion: Equatable {}

public func == (lhs: HLSion, rhs: HLSion) -> Bool {
    return (lhs.name == rhs.name) && (lhs.urlAsset == rhs.urlAsset)
}

extension HLSion: CustomStringConvertible {
    
    public var description: String {
        return "\(name), \(urlAsset.url)"
    }
}
