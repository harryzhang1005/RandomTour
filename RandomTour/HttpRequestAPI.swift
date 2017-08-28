//
//  HttpRequestAPI.swift
//
//  Created by Harvey Zhang on 4/1/15.
//  Copyright (c) 2015 HappyGuy. All rights reserved.
//

import Foundation

// HTTP CRUD(post, get, put, delete) common APIs
class HttpRequestAPI
{
    // can be overridden by a subclass
    var skipResponseDataLength: Int?
    var additionalHTTPHeaderFields: [String:String]?
    var additionalURLParams: [String:AnyObject]?
    
    typealias CompHandler = (_ result: [[String:String]]?, _ error: NSError?) -> Void
    typealias CompletionHandler = (_ result: AnyObject?, _ error: NSError?) -> Void
    
    enum HttpRequestType: String {
        case POST = "POST"
        case GET = "GET"
        case PUT = "PUT"
        case DELETE = "DELETE"
    }
    
    /* 
    For basic requests, the URL session class provides a shared singleton session object that gives you a reasonable default behavior.
    
    As a result, you don’t provide a delegate or a configuration object. Therefore, with the shared session:
    -- You cannot obtain data incrementally as it arrives from the server.
    -- You cannot significantly customize the default connection behavior.
    -- Your ability to perform authentication is limited.
    -- You cannot perform background downloads or uploads while your app is not running.
    */
    fileprivate let session = URLSession.shared
    
    fileprivate struct ErrorMessages {
        static let NoInternet = "Can't connect to the Internet!"
        static let InvalidURL = "Invalid URL"
        static let EmptyURL = "Empty URL"
    }
    
    // MARK: - Public APIs for HTTP CRUD
    
    /*
    GET only need urlString
    requestParams often use with POST or PUT
    cookieName often use with DELETE
    */
    func httpRequest(_ urlString: String, type: HttpRequestType = .GET, requestParams: [String:AnyObject]? = nil,
                     cookieName: String? = nil, completionHandler: @escaping CompletionHandler)
    {
        checkNetwork(completionHandler)
        
        if !urlString.isEmpty {
            if let url = URL(string: urlString)
            {
                let request = self.getRequest(withType: type, url: url, requestParams: requestParams, cookieName: cookieName)
                let task = session.dataTask(with: request, completionHandler: { data, response, error in
                    if error != nil {
                        completionHandler(nil, error! as NSError); return
                    } else {
                        self.parseJSONData(data!, completionHandler: completionHandler)
                    }
                }) 
                task.resume()
            } else {
                completionHandler(nil, self.getError(ErrorMessages.InvalidURL))
            }
        } else {
            completionHandler(nil, self.getError(ErrorMessages.EmptyURL))
        }
    }
    
    // MARK: - Public helpers
    
    func urlReplaceKey(_ urlString: String, params: [String:String]) -> String
    {
        var url = urlString
        for (key, value) in params {
            if url.range(of: "{\(key)}") != nil {
                url = url.replacingOccurrences(of: "{\(key)}", with: value)
            }
        }
        return url
    }
    
    func urlAddParams(_ params: [String:AnyObject]) -> String
    {
        var urlVars = [String]()
        
        var totalParams = params
        if let addedParams = additionalURLParams {
            for (k, v) in addedParams {
                totalParams[k] = v
            }
        }
        
        for (key, value) in totalParams
        {
            let stringValue = "\(value)"    /* Make sure that it is a string value */
            
            /* Escape it */
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }
    
    // MARK: - Private helpers
    
    fileprivate func getRequest(withType type: HttpRequestType, url: URL, requestParams: [String: AnyObject]? = nil,
                                cookieName: String? = nil) -> URLRequest
    {
        let request = NSMutableURLRequest(url: url)
        
        if let additionalHTTPHeaderFields = additionalHTTPHeaderFields {
            for (httpHeaderField, value) in additionalHTTPHeaderFields {
                // Adds an HTTP header to the receiver’s HTTP header dictionary.
                request.addValue(value, forHTTPHeaderField: httpHeaderField)
            }
        }
        
        switch type {
			
        case .GET: break
            
        case .POST:
            request.httpMethod = type.rawValue  // "POST"
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            if let httpBodyParams = requestParams {
                request.httpBody = try? JSONSerialization.data(withJSONObject: httpBodyParams, options: [])
            }
        case .PUT:
            request.httpMethod = type.rawValue  // "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            if let httpBodyParams = requestParams {
                request.httpBody = try? JSONSerialization.data(withJSONObject: httpBodyParams, options: [])
            }
        case .DELETE:
            request.httpMethod = type.rawValue  // "DELETE"
            
            if let cookieName = cookieName
            {
                var cookie: HTTPCookie?
                let sharedCookieStorage = HTTPCookieStorage.shared
                if let sharedCookies = sharedCookieStorage.cookies {
                    for sharedCookie in sharedCookies {
                        if sharedCookie.name == cookieName { cookie = sharedCookie }
                    }
                }
                if let cookie = cookie {
                    request.addValue(cookie.value, forHTTPHeaderField: cookieName)
                }
            }
        }
        
        return request as URLRequest
    }
    
    fileprivate func getError(_ err: String) -> NSError {
        return NSError(domain: "HttpRequestAPI", code: 1, userInfo: [NSLocalizedDescriptionKey : err])
    }
    
    fileprivate func checkNetwork(_ completionHandler: CompletionHandler) {
        if !Reachability.isConnectedToNetwork() {
            completionHandler(nil, self.getError(ErrorMessages.NoInternet))
            return
        }
    }
    
    /*
    ## Correct URL Like: https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=40.6640484163906,-74.1268281159978&radius=10000&key=AIzaSyBgzcqjTytyNsnoMdcjZ-PN0z8NGUMddPI
    json resp result: { // Means url maybe missing API key
    "error_message" = "This service requires an API key.";
    "html_attributions" =     (
    );
    results =     (
    );
    status = "REQUEST_DENIED";
    }
    
    ## But, this API key works: https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=40.6640484163906,-74.1268281159978&radius=10000&key=AIzaSyD8dG0xSBBakjEZtZyFm_MeJkA536dyVuM
    json resp result: { // Means your API key not right
    "error_message" = "This IP, site or mobile application is not authorized to use this API key. Request received from IP address 98.118.124.179, with empty referer";
    "html_attributions" =     (
    );
    results =     (
    );
    status = "REQUEST_DENIED";
    }
    
    */
    fileprivate func parseJSONData(_ data: Data, completionHandler: CompletionHandler)
    {
        var newData: Data
		
        if skipResponseDataLength != nil { // subset response data
            newData = data.subdata(in: skipResponseDataLength!..<data.count - skipResponseDataLength!)
			//newData = data.subdata(in: NSMakeRange(skipResponseDataLength!, data.count - skipResponseDataLength!) )
        } else {
            newData = data
        }
        
        do {
            // Return A Foundation object from the JSON data in newData, or nil if an error occurs.
            let parsedResult = try JSONSerialization.jsonObject(with: newData,
                                                                options: JSONSerialization.ReadingOptions.allowFragments)
            //print("json resp result: \(parsedResult)")
            completionHandler(parsedResult as AnyObject, nil)
        } catch let error as NSError {
            completionHandler(nil, error)
        }
    }
    
}//EndClass
