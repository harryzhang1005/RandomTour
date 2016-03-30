//
//  FlickrClient.swift
//  RandomTour
//
//  Created by Harvey Zhang on 1/13/16.
//  Copyright © 2016 HappyGuy. All rights reserved.
//

import UIKit

// Use Flickr REST API to get randomly photos
class FlickrClient: HttpRequestAPI
{
    static let sharedInstance = FlickrClient()
    
    private struct Constants {
        static let FlickrBaseURL = "https://api.flickr.com/services/rest/"
        static let FlickrPhotoSourceURL = "https://farm{farmId}.staticflickr.com/{serverId}/{photoId}_{secret}_{imageSize}.jpg"
        static let FlickrRestApiKey = "67fda1c0b25a2d0f325990f46d42fbb2"    // 3rd key
        static let FlickrPhotosPerPage = 24 // 24, 50
        static let FlickrMaxNumberOfResultsReturned = 4000
        
        // https://www.flickr.com/services/api/flickr.photos.search.html
        static let FlickrPhotoSearch = "flickr.photos.search"
        
        static let BboxEdge = 0.1
        
        static let MinimumPhotoPagesDiff = 300
    }
    
    private struct ImageSize {
        static let SmallSquare = "s"
        static let LargeSquare = "q"
        static let Thumbnail = "t"
        static let Small240 = "m"
        static let Small320 = "n"
        static let Medium500 = "-"
        static let Medium640 = "z"
        static let Medium800 = "c"
        static let Large1024 = "b"
        static let Large1600 = "h"
        static let Large2048 = "k"
        static let Original = "o"
    }
    
    private var currentPageNumber: Int?
    
    override init() {
        super.init()
        super.additionalURLParams = [
            "api_key": Constants.FlickrRestApiKey,
            "format": "json",
            "nojsoncallback": 1,
            "safe_search": 1            // for safe
        ]
    }
    
    // per_page (Optional) : Number of photos to return per page. If this argument is omitted, it defaults to 100. The maximum allowed value is 500.
    // page (Optional) : The page of results to return. If this argument is omitted, it defaults to 1.
    func getFlickrPhoto(withPin pin: Pin, compHandler: CompHandler)
    {
        let bboxParams = getBboxParams(pin.latitude, long: pin.longitude)
        
        photoSearchGetRandomPage(bboxParams) { randomPage, error in
            if error != nil {
                compHandler(result: nil, error: error)
            }
            else if let randomPageNum = randomPage {
                let urlParams: [String:AnyObject] = [
                    "method": Constants.FlickrPhotoSearch,
                    "bbox": bboxParams,
                    "per_page": Constants.FlickrPhotosPerPage,
                    "page": randomPageNum
                ]
                let url = Constants.FlickrBaseURL + self.urlAddParams(urlParams)
                //print("final url: \(url)")
                self.httpRequest(url) { (result, error) -> Void in
                    if error != nil {
                        compHandler(result: nil, error: error)
                    } else {
                        if let result = result, jsonPhotosDict = result["photos"] as? NSDictionary {
                            if let jsonPhotoArray = jsonPhotosDict["photo"] as? NSArray
                            {
                                var photoProps = [[String:String]]()
                                for jsonPhoto in jsonPhotoArray {
                                    let photo = self.photoParamsToProperties(jsonPhoto as! NSDictionary)
                                    if photo != nil {
                                        photoProps.append(photo!)
                                    }
                                }
                                compHandler(result: photoProps, error: nil)
                            } else {
                                let error = self.generateError("Couldn't get photo right now. Please try a different location.")
                                compHandler(result: nil, error: error)
                            }
                        } else {
                            let error = self.generateError("Couldn't get photo right now. Please try a different location.")
                            compHandler(result: nil, error: error)
                        }
                    }
                }//httpClosure
            } else {
                compHandler(result: nil, error: nil)
            }
        }
    }
    
    // MARK: - Privates
    
    private func generateError(desc: String) -> NSError {
        var dict = [NSObject:AnyObject]()
        dict[NSLocalizedDescriptionKey] = desc
        
        //NSError(domain: String, code: Int, userInfo: [NSObject : AnyObject]?)
        let error = NSError(domain: "FetchFlickrPhotos", code: 110, userInfo: dict)
        return error
    }
    
