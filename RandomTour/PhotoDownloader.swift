//
//  PhotoDownloader.swift
//
//  Created by Harvey Zhang on 1/15/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit

enum PhotoRecordState: Int {
    case new = 0, downloaded, failed
}

extension UIImage {
	class var defaultImage: UIImage? {
		return UIImage(named: "PhotoPlaceholder")
	}
}

class PhotoRecord {
    let url: URL						// remote URL
    var state = PhotoRecordState.new
    var image = UIImage.defaultImage
    
    init(url: URL) {
        self.url = url
    }
    
    lazy var dateFormatter: DateFormatter = {
        // NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .ShortStyle, timeStyle: .NoStyle)
        // yyyy-MM-dd'T'HH:mm:ss'Z
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
    
    lazy var localImageURL: URL = {
        //NSSearchPathDirectory.CachesDirectory, NSSearchPathDirectory.DocumentDirectory
        let dirURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return dirURL!.appendingPathComponent("ImageName")
    }()
    
    lazy var imageName: String = {
        let name = self.url.pathComponents.last
        return name!
        //let timePrefix = self.dateFormatter.stringFromDate(NSDate()) + "_"
        //return timePrefix + name!
    }()
    
    var imageDataFileLocalURL: URL { // local URL
        return self.localImageURL.appendingPathComponent(self.imageName)
    }
    
    var isImageDataFileExisting: Bool {
        //print("url.path: \(imageDataFileLocalURL.path!)")                       /* /Users/MacBook/.../image.jpg */
        //print("url.absoluteString: \(imageDataFileLocalURL.absoluteString)")    /* file:///Users/MacBook/.../image.jpg */
        return FileManager.default.fileExists(atPath: self.imageDataFileLocalURL.path)
    }
    
    func saveImageDataToLocal(_ data: Data) {
        try? data.write(to: self.imageDataFileLocalURL, options: [.atomic])
    }
    
    func deleteImageDataFile() {
        if isImageDataFileExisting {
            do {
                try FileManager.default.removeItem(at: self.imageDataFileLocalURL)
                self.state = PhotoRecordState.new
            } catch {
                print("Delete local image data file failed!")
            }
        }
    }
	
}//EndClass

// Photo download operation
class PhotoDownloader: Operation {
	
    let photoRecord: PhotoRecord
    
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        autoreleasepool {
            if self.isCancelled { return }
            
            // support both online and offline
            let imageData = self.photoRecord.isImageDataFileExisting ? (try? Data(contentsOf: self.photoRecord.imageDataFileLocalURL)) : (try? Data(contentsOf: self.photoRecord.url))
            
            if self.isCancelled { return }
            
            if let validImageData = imageData {
                if !self.photoRecord.isImageDataFileExisting {
					self.photoRecord.saveImageDataToLocal(validImageData)
				}
                self.photoRecord.image = UIImage(data: validImageData)
                self.photoRecord.state = PhotoRecordState.downloaded
            }
            else {
                self.photoRecord.state = PhotoRecordState.failed
                //self.photoRecord.image = UIImage(named: "failed")
            }
        }
    }
    
}//EndOperation
