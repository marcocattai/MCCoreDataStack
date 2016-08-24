# MCCoreDataStack
EUCoreDataStack is a simple SWIFT wrapper around Apple's Core Data Framework to create, save and fetch Managed Objects

##Documentation
[Wiki Pages](https://marcocattai.github.io/MCCoreDataStack/)

##Introduction:

It is a very simple, thread safe, swift library that helps you dig into the CoreData Framework. 
I have created it for a personal project and it is on my personal library since February 2016.

Here it might be useful to other developers that hopefully will contribute to it. Feel free to create pull requests. Thank you in advance for that. 

####MCCoreDataStackManager 

This class includes all the basic functionalities to setup a CoreData Stack. It uses the approach described by Core Data guru Marcus Zarra which builds on the above Parent/Child method but adds an additional context exclusively for writing to disk. A lenghty write operation might block the main thread for a short time causing the UI to freeze. This smart approach uncouples the writing into its own private queue and keeps the UI smooth.

![alt tag](https://dl.dropboxusercontent.com/u/7201536/model.png)

####MCCoreDataRepository
 This class includes an helper method to setup a CoreDataStack using MCCoreDataStackManager. This class provides basic functionalities to create, delete and fetch NSManagedObjects.

##Integrate in your existing project

You can use Cocoapods to install EUCoreDataStack adding it to your Pod file

```
platform :ios, '8.0'
use_frameworks!

target 'MyApp' do
    pod 'EUCoreDataStack'
end
```
##How to use:

###Initialization:

```swift
MCCoreDataRepository.sharedInstance.setupWithStoreName("store.sqlite", modelName: "MyDataModel", domainName: "uk.co.myApplication")
```

... Please, refer to the unit tests