    private func photoSearchGetRandomPage(bboxParam: String, completionHandler: (randomPage: Int?, error: NSError?) -> Void)
    {
        let urlParams: [String:AnyObject] = [
            "method": Constants.FlickrPhotoSearch,
            "bbox": bboxParam,
            "per_page": 1   // get 1 result per page as we only want the "total" figure to generate a random page number
        ]
        
        let url = Constants.FlickrBaseURL + urlAddParams(urlParams)
        httpRequest(url) { result, error in
            if error != nil {
                completionHandler(randomPage: nil, error: error)
            } else {
                if let photos = result!["photos"] as? NSDictionary {
                    if let totalPagesCount = Int( (photos["total"] as? String)! ) {
                        if totalPagesCount > 0 {
                            let randomPageNumber = self.getRandomPageNumber(maxX: UInt32(totalPagesCount))
                            completionHandler(randomPage: randomPageNumber, error: nil)
                        } else {
                            print("Couldn't get a random page number. Please try again later or try a different location.")
                        }
                    } else { print("No total pages count") }
                } else { print("No photos") }
            }
        }
    }
    
    /* jsonPhoto dictionary sample:
        {
            farm = 2;
            id = 23752557533;
            isfamily = 0;
            isfriend = 0;
            ispublic = 1;
            owner = "50871308@N08";
            secret = 69419552cd;
            server = 1573;
            title = "Evening in Abdij van Park III";
        }
    */
    private func photoParamsToProperties(jsonPhoto: NSDictionary) -> [String:String]?
    {
        if let photoId = jsonPhoto["id"] as? String, secret = jsonPhoto["secret"] as? String,
            serverId = jsonPhoto["server"] as? String, farmId = jsonPhoto["farm"] as? Int {
                let imageSize = ImageSize.LargeSquare
                let photoParams: [String:String] = [
                    "photoId": photoId,
                    "secret": secret,
                    "serverId": serverId,
                    "farmId": "\(farmId)",
                    "imageSize": imageSize
                ]
                let imageName = "\(photoId)_\(secret)_\(imageSize).jpg"
                let imageURL = self.urlReplaceKey(Constants.FlickrPhotoSourceURL, params: photoParams)
                return ["imageName": imageName, "imageURL": imageURL]
        }
        
        return nil
    }
    
    /*
    Latitude measurements range from 0° to (+/–)90°. Equator is 0°.
    Longitude measures how far east or west of the prime meridian a place is located. The prime meridian runs through Greenwich, England. Longitude measurements range from 0° to (+/–)180°.
    
    bbox (Optional) : A comma-delimited list of 4 values defining the Bounding Box of the area that will be searched.
    
    The 4 values represent the bottom-left corner of the box and the top-right corner, minimum_longitude, minimum_latitude, maximum_longitude, maximum_latitude.
    
    Longitude has a range of -180 to 180 , latitude of -90 to 90. Defaults to -180, -90, 180, 90 if not specified.
    
    Unlike standard photo queries, geo (or bounding box) queries will only return 250 results per page.
    
    Geo queries require some sort of limiting agent in order to prevent the database from crying. This is basically like the check against "parameterless searches" for queries without a geo component.
    
    A tag, for instance, is considered a limiting agent as are user defined min_date_taken and min_date_upload parameters — If no limiting factor is passed we return only photos added in the last 12 hours (though we may extend the limit in the future).
    */
    private func getBboxParams(lat: Double, long: Double) -> String
    {
        var miniLong = -180.0, miniLat = -90.0
        let maxiLong = 180.0, maxiLat = 90.0
        
        if lat > miniLat {
            miniLat = lat
        }
        
        if long > miniLong {
            miniLong = long
        }
        
        //return "minimum_longitude, minimum_latitude, maximum_longitude, maximum_latitude"
        return "\(miniLong),\(miniLat),\(maxiLong),\(maxiLat)"
    }

    private func getRandomPageNumber(maxX maxX: UInt32, minX: UInt32 = 1) -> Int
    {
        var result = ( arc4random() % (maxX - minX + 1) ) + minX
        var pageDiff = Int(minX)
        
        if currentPageNumber != nil && Int(maxX) > Constants.MinimumPhotoPagesDiff * 2 {
            repeat {
                result = ( arc4random() % (maxX - minX + 1) ) + minX
                pageDiff = abs(Int(result) - currentPageNumber!)
            } while(pageDiff < Constants.MinimumPhotoPagesDiff) // currentPage == Int(result)
        }
        
        currentPageNumber = Int(result)
        print("current page number: \(currentPageNumber!)")
        
        return Int(result)
    }

}//EndClass
