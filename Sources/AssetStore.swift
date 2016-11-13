//
//  AssetStore.swift
//  HLSion
//
//  Created by hyde on 2016/11/12.
//  Copyright © 2016年 r-plus. All rights reserved.
//

import Foundation

internal struct AssetStore {
    
    private static var shared: [String: String] = {
        if FileManager.default.fileExists(atPath: storeURL.path) {
            return NSDictionary(contentsOf: storeURL) as! [String : String]
        }
        return [:]
    }()
    
    private static let storeURL: URL = {
        let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0]
        return URL(fileURLWithPath: library).appendingPathComponent("HLSion").appendingPathExtension("plist")
    }()
    
    static func allMap() -> [String: String] {
        return shared
    }
    
    static func path(forName: String) -> String? {
        if let path = shared[forName] {
            return path
        }
        return nil
    }
    
    @discardableResult
    static func set(path: String, forName: String) -> Bool {
        shared[forName] = path
        let dict = shared as NSDictionary
        return dict.write(to: storeURL, atomically: true)
    }
    
    @discardableResult
    static func remove(forName: String) -> Bool {
        guard let _ = shared.removeValue(forKey: forName) else { return false }
        let dict = shared as NSDictionary
        return dict.write(to: storeURL, atomically: true)
    }
}
