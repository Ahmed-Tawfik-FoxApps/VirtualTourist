//
//  FlickrConvenience.swift
//  VirtualTourist
//
//  Created by Ahmed Tawfik on 12/14/17.
//  Copyright © 2017 Fox Apps. All rights reserved.
//

import Foundation
import MapKit

extension FlickrClient {
    
    func getImageFromFilckrByCoordinates (coordinates: CLLocationCoordinate2D,_ completionHandlerForGetImage: @escaping completionHandlerForGET) {
        
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        let parameters: [String: AnyObject] = [
            FlickrParameterKeys.SafeSearch:FlickrParameterValues.UseSafeSearch as AnyObject,
            FlickrParameterKeys.BoundingBox:bboxString(coordinates: coordinates) as AnyObject,
            FlickrParameterKeys.Extras:FlickrParameterValues.MediumURL as AnyObject,
            FlickrParameterKeys.Method:FlickrParameterValues.SearchMethod as AnyObject,
            FlickrParameterKeys.Format:FlickrParameterValues.ResponseFormat as AnyObject,
            FlickrParameterKeys.NoJSONCallback:FlickrParameterValues.DisableJSONCallback as AnyObject,
            FlickrParameterKeys.PerPage: FlickrParameterValues.PerPage as AnyObject]

        /* 2. Make the request */
        let _ = taskForGETMethod("", parameters: parameters) { (results, error) in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                print(error)
                completionHandlerForGetImage(nil, error)
            } else {
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = results![FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                    print("Flickr API returned an error. See error code and message in \(results!)")
                    return
                }
                
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = results![FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    print("Cannot find keys '\(FlickrResponseKeys.Photos)' in \(results!)")
                    return
                }
                
                /* GUARD: Is "pages" key in the photosDictionary? */
                guard let totalPages = photosDictionary[FlickrResponseKeys.Pages] as? Int else {
                    print("Cannot find key '\(FlickrResponseKeys.Pages)' in \(photosDictionary)")
                    return
                }
                
                // pick a random page!
                let pageLimit = min(totalPages, 40)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                self.getRandomImagePageFromFlickr(parameters, withPageNumber: randomPage, completionHandler: { (results, error) in
                    completionHandlerForGetImage(results, nil)
                })
            }
        }
    }
    
    private func getRandomImagePageFromFlickr (_ parameters: [String:AnyObject], withPageNumber: Int, completionHandler: @escaping completionHandlerForGET) {
        /* 1. Specify parameters, method (if has {key}), and HTTP body (if POST) */
        var parametersWithPageNumber = parameters
        parametersWithPageNumber[FlickrParameterKeys.Page] = withPageNumber as AnyObject
        
        /* 2. Make the request */
        let _ = taskForGETMethod("", parameters: parametersWithPageNumber) { (results, error) in
            
            /* 3. Send the desired value(s) to completion handler */
            if let error = error {
                print(error)
                completionHandler(nil, error)
            } else {
                /* GUARD: Did Flickr return an error (stat != ok)? */
                guard let stat = results![FlickrResponseKeys.Status] as? String, stat == FlickrResponseValues.OKStatus else {
                    print("Flickr API returned an error. See error code and message in \(results!)")
                    return
                }
                
                /* GUARD: Is "photos" key in our result? */
                guard let photosDictionary = results![FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    print("Cannot find keys '\(FlickrResponseKeys.Photos)' in \(results!)")
                    return
                }
                completionHandler(photosDictionary, nil)
            }
        }
    }
    
    //Helper Function
    private func bboxString(coordinates: CLLocationCoordinate2D) -> String {
        // ensure bbox is bounded by minimum and maximums
        let latitude = Double(coordinates.latitude)
        let longitude = Double(coordinates.longitude)
        let minimumLon = max(longitude - Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.SearchBBoxHalfWidth, Constants.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.SearchBBoxHalfHeight, Constants.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }

}
