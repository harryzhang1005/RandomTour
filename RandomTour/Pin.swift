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

class Pin: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }

    // Create Core Data
    init(lati: Double, long: Double) {
        let context = CoreDataStackManager.sharedInstance.managedObjectContext
        let entityDesc = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)
        super.init(entity: entityDesc!, insertIntoManagedObjectContext: context)
        
        self.latitude = lati
        self.longitude = long
        self.isFetchingPhotos = false
    }
    
}

extension Pin: MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set { // draggable pin also need set
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
