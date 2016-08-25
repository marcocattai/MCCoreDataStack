# MCCoreDataStack
EUCoreDataStack is a simple SWIFT wrapper around Apple's Core Data Framework to create, save and fetch Managed Objects

##Documentation
[API Reference](https://marcocattai.github.io/MCCoreDataStack/)

##Introduction:

It is a very simple, thread safe, swift library that helps you dig into the CoreData Framework. 
I have created it for a personal project and it is on my personal library since February 2016.

This library has been used with success and it doesn't have any particoular issue. Here on github it could be be useful to other developers that hopefully will contribute to it. Feel free to create pull requests. Thank you in advance for that. 

####MCCoreDataStackManager 

This class includes all the basic functionalities to setup a CoreData Stack. It uses the approach described by Core Data guru Marcus Zarra which builds on the above Parent/Child method but adds an additional context exclusively for writing to disk. A lenghty write operation might block the main thread for a short time causing the UI to freeze. This smart approach uncouples the writing into its own private queue and keeps the UI smooth.

![alt tag](https://dl.dropboxusercontent.com/u/7201536/model.png)

####MCCoreDataRepository
 This class includes an helper method to setup a CoreDataStack using MCCoreDataStackManager. This class provides basic functionalities to create, delete and fetch NSManagedObjects.

##Integrate in your existing project

###You can use Cocoapods to install EUCoreDataStack adding it to your Pod file

```
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
    pod 'EUCoreDataStack'
end
```

###Manually (iOS 7+)

To use this library on iOS 7 
- drag Library folder to the project tree
- Build the project
- #import "[YourProductModuleName]-Swift.h"

##How to use:

###Setup CoreDataStack
```swift
MCCoreDataRepository.sharedInstance.setup(storeName: "TestDB.sqlite", domainName: "co.uk.tests")
```

####Create one object in background
```swift
//Here we define our Dictionaries

let subDictionary: [String: AnyObject] = ["subCategoryID": "sub12345", "subCategoryName": "subTest12345"]
let dictionary: [String: AnyObject] = ["categoryID": "12345", "categoryName": "Test12345", "subCategory": subDictionary]

self.coreDataStackManager.asyncWrite(operationBlock: { (MOC) in

   self.coreDataRepo?.create(dictionary: dictionary, entityName: "MCCategoryTest", MOC: MOC)
 
}, completion: {

    self.coreDataRepo?.cdsManager.readOnMainThread(operationBlock: { (MOC) in
       let results = self.coreDataRepo?.fetchAll(byEntityName: "MCCategoryTest", MOC: MOC, resultType: .ManagedObjectResultType) as? [NSManagedObject]

	   // Objects will be deleted in a background thread. Deletion will fetch the objects from the background context
	   self.coreDataRepo.delete(containedInArray: results, completionBlock: nil)
    })
})
```

... Please, refer to the unit tests

##Tracking Violations

1) Please enable  Enable Core Data multi-threading assertions by passing following arguments during app launch.

```
-com.apple.CoreData.ConcurrencyDebug 1
```
2) Verify that Xcode prints out following text in console to indicate that the multi-threading assertions is enabled. 

```
CoreData: annotation: Core Data multi-threading assertions enabled.
```
3) Once the Core Data debugging is enabled, Xcode will throw an exception whenenver the app attempts to access an instance of managed object from a wrong context. You might want to check this change into your version control system so that everyone in your team can benefit from tracking these violations early during development.

