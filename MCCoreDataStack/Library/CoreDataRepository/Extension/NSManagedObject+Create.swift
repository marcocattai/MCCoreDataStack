//
//  NSManagedObject+Create.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 02/06/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObject: EUManagedObjectProtocol
{
    
    //MARK: Extension to auto populate properties from a dictionary
    
    ///### Class method to create an Instance of a specific NSManagedObject using a Dictionary
    ///- Parameter dictionary: dictionary
    ///- Parameter entityName: the name of the entity
    ///- Parameter MOC: NSManagedObjectContext
    ///- Return: NSManagedObject

    @objc public class func instanceWithDictionary(dictionary dictionary: Dictionary<String, AnyObject>,
                                                   entityName: String,
                                                   MOC moc: NSManagedObjectContext) -> NSManagedObject?
    {
        let entity = NSEntityDescription.insertNewObjectForEntityForName(entityName, inManagedObjectContext: moc)
        entity.updateWithDictionary(dictionary: dictionary)
        
        return entity
    }
    
    ///### Update current NSManagedObject with a dictionary
    ///- Parameter dictionary: dictionary

    @objc public func updateWithDictionary(dictionary dictionary: Dictionary<String, AnyObject>)
    {
        for (key, value) in dictionary {
            let keyName = key
            let keyValue: AnyObject = value
            
            if value is Array<Dictionary<String, AnyObject>> {
                
                self.update(keyName: keyName, array: value as! Array<Dictionary<String, AnyObject>>)
            } else if (value is Dictionary<String, AnyObject>) {
                
                let array = [value]
                self.update(keyName: keyName, array: array as! Array<Dictionary<String, AnyObject>>)
            } else if (self.respondsToSelector(NSSelectorFromString(keyName))) {
                
                if keyValue is String {
                   let keyValueString = keyValue as! String
                    self.setValue(keyValueString, forKey: keyName)
                } else if keyValue is NSDateComponents {
                    let dateComponents = keyValue as! NSDateComponents
                    self.setValue(dateComponents.date, forKey: keyName)
                } else {
                    self.setValue(keyValue, forKey: keyName)
                }
            }
        }
    }
    
    ///### called when a value is an array of NSManagedObjects. To be overridden
    ///- Parameter array: array of dictionaries

    public func update(keyName keyName: String, array: Array<Dictionary<String, AnyObject>>)
    {
        // To be overridden by subclasses
    }

}