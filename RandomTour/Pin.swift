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
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    init(latitude: Double, longitude: Double, insertIntoManagedObjectContext context: NSManagedObjectContext) {
        let aEntity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: aEntity!, insertIntoManagedObjectContext: context)
        
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
    
    private func deleteLocalImageDataFile(photo: Photo) {
        if let photoRecord = photo.photoRecord {
            photoRecord.deleteImageDataFile()
        }
    }
}//EndClass

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
    
    private func formatNumberToString(num: Double) -> String {
        return String(format: "%.2f", num)
    }
}
