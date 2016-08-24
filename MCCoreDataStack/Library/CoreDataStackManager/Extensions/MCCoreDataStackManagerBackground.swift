//
//  MCCoreDataStackManagerBackground.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import Swift
import CoreData

#if TARGET_OS_IPHONE

internal extension MCCoreDataStackManager
{
    
    internal func deregisterObservers()
    {
        if self.areObserversRegistered {
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
            NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)
            
            self.areObserversRegistered = false
        }
    }
    
    internal func registerObservers()
    {
        if self.areObserversRegistered == false {
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "_applicationWillResignActive:", name: UIApplicationWillResignActiveNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "_applicationDidEnterBackground:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "_applicationWillTerminate:", name: UIApplicationWillTerminateNotification, object: nil)
            self.areObserversRegistered = true
        }
    }
    
    //MARK: Observers
    
    internal func _applicationWillResignActive(notification: NSNotification)
    {
        self.persistbkgMOC()
    }
    
    internal func _applicationDidEnterBackground(notification: NSNotification)
    {
        self.persistbkgMOC()
    }
    
    internal func _applicationWillTerminate(notification: NSNotification)
    {
        self.persistbkgMOC()
    }
    
    internal func persistbkgMOC() {
        if UIDevice.currentDevice().respondsToSelector("isMultitaskingSupported") {
            self.bkgPersistTask = UIBackgroundTaskInvalid
            NSNotificationCenter.defaultCenter().addObserver(self, selector: "_doBackgroundTask:", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        }
    }
    
    internal func _doBackgroundTask(notification: NSNotification)
    {
        let app: UIApplication = UIApplication.sharedApplication()
        weak var weakSelf = self
        if app.respondsToSelector("beginBackgroundTaskWithExpirationHandler:") {
            weakSelf!.bkgPersistTask = app.beginBackgroundTaskWithExpirationHandler({() -> Void in
                if weakSelf!.bkgPersistTask != UIBackgroundTaskInvalid {
                    app.endBackgroundTask(weakSelf!.bkgPersistTask!)
                    self.bkgPersistTask = UIBackgroundTaskInvalid
                }
            })
            let queue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUMIPE_PRIORITY_DEFAULT, 0)
            dispatch_async(queue, {() -> Void in
                weakSelf?.performOperationInBackgroundQueueWithBlock({ (MOC) -> Void in
                    weakSelf!.terminateBackgroundTask()
                })
            })
        }
    }
    
    internal func terminateBackgroundTask()
    {
        let app: UIApplication = UIApplication.sharedApplication()
        if app.respondsToSelector("endBackgroundTask:") {
            if bkgPersistTask != UIBackgroundTaskInvalid {
                app.endBackgroundTask(bkgPersistTask!)
                self.bkgPersistTask = UIBackgroundTaskInvalid
            }
        }
    }
}

#endif
