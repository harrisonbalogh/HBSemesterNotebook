//
//  Alet.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class Alert {
    
    // Alert types help with getting rid of duplicate alerts.
    // For instance if a user doesn't remove a 10 minute warning
    // alert, then when the 5 minute warning alert occurs, it should
    // remove the 10 minute warning.
    enum AlertType {
        case future
        case happening
        case deletion
        case completed
        case custom
    }
    
    enum AlertLocation {
        case dropdown
        case overlay
        case sidebar
    }
    
    private static var alertQueue = [Alert]()
    private static var alertControllers = [NSViewController]()
    private static var alertShowing = false
    
    // Sets in the MasterViewController viewDidLoad - Location of alerts temporarily.
    static weak var masterViewController: MasterViewController!
    
    ///
    private static func display(_ location: AlertLocation) {
        
        if !alertShowing {
            alertShowing = true
            switch location {
            case .dropdown:
                // Controller
                let newController = HXAlertDropdown(nibName: "HXAlertDropdown", bundle: nil)!
                alertControllers.append(newController)
                masterViewController.addChildViewController(newController)
                masterViewController.view.addSubview(newController.view)
                newController.button_ignore.target = self
                newController.button_ignore.action = #selector(Alert.closeAlert)
                
                // Constraints
                newController.topConstraint = newController.view.topAnchor.constraint(equalTo: masterViewController.view.topAnchor, constant: -30)
                newController.topConstraint.isActive = true
                newController.view.leadingAnchor.constraint(equalTo: masterViewController.splitView_content.leadingAnchor).isActive = true
                newController.view.trailingAnchor.constraint(equalTo: masterViewController.view.trailingAnchor).isActive = true
                
                // Visuals
                var minute = "\(Alert.alertQueue[0].minute)"
                if Alert.alertQueue[0].minute < 10 {
                    minute = "0" + minute
                }
                newController.label_time.stringValue = "\(HXTimeFormatter.formatHour(Alert.alertQueue[0].hour)):\(minute)"
                
                if Alert.alertQueue[0].course == nil {
                    newController.label_course.stringValue = "Error"
                } else {
                    newController.label_course.stringValue = Alert.alertQueue[0].course!.title! + ":"
                }
                newController.label_content.stringValue = Alert.alertQueue[0].content
                if Alert.alertQueue[0].question == nil {
                    newController.label_accept.isHidden = true
                    newController.label_accept.isEnabled = false
                    newController.image_underline.isHidden = true
                } else {
                    newController.label_accept.stringValue = Alert.alertQueue[0].question!
                    newController.button_accept.target = Alert.alertQueue[0].target
                    newController.button_accept.action = Alert.alertQueue[0].action
                }
                newController.label_ignore.stringValue = Alert.alertQueue[0].deny
                
                // Starting animation
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.2
                newController.topConstraint.animator().constant = 0
                NSAnimationContext.endGrouping()
            case .overlay:
                let newController = HXAlertOverlay(nibName: "HXAlertOverlay", bundle: nil)!
                masterViewController.addChildViewController(newController)
            case .sidebar:
                let newController = HXAlertSidebar(nibName: "HXAlertSidebar", bundle: nil)!
                masterViewController.addChildViewController(newController)
            }
        }
    }
    private static func dequeue() {
        if alertQueue.count > 0 {
            alertQueue.removeFirst()
            alertControllers[0].view.removeFromSuperview()
            alertControllers[0].removeFromParentViewController()
            alertControllers.removeFirst()
            if alertQueue.count > 0 {
                display(.dropdown)
            }
        }
    }
    
    // MARK: - App Alert controls above
    
    let hour: Int
    let minute: Int
    let course: Course?
    let content: String
    let question: String?
    let deny: String
    let action: Selector?
    let target: AnyObject?
    let type: AlertType
    /// This indicates that an alert is deleted even if it may still be in the alertQueue.
    /// This occurs when an alert is still sliding off screen.
    var removed = false
    
    /// Question parameter is the label applied to accepting the notification's action but can be
    /// provided with a nil in order for the accept button not to be displayed.
    init(hour: Int, minute: Int, course: Course?, content: String, question: String?, deny: String, action: Selector?, target: AnyObject?, type: AlertType) {
        self.hour = hour
        self.minute = minute
        self.course = course
        self.content = content
        self.question = question
        self.deny = deny
        self.action = action
        self.target = target
        self.type = type
        
        // Check if course already has deletion alert
        if type == .deletion {
            for alert in Alert.alertQueue {
                if alert.type == .deletion && alert.course == course {
                    // This course already had a deletion alert
                    return
                }
            }
        } else
        // Check if a future alert already exists for course. Remove it so the new Alert can be displayed
        if type == .future {
            for x in 0..<Alert.alertQueue.count {
                if Alert.alertQueue[x].type == .future && Alert.alertQueue[x].course == course {
                    Alert.remove(at: x)
                    break
                }
            }
        } else
        // Check if course is happening, in which case remove the future alerts
        if type == .happening {
            for x in 0..<Alert.alertQueue.count {
                if (Alert.alertQueue[x].type == .happening || Alert.alertQueue[x].type == .future) && Alert.alertQueue[x].course == course {
                    Alert.remove(at: x)
                    break
                }
            }
        }
        
        // Check if this alert does not already exist
        if !Alert.alertQueue.contains(where: {
            !$0.removed &&
            $0.hour == self.hour &&
            $0.minute == self.minute &&
            $0.course == self.course &&
            $0.content == self.content}) {
            
            Alert.alertQueue.append(self)
            
            if !Alert.alertShowing {
                Alert.display(.dropdown)
            }
        }
    }
    
    /// This initializer will assume the hour and minute is the current calendar time. Convenience initializer.
    convenience init(course: Course?, content: String, question: String?, deny: String, action: Selector?, target: AnyObject?, type: AlertType) {
        let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
        let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
        
        self.init(hour: hour, minute: minute, course: course, content: content, question: question, deny: deny, action: action, target: target, type: type)
    }
    
    /// Dequeue alert.
    @objc public static func closeAlert() {
        
        if Alert.alertQueue.count == 0 {
            return
        }
        
        Alert.alertQueue[0].removed = true
        
        if let controller = Alert.alertControllers[0] as? HXAlertDropdown {
            print("Closing dropdown alert.")
            controller.button_accept.isEnabled = false
            
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.2
            NSAnimationContext.current().completionHandler = {
                Alert.alertShowing = false
                Alert.dequeue()
            }
            controller.topConstraint.animator().constant = -30
            NSAnimationContext.endGrouping()
        }
//        else
//        if let controller = Alert.alertControllers[0] as? HXAlertOverlay {
//
//        } else
//        if let controller = Alert.alertControllers[0] as? HXAlertSidebar {
//
//        }
    }
    
    /// Use this instead of Alert.alertQueue.remove(at:), will check if the alert is visible.
    private static func remove(at index: Int) {
        if index > 0 {
            Alert.alertQueue.remove(at: index)
        } else if Alert.alertShowing {
            // Alert is showing if its index 0
            Alert.closeAlert()
        }
    }
    
    /// Probably used after a .deletion alert has been confirmed, will remove
    /// all alerts with the provided course title.
    public static func flushAlerts(for course: Course) {
        for x in stride(from: Alert.alertQueue.count - 1, through: 0, by: -1) {
            if Alert.alertQueue[x].course == course {
                Alert.remove(at: x)
            }
        }
    }
    
    public static func checkExpiredAlerts() {
        for x in 0..<alertQueue.count {
            if alertQueue[x].type == .happening && alertQueue[x].course != nil {
                
                let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
                // Get calendar date to deduce semester
                let yearComponent = calendar.component(.year, from: Date())
                
                // This should be adjustable in the settings, assumes Jul-Dec is Fall. Jan-Jun is Spring.
                var semesterTitle = "spring"
                if calendar.component(.month, from: Date()) >= 7 {
                    semesterTitle = "fall"
                }
                
                if Semester.retrieveSemester(titled: semesterTitle, in: yearComponent) != nil {
                    if alertQueue[x].course!.duringTimeSlot() == nil {
                        // Course is not happening at the moment... So this alert doesn't apply anymore.
                        Alert.remove(at: x)
                    }
                }
                
            }
        }
    }
    
//    /// In case a user lets a course go by with a course .happening alert, this can
//    /// be called to nullify a .happening alert.
//    public static func flushHappening(for course: String) {
//        for x in 0..<Alert.alertQueue.count {
//            if Alert.alertQueue[x].type == .happening && Alert.alertQueue[x].course == course {
//                Alert.remove(at: x)
//            }
//        }
//    }
}
