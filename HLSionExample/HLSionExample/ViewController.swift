//
//  ViewController.swift
//  HLSionExample
//
//  Created by hyde on 2016/11/13.
//  Copyright © 2016年 r-plus. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation
import HLSion

class ViewController: UITableViewController {

    var sources = [HLSion]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // https://developer.apple.com/streaming/examples/
        sources.append(HLSion(url: URL(string: "https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8")!, name: "Sample HLS"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as! Cell
        let hlsion = sources[indexPath.row]
        cell.progressView.isHidden = true
        cell.titleLabel.text = hlsion.name
        cell.subLabel.text = hlsion.state.rawValue
        cell.sizeLabel.text = hlsion.offlineAssetSize == 0 ? nil : "\(hlsion.offlineAssetSize / 1024 / 1024)MB"
//        cell.accessoryType = hlsion.state == .downloaded ? .detailButton : .none
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let hlsion = sources[indexPath.row]
        switch hlsion.state {
        case .notDownloaded:
            let cell = tableView.cellForRow(at: indexPath) as! Cell
            cell.progressView.isHidden = false
            cell.progressView.progress = 0
            hlsion.download { (percent) in
                DispatchQueue.main.async {
                    print(percent)
                    cell.subLabel.text = hlsion.state.rawValue
                    cell.progressView.progress = Float(percent)
                }
            }.finish { (relativePath) in
                DispatchQueue.main.async {
                    tableView.reloadData()
                    print(relativePath)
                }
            }
        case .downloading:
            break
        case .downloaded:
            performSegue(withIdentifier: "AVPlayerViewControllerSegue", sender: hlsion)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        
        guard let playerViewControler = segue.destination as? AVPlayerViewController else { return }
        guard let hlsion = sender as? HLSion else { return }
        let playerItem = AVPlayerItem(asset: hlsion.urlAsset)
        let player = AVPlayer(playerItem: playerItem)
        playerViewControler.player = player
    }
    
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
//    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
//        guard let cell = tableView.cellForRow(at: indexPath) as? Cell else { return }
//        
//        let hlsion = sources[indexPath.row]
//        guard hlsion.state == .downloaded else { return }
//        let availables = hlsion.downloadableAdditionalMedias()
//        
//        let alertController = UIAlertController(title: hlsion.name, message: "Select from the following options:", preferredStyle: .actionSheet)
//        availables.forEach { (group, option) in
//            let alertAction = UIAlertAction(title: "Download \(option.displayName)", style: .default) { _ in
//                hlsion.downloadAdditional(media: (group, option)).progress { (progress) in
//                    print(progress)
//                }.finish { (path) in
//                    print("-------------Additional download finish.")
//                    print(path)
//                }
//            }
//            alertController.addAction(alertAction)
//        }
//        alertController.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
//        
//        if UIDevice.current.userInterfaceIdiom == .pad {
//            guard let popoverController = alertController.popoverPresentationController else {
//                return
//            }
//            
//            popoverController.sourceView = cell
//            popoverController.sourceRect = cell.bounds
//        }
//        
//        present(alertController, animated: true, completion: nil)
//    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: { action, indexPath in
            let hlsion = self.sources[indexPath.row]
            guard hlsion.state == .downloaded else { return }
            try! hlsion.deleteAsset()
            tableView.reloadData()
        })
        return [deleteAction]
    }
}
