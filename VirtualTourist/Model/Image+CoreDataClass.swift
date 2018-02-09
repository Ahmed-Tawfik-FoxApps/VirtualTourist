//
//  Image+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Ahmed Tawfik on 12/19/17.
//  Copyright © 2017 Fox Apps. All rights reserved.
//
//

import Foundation
import CoreData

@objc(Image)
public class Image: NSManagedObject {

    convenience init(imageURL: String?, imageData: NSData?, pin: Pin, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Image", in: context) {
            self.init(entity: entity, insertInto: context)
            self.imageURL = imageURL
            self.imageData = imageData
            self.pin = pin
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}
