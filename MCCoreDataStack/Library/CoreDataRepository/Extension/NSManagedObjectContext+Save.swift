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

    // MARK: Save new objects

    ///### Save the current context in a background queue
    ///- Parameter completionBlock: The completion Block

    public func save(completionBlock: @escaping MCCoreDataAsyncResult) {

        self.performAndWait { [weak self] in
            guard let strongSelf = self else {
                completionBlock({ })
                return
            }

            if strongSelf.hasChanges {
                do {
                    try strongSelf.save()
                } catch {
                    completionBlock ({
                        let error = "We encountered a problem. Changes could not be saved."
                        throw CoreDataStackError.Error(description: error)
                    })

                    return
                }
            }

            completionBlock({ })
        }
    }

    ///### Save the current context and wait

    public func saveAndWait(completionBlock: @escaping MCCoreDataAsyncResult) {

        self.performAndWait { [weak self] in
            guard let strongSelf = self else {
                completionBlock({ })
                return
            }

            if strongSelf.hasChanges {
                do {
                    try strongSelf.save()
                } catch {
                    completionBlock ({
                        let error = "We encountered a problem. Changes could not be saved."
                        throw CoreDataStackError.Error(description: error)
                    })

                    return
                }
            }

            completionBlock({ })
        }
    }
}
