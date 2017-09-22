//
//  MCCategoryTest.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

@objc(MCCategoryTest)
class MCCategoryTest: NSManagedObject {

// Insert code here to add functionality to your managed object subclass

    override  func update(keyName: String, array: Array<Dictionary<String, AnyObject>>) {
        if let entityName = self.getEntity(keyName) {

            for dict in array {

                let entity = NSEntityDescription.insertNewObject(forEntityName: entityName, into: self.managedObjectContext!)
                entity.updateWithDictionary(dictionary: dict)

                switch entityName {
                case "MCSubCategoryTest":
                    self.subCategory = (entity as! MCSubCategoryTest)

                    break
                default: break
                }
            }
        }
    }

    fileprivate func getEntity(_ keyName: String) -> String? {
        switch keyName {
        case "subCategory":
            return "MCSubCategoryTest"
        default:
            break

        }
        return nil
    }

}
