//
//  Image+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by Ahmed Tawfik on 12/19/17.
//  Copyright © 2017 Fox Apps. All rights reserved.
//
//

import Foundation
import CoreData


extension Image {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Image> {
        return NSFetchRequest<Image>(entityName: "Image")
    }

    @NSManaged public var imageData: NSData?
    @NSManaged public var imageURL: String?
    @NSManaged public var pin: Pin?

}
