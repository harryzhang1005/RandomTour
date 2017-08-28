//
//  GooglePlacesClient.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit

// Use Google Places REST API to get random places
class GooglePlacesClient: HttpRequestAPI
{
    static let sharedInstance = GooglePlacesClient()
    
    // https://developers.google.com/places/
    
    fileprivate struct Constants {
        static let GPlaceBaseURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"
        //static let GPlaceRestApiKey = "AIzaSyBgzcqjTytyNsnoMdcjZ-PN0z8NGUMddPI" // my key not work yet, why?
        static let GPlaceRestApiKey = "AIzaSyD8dG0xSBBakjEZtZyFm_MeJkA536dyVuM" // 3rd Key works
        static let GPlaceRadius = 10_000 // max 50_000
    }

    override init() {
        super.init()
        super.additionalURLParams = ["key": Constants.GPlaceRestApiKey as AnyObject]
    }
    
    func getGooglePlacesByPin(withPin pin: Pin, compHandler: @escaping CompHandler)
    {
        let params: [String:AnyObject] = [
            "location": "\(pin.latitude),\(pin.longitude)" as AnyObject,
            "radius": Constants.GPlaceRadius as AnyObject
        ]
        let url = Constants.GPlaceBaseURL + urlAddParams(params)
        
        httpRequest(url) { result, error in
            if error != nil {
                compHandler(nil, error)
            } else {
                if let jsonPlacesArray = result!["results"] as? NSArray {
                    var placeProps = [[String:String]]()
                    for jsonPlace in jsonPlacesArray
                    {
                        if let place = self.jsonParamsToPlaceProperties(jsonPlace as! NSDictionary) {
                            placeProps.append(place)
                        }
                    }
                    compHandler(placeProps, nil)
                } else {
                    let error = self.generateError("Couldn't get Google Places right now. Please try a different location.")
                    compHandler(nil, error)
                }
            }
        }//http
    }
    
    // MARK: - Privates
    
    fileprivate func jsonParamsToPlaceProperties(_ jsonData: NSDictionary) -> [String:String]?
    {
        if let placeName = jsonData["name"] as? String, let vicinity = jsonData["vicinity"] as? String {
            // Google Places may return the first object as the place itself, ignore it
            if placeName != vicinity {
                // Such as, ["vicinity": "200 Eastern Parkway, Brooklyn", "name": "Brooklyn Museum"]
                return ["name": placeName, "vicinity": vicinity]
            }
        }
        return nil
    }
    
    fileprivate func generateError(_ desc: String) -> NSError {
        var dict = [AnyHashable: Any]()
        dict[NSLocalizedDescriptionKey] = desc
        
        //NSError(domain: String, code: Int, userInfo: [NSObject : AnyObject]?)
        let error = NSError(domain: "FetchGooglePlaces", code: 111, userInfo: dict)
        return error
    }
    
}//EndClass
