//
//  NSManagedObjectContext+Save.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 30/05/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

extension NSManagedObjectContext {
    
    //MARK: Save new objects
    
    ///### Save the current context in a background queue
    ///- Parameter completionBlock: The completion Block

    public func save(completionBlock completionBlock: MCCoreDataAsyncResult) -> Void {
        
        self.performBlockAndWait({ [weak self] in
            
            guard let strongSelf = self else {
                completionBlock(inner: { })
                return
            }
            
            if strongSelf.hasChanges {
                
                do {
                    
                    try strongSelf.save()
                    
                    completionBlock(inner: { })
                    
                } catch {
                    completionBlock (inner: {
                        throw CoreDataStackError.InternalError(description: "We encountered a problem. Changes could not be saved.")
                    })
                }
            } else {
                completionBlock(inner: { })
            }
            
        })
    }
    
    ///### Save the current context and wait

    public func saveAndWait(completionBlock completionBlock: MCCoreDataAsyncResult) -> Void {
        
        self.performBlockAndWait({ [weak self] in
            
            guard let strongSelf = self else {
                completionBlock(inner: { })
                return
            }
            
            if strongSelf.hasChanges {
                
                do {
                    
                    try strongSelf.save()
                    
                    completionBlock(inner: { })
                    
                } catch {
                    completionBlock (inner: {
                        throw CoreDataStackError.InternalError(description: "We encountered a problem. Changes could not be saved.")
                    })
                }
            } else {
                completionBlock(inner: { })
            }
        })
    }
    
}
