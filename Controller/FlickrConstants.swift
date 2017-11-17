//
//  FlickrConstants.swift
//  VirtualMapTour
//
//  Created by Cece Soudaly on 9/2/17.
//  Copyright © 2017 CeceMobile. All rights reserved.
//

import Foundation

import Foundation

extension FlickrClient {
    
    //MARK:- Constants to call Flickr webAPI
    struct Constant {
        static let ApiKey: String = "c2ddc9c9b887a742dc2d04036ba618f0"
        static let BaseURL: String = "https://api.flickr.com/services/rest/"
        static let Safesearch = "1"
        static let Extras = "url_m"
        static let DataFormat = "json"
        static let No_JSON_CALLBACK = "1"
        static let photosPerPage = 21
        static let Status = "stat"
        static let OKStatus = "ok"
        
    }
    
    //MARK:- Flickr methods to download data
    struct Methods {
        static let SearchPhotosbyLatLon = "flickr.photos.search"
    }
    
    // MARK: - Parameter Keys
    struct ParameterKeys {
        static let Method = "method"
        static let ApiKey = "api_key"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Safesearch = "safe_search"
        static let Extras = "extras"
        static let Dataformat = "format"
        static let NOJSONCallback = "nojsoncallback"
        static let pageNumber = "page"
        static let photosPerPage = "per_page"
        static let BoundingBox = "bbox"
        
    }
    // MARK: - JSON Response Keys
    struct JSONResponseKeys {
        static let Photos = "photos"
        static let TotalPages = "pages"
        static let Photo = "photo"
        static let Message = "msg"
        
    }
    
    // MARK: Flickr
    struct Flickr {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
        
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
}

