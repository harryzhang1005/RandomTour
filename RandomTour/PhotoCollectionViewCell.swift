//
//  PhotoCollectionViewCell.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    var imageCache = [String: UIImage]()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        spinner.color = UIColor.blackColor()
        spinner.hidesWhenStopped = true
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "cleanImageCache", name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
    }
    
    private func cleanImageCache() {
        imageCache.removeAll(keepCapacity: true)
    }
    
    func configCell(photo: Photo)
    {
        if let imageURL = photo.imageURL
        {
            if imageCache.keys.contains(imageURL) && photo.didFetchImageData {
                self.backgroundView = UIImageView(image: imageCache[imageURL])
            } else {
                self.spinner.startAnimating()
                self.backgroundView = UIImageView(image: UIImage(named: "PhotoPlaceholder"))
                
                // NSURLSession download photo
//                if let url = NSURL(string: imageURL) {
//                    NSURLSession.sharedSession().dataTaskWithURL(url) { (data: NSData?, resp: NSURLResponse?, error: NSError?) in
//                        // x
//                    }.resume()
//                }
                
                // GCD Async download photo
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    let imageData = NSData(contentsOfURL: NSURL(string: imageURL)!)
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        if let validImageData = imageData {
                            photo.didFetchImageData = true
                            let cellImage = UIImage(data: validImageData)
                            if !self.imageCache.keys.contains(imageURL) { self.imageCache[imageURL] = cellImage! }
                            self.backgroundView = UIImageView(image: cellImage)
                        } else {
                            photo.didFetchImageData = false
                            self.backgroundView = UIImageView(image: UIImage(named: "NoPhoto"))
                        }
                        
                        self.spinner.stopAnimating()
                    }//mainQ
                }//async
                
            }//not-download-yet
        } else {
            self.backgroundView = UIImageView(image: UIImage(named: "PhotoPlaceholder"))
        }
        
        // for selected state
        let selectedBgView = UIView(frame: self.bounds)
        selectedBgView.backgroundColor = UIColor(red: 255.0, green: 255.0, blue: 255.0, alpha: 0.75)
        
        let checkmark = UIImageView(image: UIImage(named: "Checkmark")) // Note: image name is case sensitive
        //checkmark.frame = CGRect(origin: self.contentView.frame.origin, size: self.frame.size)    // works
        checkmark.frame = self.bounds   // works, real cell item size
        //checkmark.frame = self.frame              // not work, origin not always (0, 0)
        //checkmark.frame = self.contentView.bounds // not work, contentView in IB size (0, 0, 120, 120), here not real item size
        //checkmark.frame = self.contentView.frame  // not work, contentView in IB size
        
        // Note: debug is case sensitive
        #if DEBUG
            //print("cell bounds: \(NSStringFromCGRect(self.bounds)), cell frame: \(NSStringFromCGRect(self.frame))")
            //print("contentView bounds: \(NSStringFromCGRect(self.contentView.bounds)), contentView frame: \(NSStringFromCGRect((self.contentView.frame)))")
        #endif
        
        checkmark.contentMode = UIViewContentMode.BottomRight
        
        selectedBgView.addSubview(checkmark)
        self.selectedBackgroundView = selectedBgView
    }
    
}
