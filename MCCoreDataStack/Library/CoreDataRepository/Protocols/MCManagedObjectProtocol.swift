//
//  EUManagedObjectProtocol.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation

@objc public protocol EUManagedObjectProtocol {
    
    ///### Protocol automatically implemented by NSManagedObject extension
    func updateWithDictionary(dictionary dictionary: Dictionary<String, AnyObject>)
}
