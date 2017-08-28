//
//  Pin.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject
{
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }

    init(latitude: Double, longitude: Double, insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let aEntity = NSEntityDescription.entity(forEntityName: "Pin", in: context)
        super.init(entity: aEntity!, insertInto: context)
        
        self.latitude = latitude
        self.longitude = longitude
        self.isFetchingPhotos = false
    }
    
    // Still need clean image files
    func cleanImages() {
        if let photos = self.photos {
            for photo in photos {
                deleteLocalImageDataFile(photo)
            }
        }
    }
    
    fileprivate func deleteLocalImageDataFile(_ photo: Photo) {
        if let photoRecord = photo.photoRecord {
            photoRecord.deleteImageDataFile()
        }
    }
}//EndClass

// Pin on the map
extension Pin: MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set { // for draggable pin
            latitude = newValue.latitude
            longitude = newValue.longitude
        }
    }
    
    // Title and subtitle for use by selection UI.
    var title: String? { return "Hello, there" }
    var subtitle: String? { return "(\(formatNumberToString(latitude)), \(formatNumberToString(longitude)))" }
    
    fileprivate func formatNumberToString(_ num: Double) -> String {
        return String(format: "%.2f", num)
    }
}
