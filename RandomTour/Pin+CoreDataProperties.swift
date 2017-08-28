//
//  Pin+CoreDataProperties.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/14/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {
    
    @NSManaged var latitude: Double         // The pin's latitude
    @NSManaged var longitude: Double        // The pin's longitude
    @NSManaged var isFetchingPhotos: Bool   // is there fetching photos for the pin ?
    @NSManaged var photos: [Photo]?         // [Photo] or NSOrderedSet?, how many photos are belong to this pin ?
    @NSManaged var places: [Place]?         // [Place] or NSOrderedSet?, how many places are belong to this pin ?

}
