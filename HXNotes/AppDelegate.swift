//
//  AppDelegate.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/15/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    public static var scheduleAssistant: ScheduleAssistant!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        
        setupDefaults()
        
        // Only add the menubar icon if set to true in preferences
        if let menuBarShown = CFPreferencesCopyAppValue(NSString(string: "showInMenuBar"), kCFPreferencesCurrentApplication) as? String {
            if menuBarShown == "true" {
                createMenuBarIcon()
            }
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: Foundation.URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.apple.toolsQA.CocoaApp_CD" in the user's Application Support directory.
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls[urls.count - 1]
        return appSupportURL.appendingPathComponent("com.apple.toolsQA.CocoaApp_CD")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "HXNotes", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = FileManager.default
        var failError: NSError? = nil
        var shouldFail = false
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        do {
            let properties = try self.applicationDocumentsDirectory.resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
            if !properties.isDirectory! {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } catch  {
            let nserror = error as NSError
            if nserror.code == NSFileReadNoSuchFileError {
                do {
                    try fileManager.createDirectory(atPath: self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    failError = nserror
                }
            } else {
                failError = nserror
            }
        }
        
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = nil
        if failError == nil {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.appendingPathComponent("HXNotes.storedata")
            do {
                try coordinator!.addPersistentStore(ofType: NSXMLStoreType, configurationName: nil, at: url, options: [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true])
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                 
                /*
                 Typical reasons for an error here include:
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                failError = error as NSError
            }
        }
        
        if shouldFail || (failError != nil) {
            // Report any error we got.
            if let error = failError {
                NSApplication.shared().presentError(error)
                fatalError("Unresolved error: \(error), \(error.userInfo)")
            }
            fatalError("Unsresolved error: \(failureReason)")
        } else {
            return coordinator!
        }
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving and Undo support
    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSApplication.shared().presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return managedObjectContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !managedObjectContext.hasChanges {
            return .terminateNow
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == NSAlertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }
    
    // MARK: - Preferences
    var prefPanel: NSPanel!
    
    func setupDefaults() {
        
        if CFPreferencesCopyAppValue(NSString(string: "autoScroll"), kCFPreferencesCurrentApplication) == nil {
            
            CFPreferencesSetAppValue(NSString(string: "autoScroll"),NSString(string: "\(true)"), kCFPreferencesCurrentApplication)
            CFPreferencesSetAppValue(NSString(string: "autoScrollPositionPercent"),NSString(string: "50"), kCFPreferencesCurrentApplication)
            CFPreferencesSetAppValue(NSString(string: "bottomBufferSpace"),NSString(string: "30"), kCFPreferencesCurrentApplication)
            CFPreferencesSetAppValue(NSString(string: "launchWithSystem"),NSString(string: "\(false)"), kCFPreferencesCurrentApplication)
            CFPreferencesSetAppValue(NSString(string: "showInMenuBar"),NSString(string: "\(true)"), kCFPreferencesCurrentApplication)
            CFPreferencesSetAppValue(NSString(string: "runAfterClose"),NSString(string: "\(false)"), kCFPreferencesCurrentApplication)
            CFPreferencesSetAppValue(NSString(string: "futureAlertTimeMinutes"),NSString(string: "5"), kCFPreferencesCurrentApplication)
            // ALWAYS, NO_LECTURES, NO_TIMESLOTS, NEVER
            CFPreferencesSetAppValue(NSString(string: "courseDeletionConfirmation"),NSString(string: "NO_LECTURES"), kCFPreferencesCurrentApplication)
            // TOPBAR, SIDEBAR, OVERLAY
            CFPreferencesSetAppValue(NSString(string: "alertLocation"),NSString(string: "TOPBAR"), kCFPreferencesCurrentApplication)
            CFPreferencesSetAppValue(NSString(string: "defaultCourseTimeSpanMinutes"),NSString(string: "55"), kCFPreferencesCurrentApplication)
            CFPreferencesSetAppValue(NSString(string: "bufferTimeBetweenCoursesMinutes"),NSString(string: "5"), kCFPreferencesCurrentApplication)
            // SEMESTER_TITLE : SEMESTER_YEAR : COURSE_TITLE or nil if a semester wasn't open on quit
            CFPreferencesSetAppValue(NSString(string: "previouslyOpenedCourse"),NSString(string: "nil"), kCFPreferencesCurrentApplication)
            
            CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
        }
    }
    
    @IBAction func revealPreferences(_ sender: NSMenuItem) {
        
//        if prefPanel == nil {
//            let prefController = PreferencesViewController(nibName: "PreferencesView", bundle: nil)!
//            prefPanel = NSPanel(contentViewController: prefController)
//            NSApp.mainWindow!.beginSheet(prefPanel, completionHandler: {response in })
//            NSApp.runModal(for: prefPanel)
//            
//        }
        
        if let content = NSApp.keyWindow?.contentViewController as? MasterViewController {
            content.displayPreferences()
        }
        
    }
    func closeModal() {
        
//        NSApp.mainWindow!.endSheet(prefPanel!)
//        NSApp.stopModal()
//        prefPanel = nil
        
    }
    
    // MARK: - Menu Bar Functionality
    
    var statusItem: NSStatusItem!
    let menuBarPopover = NSPopover()
    var eventMonitor: EventMonitor?
    
    func createMenuBarIcon() {
        if statusItem == nil {
            statusItem = NSStatusBar.system().statusItem(withLength: NSSquareStatusItemLength)
            // Menu Bar Icon
            if let button = statusItem.button {
                button.image = #imageLiteral(resourceName: "menu_icon@")
                button.target = self
                button.action = #selector(self.toggleMenuBarPopover(sender:))
            }
            menuBarPopover.contentViewController = MenuBarPopoverViewController(nibName: "MenuBarPopover", bundle: nil)
            
            eventMonitor = EventMonitor(mask: [NSEventMask.leftMouseDown, NSEventMask.rightMouseDown], handler: {event in
                if self.menuBarPopover.isShown {
                    self.closeMenuBarPopover(sender: event)
                }
            })
            eventMonitor?.start()
        }
    }
    func removeMenuBarIcon() {
        if statusItem != nil {
            NSStatusBar.system().removeStatusItem(statusItem)
            statusItem = nil
            eventMonitor?.stop()
            eventMonitor = nil
        }
    }
    
    func showMenuBarPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            
            menuBarPopover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }
    
    func closeMenuBarPopover(sender: AnyObject?) {
        menuBarPopover.performClose(sender)
    }
    
    func toggleMenuBarPopover(sender: AnyObject?) {
        if menuBarPopover.isShown {
            closeMenuBarPopover(sender: sender)
        } else {
            showMenuBarPopover(sender: sender)
        }
    }
    
    ///
    @IBAction func findFunction(_ sender: NSMenuItem) {
        if let content = NSApp.keyWindow?.contentViewController as? MasterViewController {
            content.notifyFind()
        }
    }
    ///
    @IBAction func findAndReplaceFunction(_ sender: NSMenuItem) {
        if let content = NSApp.keyWindow?.contentViewController as? MasterViewController {
            content.notifyFindAndReplace()
        }
    }
    ///
    @IBAction func exportFunction(_ sender: NSMenuItem) {
        if let content = NSApp.keyWindow?.contentViewController as? MasterViewController {
            content.notifyExport()
        }
    }
    ///
    @IBAction func printFunction(_ sender: NSMenuItem) {
        if let content = NSApp.keyWindow?.contentViewController as? MasterViewController {
            content.notifyPrint()
        }
    }
}

