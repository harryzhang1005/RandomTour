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
    
    typealias CompHandler = (result: [[String:String]]?, error: NSError?) -> Void
    typealias CompletionHandler = (result: AnyObject?, error: NSError?) -> Void
    
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
    private let session = NSURLSession.sharedSession()
    
    private struct ErrorMessages {
        static let NoInternet = "Can't connect to the Internet!"
        static let InvalidURL = "Invalid URL"
        static let EmptyURL = "Empty URL"
    }
    
    // MARK: - Public APIs HTTP CRUD
    
    /*
    GET only need urlString
    requestParams often use with POST or PUT
    cookieName often use with DELETE
    */
    func httpRequest(urlString: String, type: HttpRequestType = .GET, requestParams: [String:AnyObject]? = nil, cookieName: String? = nil, completionHandler: CompletionHandler)
    {
        checkNetwork(completionHandler)
        
        if !urlString.isEmpty {
            if let url = NSURL(string: urlString)
            {
                let request = self.getRequest(withType: type, url: url, requestParams: requestParams, cookieName: cookieName)
                let task = session.dataTaskWithRequest(request) { data, response, error in
                    if error != nil {
                        completionHandler(result: nil, error: error); return
                    } else {
                        self.parseJSONData(data!, completionHandler: completionHandler)
                    }
                }
                task.resume()
            } else {
                completionHandler(result: nil, error: self.getError(ErrorMessages.InvalidURL))
            }
        } else {
            completionHandler(result: nil, error: self.getError(ErrorMessages.EmptyURL))
        }
    }
    
    // MARK: - Public Helpers
    
    func urlReplaceKey(urlString: String, params: [String:String]) -> String
    {
        var url = urlString
        for (key, value) in params {
            if url.rangeOfString("{\(key)}") != nil {
                url = url.stringByReplacingOccurrencesOfString("{\(key)}", withString: value)
            }
        }
        return url
    }
    
    func urlAddParams(params: [String:AnyObject]) -> String
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
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    // MARK: - Private Helpers
    
    private func getRequest(withType type: HttpRequestType, url: NSURL, requestParams: [String: AnyObject]? = nil, cookieName: String? = nil) -> NSURLRequest
    {
        let request = NSMutableURLRequest(URL: url)
        
        if let additionalHTTPHeaderFields = additionalHTTPHeaderFields {
            for (httpHeaderField, value) in additionalHTTPHeaderFields {
                // Adds an HTTP header to the receiver’s HTTP header dictionary.
                request.addValue(value, forHTTPHeaderField: httpHeaderField)
            }
        }
        
        switch type {
        case .GET: break
            
        case .POST:
            request.HTTPMethod = type.rawValue  // "POST"
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            if let httpBodyParams = requestParams {
                request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(httpBodyParams, options: [])
            }
        case .PUT:
            request.HTTPMethod = type.rawValue  // "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            if let httpBodyParams = requestParams {
                request.HTTPBody = try? NSJSONSerialization.dataWithJSONObject(httpBodyParams, options: [])
            }
        case .DELETE:
            request.HTTPMethod = type.rawValue  // "DELETE"
            
            if let cookieName = cookieName
            {
                var cookie: NSHTTPCookie?
                let sharedCookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()
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
        
        return request
    }
    
    private func getError(err: String) -> NSError {
        return NSError(domain: "HttpRequestAPI", code: 1, userInfo: [NSLocalizedDescriptionKey : err])
    }
    
    private func checkNetwork(completionHandler: CompletionHandler) {
        if !Reachability.isConnectedToNetwork() {
            completionHandler(result: nil, error: self.getError(ErrorMessages.NoInternet))
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
    private func parseJSONData(data: NSData, completionHandler: CompletionHandler)
    {
        let newData: NSData
        if skipResponseDataLength != nil { /* subset response data! */
            newData = data.subdataWithRange(NSMakeRange(skipResponseDataLength!, data.length - skipResponseDataLength!))
        } else {
            newData = data
        }
        
        do {
            // Return A Foundation object from the JSON data in newData, or nil if an error occurs.
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(newData, options: NSJSONReadingOptions.AllowFragments)
            //print("json resp result: \(parsedResult)")
            completionHandler(result: parsedResult, error: nil)
        } catch let error as NSError {
            completionHandler(result: nil, error: error)
        }
    }
    
}//EndClass
