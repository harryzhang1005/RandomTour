//
//  CoordinateRegion.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/15/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit
import MapKit

class CoordinateRegion: NSObject, NSCoding
{
    var mapRegion: MKCoordinateRegion
    
    init(region: MKCoordinateRegion) {
        mapRegion = region
    }
    
    // Note: Designated initializer can't be declared in an extension of 'CoordinateRegion';
    // Iniitializer requirement 'init(coder:)' can only be satified by a 'required' in the definition of non-final class 'CoordinateRegion'
    required init?(coder aDecoder: NSCoder) { // NS_DESIGNATED_INITIALIZER
        let centerLatitude = aDecoder.decodeDoubleForKey(Constants.RegionCenterLatitude)
        let centerLongitude = aDecoder.decodeDoubleForKey(Constants.RegionCenterLongitude)
        let spanLatitudeDelta = aDecoder.decodeDoubleForKey(Constants.RegionSpanLatitudeDelta)
        let spanlongitudeDelta = aDecoder.decodeDoubleForKey(Constants.RegionSpanLongitudeDelta)
        
        // Struct 'self.mapRegion' must be compelety initialized before a member is stored to
        mapRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLatitude, longitude: centerLongitude),
            span: MKCoordinateSpan(latitudeDelta: spanLatitudeDelta, longitudeDelta: spanlongitudeDelta))
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeDouble(mapRegion.center.latitude, forKey: Constants.RegionCenterLatitude)
        aCoder.encodeDouble(mapRegion.center.longitude, forKey: Constants.RegionCenterLongitude)
        aCoder.encodeDouble(mapRegion.span.latitudeDelta, forKey: Constants.RegionSpanLatitudeDelta)
        aCoder.encodeDouble(mapRegion.span.longitudeDelta, forKey: Constants.RegionSpanLongitudeDelta)
    }
    
    private struct Constants {
        static let RegionCenterLatitude = "RegionCenterLatitude"
        static let RegionCenterLongitude = "RegionCenterLongitude"
        static let RegionSpanLatitudeDelta = "RegionSpanLatitudeDelta"
        static let RegionSpanLongitudeDelta = "RegionSpanLongitudeDelta"
    }

}
