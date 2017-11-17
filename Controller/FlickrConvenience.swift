//
//  FlickrConvenience.swift
//  VirtualMapTour
//
//  Created by Cece Soudaly on 9/3/17.
//  Copyright © 2017 CeceMobile. All rights reserved.
//


import Foundation
import UIKit

extension FlickrClient {
    
    // Flickr conveniece method to download image set based on location and page number
    
    func getImageFromFlickrByLatLonWithPage(methodArguments: [String : AnyObject], pageNumber: Int,completionHandler: @escaping (_ result:[String:AnyObject]?, _ error: NSError?) -> Void) {
        
        // Add page to method parameters
        var withPageDictionary = methodArguments
        withPageDictionary[FlickrClient.ParameterKeys.pageNumber] = pageNumber as AnyObject
        withPageDictionary[FlickrClient.ParameterKeys.photosPerPage] = FlickrClient.Constant.photosPerPage as AnyObject
        
        // Call general get method to call webAPI
        
        taskForGETMethod(parameters: withPageDictionary) { JSONResult, error in
            
            // Send required values to completion handler
            if let error = error {
                completionHandler(nil, error)
            } else {
                if let photosDictionary = JSONResult?[JSONResponseKeys.Photos] as? [String : AnyObject]  {
                    completionHandler(photosDictionary, nil)
                } else {
                    completionHandler(nil, NSError(domain: "getImageFromFlickrByLatLonWithPage Parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "could not parse getImageFromFlickrByLatLonWithPage"]))
                }
            }
        }
    }
    
    func getFlickrImagesByLatLon(latitude:Double,longitude:Double, nextPageNumber: Int, completionHandler: @escaping (_ result: [[String:AnyObject]]?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        //Specify parameters
        let dictparameters = [
            FlickrClient.ParameterKeys.Method: FlickrClient.Methods.SearchPhotosbyLatLon,
            FlickrClient.ParameterKeys.ApiKey: FlickrClient.Constant.ApiKey,
            FlickrClient.ParameterKeys.Latitude: latitude,
            FlickrClient.ParameterKeys.Longitude: longitude,
            FlickrClient.ParameterKeys.Safesearch: FlickrClient.Constant.Safesearch,
            FlickrClient.ParameterKeys.Extras: FlickrClient.Constant.Extras,
            FlickrClient.ParameterKeys.Dataformat: FlickrClient.Constant.DataFormat,
            FlickrClient.ParameterKeys.NOJSONCallback: FlickrClient.Constant.No_JSON_CALLBACK
            ] as [String : Any]
        
        //Make the request
        let task =   taskForGETMethod(parameters: dictparameters as! [String : AnyObject]) { JSONResult, error in
            
            // Send required values to completion handler
            if let error = error {
                completionHandler(nil, error)
            } else {
                
                if let photosDictionary = JSONResult?[JSONResponseKeys.Photos] as? [String:AnyObject] {
                    
                    if let totalPages = photosDictionary[JSONResponseKeys.TotalPages] as? Int {
                        
                        // Pass next page number to flickr API to get the images for different pages
                        print("Total pages are : \(totalPages)")
                        print("Page number is : \(nextPageNumber)")
                        
                        if nextPageNumber <= totalPages {
                            
                            self.getImageFromFlickrByLatLonWithPage(methodArguments: dictparameters as! [String : AnyObject], pageNumber: nextPageNumber) {
                                results, error in
                                
                                if let receivedDictionary = results as [String:AnyObject]? {
                                    
                                    // Received photos array
                                    if let photosArray = receivedDictionary[JSONResponseKeys.Photo] as? [[String: AnyObject]] {
                                        completionHandler(photosArray, nil)
                                    }
                                }
                            }
                        } else {
                            completionHandler(nil, NSError(domain: "VIRTUAL_TOURIST_MESSAGE", code: 101, userInfo: [NSLocalizedDescriptionKey: "There is no more Flickr images available for this location."]))
                        }
                    }
                } else {
                    
                    completionHandler(nil, NSError(domain: "getFlickrImagesByLatLon Parsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "could not parse getFlickrImagesByLatLon"]))
                }
            }
        }
        return task
    }
    
    /// Data task to download Flickr image
    func taskForImage(filePath:String, completionHandler :@escaping (_ imageDate:NSData?, _ error:NSError?) -> Void)-> URLSessionTask {
        
        // Flickr image URL
        let url = URL(string: filePath)!
        
        let request = URLRequest(url: url as URL)
        
        
        // Make the request
        let task = session.dataTask(with: request) {
            data, response, downloadError in
            
            if let error = downloadError {
                //let newError = FlickrClient.errorForData(data, response: response, error: error)
                completionHandler(data! as NSData, error as NSError)
            } else {
                completionHandler(data as! NSData, nil)
            }
        }
        task.resume()
        return task
        
    }
    
}

