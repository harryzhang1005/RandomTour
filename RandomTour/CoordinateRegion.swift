//
//  CoordinateRegion.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/15/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit
import MapKit

// For archiving pins on the map
class CoordinateRegion: NSObject, NSCoding
{
    var mapRegion: MKCoordinateRegion
    
    init(region: MKCoordinateRegion) {
        mapRegion = region
    }
    
    // Note: Designated initializer can't be declared in an extension of 'CoordinateRegion';
    // Initializer requirement 'init(coder:)' can only be satified by a 'required' in the definition of non-final class 'CoordinateRegion'
    required init?(coder aDecoder: NSCoder) { // NS_DESIGNATED_INITIALIZER
        let centerLatitude = aDecoder.decodeDouble(forKey: Constants.RegionCenterLatitude)
        let centerLongitude = aDecoder.decodeDouble(forKey: Constants.RegionCenterLongitude)
        let spanLatitudeDelta = aDecoder.decodeDouble(forKey: Constants.RegionSpanLatitudeDelta)
        let spanlongitudeDelta = aDecoder.decodeDouble(forKey: Constants.RegionSpanLongitudeDelta)
        
        // Struct 'self.mapRegion' must be compelety initialized before a member is stored to
        mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
            span: MKCoordinateSpan(latitudeDelta: spanLatitudeDelta, longitudeDelta: spanlongitudeDelta))
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(mapRegion.center.latitude, forKey: Constants.RegionCenterLatitude)
        aCoder.encode(mapRegion.center.longitude, forKey: Constants.RegionCenterLongitude)
        aCoder.encode(mapRegion.span.latitudeDelta, forKey: Constants.RegionSpanLatitudeDelta)
        aCoder.encode(mapRegion.span.longitudeDelta, forKey: Constants.RegionSpanLongitudeDelta)
    }
    
    fileprivate struct Constants {
        static let RegionCenterLatitude = "RegionCenterLatitude"
        static let RegionCenterLongitude = "RegionCenterLongitude"
        static let RegionSpanLatitudeDelta = "RegionSpanLatitudeDelta"
        static let RegionSpanLongitudeDelta = "RegionSpanLongitudeDelta"
    }

}
