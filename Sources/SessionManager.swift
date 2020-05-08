//
//  SessionManager.swift
//  HLSion
//
//  Created by hyde on 2016/11/12.
//  Copyright © 2016年 r-plus. All rights reserved.
//

import Foundation
import AVFoundation

final internal class SessionManager: NSObject, AVAssetDownloadDelegate {
    // MARK: Properties
    
    static let shared = SessionManager()
    
    internal let homeDirectoryURL = URL(fileURLWithPath: NSHomeDirectory())
    private var session: AVAssetDownloadURLSession!
    internal var downloadingMap = [AVAssetDownloadTask : HLSion]()
    
    // MARK: Intialization
    
    override private init() {
        super.init()
        let configuration = URLSessionConfiguration.background(withIdentifier: "jp.HLSion.configuration")
        session = AVAssetDownloadURLSession(configuration: configuration,
                                                            assetDownloadDelegate: self,
                                                            delegateQueue: OperationQueue.main)
        restoreDownloadsMap()
    }
    
    // MARK: Method
    
    private func restoreDownloadsMap() {
        session.getAllTasks { tasksArray in
            for task in tasksArray {
                guard let assetDownloadTask = task as? AVAssetDownloadTask, let hlsionName = task.taskDescription else { break }
                
                let hlsion = HLSion(asset: assetDownloadTask.urlAsset, description: hlsionName)
                self.downloadingMap[assetDownloadTask] = hlsion
            }
        }
    }
    
    func downloadStream(_ hlsion: HLSion) {
        guard assetExists(forName: hlsion.name) == false else { return }
        
        guard let task = session.makeAssetDownloadTask(asset: hlsion.urlAsset, assetTitle: hlsion.name, assetArtworkData: nil, options: [AVAssetDownloadTaskMinimumRequiredMediaBitrateKey: 265_000]) else { return }
        
        task.taskDescription = hlsion.name
        downloadingMap[task] = hlsion
        
        task.resume()
    }
    
//    func downloadAdditional(media: AVMutableMediaSelection, hlsion: HLSion) {
//        guard assetExists(forName: hlsion.name) == true else { return }
//        
//        let options = [AVAssetDownloadTaskMediaSelectionKey: media]
//        guard let task = session.makeAssetDownloadTask(asset: hlsion.urlAsset, assetTitle: hlsion.name, assetArtworkData: nil, options: options) else { return }
//        
//        task.taskDescription = hlsion.name
//        downloadingMap[task] = hlsion
//        
//        task.resume()
//    }
    
    func cancelDownload(_ hlsion: HLSion) {
        downloadingMap.first(where: { $1 == hlsion })?.key.cancel()
    }
    
    func deleteAsset(forName: String) throws {
        guard let relativePath = AssetStore.path(forName: forName) else { return }
        let localFileLocation = homeDirectoryURL.appendingPathComponent(relativePath)
        try FileManager.default.removeItem(at: localFileLocation)
        AssetStore.remove(forName: forName)
    }
    
    func assetExists(forName: String) -> Bool {
        guard let relativePath = AssetStore.path(forName: forName) else { return false }
        let filePath = homeDirectoryURL.appendingPathComponent(relativePath).path
        return FileManager.default.fileExists(atPath: filePath)
    }
    
    // MARK: AVAssetDownloadDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let task = task as? AVAssetDownloadTask , let hlsion = downloadingMap.removeValue(forKey: task) else { return }
        
        if let error = error as NSError? {
            switch (error.domain, error.code) {
            case (NSURLErrorDomain, NSURLErrorCancelled):
                // hlsion.result as success when cancelled.
                guard let localFileLocation = AssetStore.path(forName: hlsion.name) else { return }
                
                do {
                    let fileURL = homeDirectoryURL.appendingPathComponent(localFileLocation)
                    try FileManager.default.removeItem(at: fileURL)
                } catch {
                    print("An error occured trying to delete the contents on disk for \(hlsion.name): \(error)")
                }
                
            case (NSURLErrorDomain, NSURLErrorUnknown):
                hlsion.result = .failure(error)
                fatalError("Downloading HLS streams is not supported in the simulator.")
                
            default:
                hlsion.result = .failure(error)
                print("An unexpected error occured \(error.domain)")
            }
        } else {
            hlsion.result = .success
        }
        switch hlsion.result! {
        case .success:
            hlsion.finishClosure?(AssetStore.path(forName: hlsion.name)!)
        case .failure(let err):
            hlsion.errorClosure?(err)
        }
    }
    
    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didFinishDownloadingTo location: URL) {
        
        guard let hlsion = downloadingMap[assetDownloadTask] else { return }
        AssetStore.set(path: location.relativePath, forName: hlsion.name)
    }
    
    func urlSession(_ session: URLSession,
                    assetDownloadTask: AVAssetDownloadTask,
                    didLoad timeRange: CMTimeRange,
                    totalTimeRangesLoaded loadedTimeRanges: [NSValue],
                    timeRangeExpectedToLoad: CMTimeRange) {
        guard let hlsion = downloadingMap[assetDownloadTask] else { return }
        hlsion.result = nil
        guard let progressClosure = hlsion.progressClosure else { return }
        
        let percentComplete = loadedTimeRanges.reduce(0.0) {
            let loadedTimeRange : CMTimeRange = $1.timeRangeValue
            return $0 + CMTimeGetSeconds(loadedTimeRange.duration) / CMTimeGetSeconds(timeRangeExpectedToLoad.duration)
        }
        
        progressClosure(percentComplete)
    }
    
//    func urlSession(_ session: URLSession, assetDownloadTask: AVAssetDownloadTask, didResolve resolvedMediaSelection: AVMediaSelection) {
//        if assetDownloadTask.taskDescription == "jp.HLSion.dummy" {
//            guard let hlsion = downloadingMap[assetDownloadTask] else { return }
//            hlsion.resolvedMediaSelection = resolvedMediaSelection
//            assetDownloadTask.cancel()
//        }
//    }
}
