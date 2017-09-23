//
//  NSManagedObject+Create.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 02/06/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject: EUManagedObjectProtocol {

    // MARK: Extension to auto populate properties from a dictionary

    ///### Class method to create an Instance of a specific NSManagedObject using a Dictionary
    ///- Parameter dictionary: dictionary
    ///- Parameter entityName: the name of the entity
    ///- Parameter context: NSManagedObjectContext
    ///- Return: NSManagedObject

    @objc public class func instanceWithDictionary(dictionary: [String: AnyObject],
                                                   entityName: String,
                                                   context: NSManagedObjectContext) -> NSManagedObject? {
        let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: context)
        entity.updateWithDictionary(dictionary: dictionary)

        return entity
    }

    ///### Update current NSManagedObject with a dictionary
    ///- Parameter dictionary: dictionary

    @objc public func updateWithDictionary(dictionary: [String: AnyObject]) {
        for (key, value) in dictionary {

            if value is [[String: AnyObject]] {
                // swiftlint:disable:next force_cast
                self.update(keyName: key, array: value as! [[String: AnyObject]])

            } else if value is [String: AnyObject] {
                let array = [value]
                // swiftlint:disable:next force_cast
                self.update(keyName: key, array: array as! [[String: AnyObject]])

            } else if self.responds(to: NSSelectorFromString(key)) {
                switch value {
                case is String:
                    self.setValue(value, forKey: key)
                case is DateComponents:
                    let dateComponents = value
                    // swiftlint:disable:next force_cast
                    self.setValue((dateComponents as! NSDateComponents).date, forKey: key)
                default:
                    self.setValue(value, forKey: key)
                }
            }
        }
    }

    ///### called when a value is an array of NSManagedObjects. To be overridden
    ///- Parameter array: array of dictionaries

    @objc public func update(keyName: String, array: [[String: AnyObject]]) {
        // To be overridden by subclasses
    }
}
