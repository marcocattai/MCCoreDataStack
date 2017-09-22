//
//  MCCoreDataStackManagerBackground.swift
//  MCCoreDataStack
//
//  Created by Marco Cattai on 09/02/2016.
//  Copyright © MCCoreDataStack  All rights reserved.
//

import Foundation
import CoreData

#if TARGET_OS_IPHONE

    extension MCCoreDataStackManager {

        func deregisterObservers() {
            if self.areObserversRegistered {
                let center = NSNotificationCenter.defaultCenter()

                center.removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
                center.removeObserver(self, name: UIApplicationDidEnterBackgroundNotification, object: nil)
                center.removeObserver(self, name: UIApplicationWillTerminateNotification, object: nil)

                self.areObserversRegistered = false
            }
        }

        func registerObservers() {
            if self.areObserversRegistered == false {
                let center = NSNotificationCenter.defaultCenter()

                center.addObserver(self,
                                   selector: "applicationWillResignActive:",
                                   name: UIApplicationWillResignActiveNotification,
                                   object: nil)
                center.addObserver(self,
                                   selector: "applicationDidEnterBackground:",
                                   name: UIApplicationDidEnterBackgroundNotification,
                                   object: nil)
                center.addObserver(self,
                                   selector: "applicationWillTerminate:",
                                   name: UIApplicationWillTerminateNotification,
                                   object: nil)

                self.areObserversRegistered = true
            }
        }

        // MARK: Observers

        func applicationWillResignActive(notification: NSNotification) {
            self.persistbkgcontext()
        }

        func applicationDidEnterBackground(notification: NSNotification) {
            self.persistbkgcontext()
        }

        func applicationWillTerminate(notification: NSNotification) {
            self.persistbkgcontext()
        }

        func persistbkgcontext() {
            if UIDevice.currentDevice().respondsToSelector("isMultitaskingSupported") {
                self.bkgPersistTask = UIBackgroundTaskInvalid
                NSNotificationCenter.defaultCenter().addObserver(self,
                                                                 selector: "doBackgroundTask:",
                                                                 name: UIApplicationDidEnterBackgroundNotification,
                                                                 object: nil)
            }
        }

        func doBackgroundTask(notification: NSNotification) {
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
                    weakSelf?.asyncRead({ (_) -> Void in
                        weakSelf!.terminateBackgroundTask()
                    })
                })
            }
        }

        func terminateBackgroundTask() {
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
