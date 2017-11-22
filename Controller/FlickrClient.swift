
//
//  FlickrClient.swift
//  VirtualMapTour
//
//  Created by Cece Soudaly on 9/2/17.
//  Copyright © 2017 CeceMobile. All rights reserved.
//
import UIKit
import Foundation
import CoreData


class FlickrClient : NSObject {
    
    var session: URLSession
    
    override init() {
        session = URLSession.shared
        super.init()
    }
    
    // Call HTTP Get Method to download data
    func taskForGETMethod(parameters: [String:AnyObject], completionHandler: @escaping (_ result:AnyObject?, _ error:NSError?) -> Void) -> URLSessionDataTask {
        
        // Set the parameters
        var mutableParameters = parameters
        
        //Build URL and configure Request
        let urlString = Constant.BaseURL  + FlickrClient.escapedParameters(parameters: mutableParameters)
        let url1 = URL(string: urlString)!
        
        print("make the request", url1)
        
        let request = URLRequest(url: url1 as URL)
        
        //Make the Request
        let task = session.dataTask(with: request) {data,response,downloadError in
            //Parse the data and use the data
            if let error = downloadError {
                let newError = FlickrClient.manageErrors(data: data as NSData?, response: response, error: error as NSError?, completionHandler: completionHandler)
                completionHandler(data as AnyObject, nil)
            } else {
                FlickrClient.parseJSONWithmpletionHandler(data: data! as NSData, completionHandler: completionHandler)
            }
        }
        //Start the request
        task.resume()
        return task
        
    }
    
    
    func getImagesFromFlickr(_ location: Location, _ page: Int, _ completionHandler: @escaping (_ result: [Photo]?, _ error: NSError?) -> Void) {
        
        let methodParameters: [String:String] = [
            ParameterKeys.Method  : Methods.SearchPhotosbyLatLon,
            ParameterKeys.ApiKey: Constant.ApiKey,
            ParameterKeys.BoundingBox: bboxString(longitude:location.longitude , latitude: location.latitude),
            ParameterKeys.Latitude: "\(location.latitude)",
            ParameterKeys.Longitude: "\(location.longitude)",
            ParameterKeys.photosPerPage: "21",
            ParameterKeys.pageNumber: "\(page)",
            ParameterKeys.Safesearch: Constant.Safesearch,
            ParameterKeys.Extras: Constant.Extras,
            ParameterKeys.Dataformat: Constant.DataFormat,
            ParameterKeys.NOJSONCallback: Constant.No_JSON_CALLBACK
        ]
        // create session and request
        //Build URL and configure Request
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        print("make the request", request)
        
        
        let task = taskForGETMethod(request: request) { (parsedResult, error) in
            
            // display error
            func displayError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandler(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult?[Constant.Status] as? String, stat == Constant.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult?[JSONResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find key '\(JSONResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[JSONResponseKeys.Photo] as? [[String: AnyObject]] else {
                displayError("Cannot find key '\(JSONResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            DispatchQueue.main.async(){
                var imageUrlStrings = [Photo]()
                
                for url in photosArray {
                    guard let urlString = url[Constant.Extras] as? String else {
                        displayError("Cannot find key '\(Constant.Extras)' in \(photosArray)")
                        return
                    }
                    
                    //Keep photo and location object consistence, both are created by dictionary.
                    let photo = Photo(dictionary: photosDictionary, context: CoreDataStackManager.getContext())
                    //saving it to core data
                    photo.imageUrl = urlString
                    photo.location = location
                    imageUrlStrings.append(photo)
                    CoreDataStackManager.saveContext()
                }
                
                completionHandler(imageUrlStrings, nil)
            }
            
        }
        
        // start the task!
        task.resume()
    }
    
    // MARK: GETMethod
    private func taskForGETMethod(request:URLRequest, _ completionHandlerForGET: @escaping(_ result: AnyObject?, _ error: NSError?) -> Void)-> URLSessionDataTask {
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // display error
            func displayError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        task.resume()
        return task
    }
    
    // given raw JSON, return a usable Foundation object
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    
    //    // Display error
    class func manageErrors(data: NSData?, response: URLResponse?, error: NSError?, completionHandler: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        /* GUARD: Was there an error? */
        guard (error == nil) else {
            print("Error: There was an error with your request: \(error)")
            let modifiedError = NSError(domain: "Error", code: 0, userInfo: [NSLocalizedDescriptionKey: error!.localizedDescription])
            completionHandler(nil, modifiedError)
            return
        }
        
        /* GUARD: Did we get a successful 2XX response? */
        guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
            if let response = response as? HTTPURLResponse {
                if response.statusCode == 403 {
                    print("Authentication Error: Status code: \(response.statusCode)!")
                    completionHandler(nil, NSError(domain: "Authentication Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Status code: \(response.statusCode)!"]))
                } else {
                    print("Server Error: Your request returned an invalid response! Status code: \(response.statusCode)!")
                    completionHandler(nil, NSError(domain: "Server Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Your request returned an invalid response! Status code: \(response.statusCode)!"]))
                }
            } else if let response = response {
                print("Server Error: Your request returned an invalid response! Response: \(response)!")
                completionHandler(nil, NSError(domain: "Server Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Your request returned an invalid response! Response: \(response)!"]))
            } else {
                print("Server Error: Your request returned an invalid response!")
                completionHandler(nil, NSError(domain: "Server Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "Your request returned an invalid response!"]))
            }
            return
        }
        
        /* GUARD: Was there any data returned? */
        guard let _ = data else {
            print("Network Error: No data was returned by the request!")
            completionHandler(nil, NSError(domain: "Network Error", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data was returned by the request!"]))
            return
        }
    }
    
    //Parse JSON response
    class func parseJSONWithmpletionHandler(data:NSData, completionHandler:(_ result:AnyObject?, _ error:NSError?) -> Void) {
        var parsedResult: AnyObject!
        do {
            
            let json = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as? [String : Any]
            
            parsedResult = json as AnyObject
            
            let posts = parsedResult["posts"] as? [[String: Any]] ?? []
            
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandler(nil, NSError(domain: "parseJSONWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandler(parsedResult, nil)
    }
    
    /* Helper function: Given a dictionary of parameters, convert to a string for a url */
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joined(separator: "&")
    }
    
    private func flickrURLFromParameters(_ parameters: [String:String]) -> URL {
        
        var components = URLComponents()
        components.scheme = Flickr.APIScheme
        components.host = Flickr.APIHost
        components.path = Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
    
    func bboxString(longitude:Double, latitude:Double) -> String {
        let minimumLon = max(longitude - Flickr.SearchBBoxHalfWidth,Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Flickr.SearchBBoxHalfWidth, Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Flickr.SearchBBoxHalfHeight, Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    //MARK:- SharedInstance
    
    class func sharedInstance()-> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    
}

