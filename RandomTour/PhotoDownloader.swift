//
//  PhotoDownloader.swift
//

import UIKit

enum PhotoRecordState: Int {
    case New = 0, Downloaded, Failed
}

class PhotoRecord {
    let url: NSURL                  // remote URL
    var state = PhotoRecordState.New
    var image = UIImage.defaultImage
    
    init(url: NSURL) {
        self.url = url
    }
    
    lazy var dateFormatter: NSDateFormatter = {
        // NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .ShortStyle, timeStyle: .NoStyle)
        // yyyy-MM-dd'T'HH:mm:ss'Z
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
    
    lazy var localImageURL: NSURL = {
        //NSSearchPathDirectory.CachesDirectory
        //NSSearchPathDirectory.DocumentDirectory
        let dirURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        return dirURL!.URLByAppendingPathComponent("ImageName")
    }()
    
    lazy var imageName: String = {
        let name = self.url.pathComponents?.last
        return name!
        //let timePrefix = self.dateFormatter.stringFromDate(NSDate()) + "_"
        //return timePrefix + name!
    }()
    
    var imageDataFileLocalURL: NSURL { // local URL
        return self.localImageURL.URLByAppendingPathComponent(self.imageName)
    }
    
    var isImageDataFileExisting: Bool {
        return NSFileManager.defaultManager().fileExistsAtPath(self.imageDataFileLocalURL.absoluteString)
    }
    
    func saveImageDataToLocal(data: NSData) {
        data.writeToURL(self.imageDataFileLocalURL, atomically: true)
    }
}

// Photo download operation
class PhotoDownloader: NSOperation {
    let photoRecord: PhotoRecord
    
    init(photoRecord: PhotoRecord) {
        self.photoRecord = photoRecord
    }
    
    override func main() {
        autoreleasepool {
            if self.cancelled { return }
            
            // support online and offline cases
            let imageData = self.photoRecord.isImageDataFileExisting ? NSData(contentsOfURL: self.photoRecord.imageDataFileLocalURL) : NSData(contentsOfURL: self.photoRecord.url)
            
            if self.cancelled { return }
            
            if let validImageData = imageData {
                if !self.photoRecord.isImageDataFileExisting { self.photoRecord.saveImageDataToLocal(validImageData) }
                self.photoRecord.image = UIImage(data: validImageData)
                self.photoRecord.state = PhotoRecordState.Downloaded
            }
            else {
                self.photoRecord.state = PhotoRecordState.Failed
                //self.photoRecord.image = UIImage(named: "failed")
            }
        }
    }
    
}//EndOperation

extension UIImage {
    class var defaultImage: UIImage? {
        return UIImage(named: "PhotoPlaceholder")
    }
}
