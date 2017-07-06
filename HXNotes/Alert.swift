//
//  Alet.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class Alert {
    
    enum AlertLocation {
        case dropdown
        case overlay
        case sidebar
    }
    
    private static var alertQueue = [Alert]()
    private static var alertControllers = [NSViewController]()
    private static var alertShowing = false
    
    // Sets in the MasterViewController viewDidLoad - Location of alerts temporarily.
    static var masterViewController: MasterViewController!
    
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
                newController.view.leadingAnchor.constraint(equalTo: masterViewController.container_content.leadingAnchor).isActive = true
                newController.view.trailingAnchor.constraint(equalTo: masterViewController.view.trailingAnchor).isActive = true
                
                // Visuals
                var minute = "\(Alert.alertQueue[0].minute)"
                if Alert.alertQueue[0].minute < 10 {
                    minute = "0" + minute
                }
                newController.label_time.stringValue = "\(HXTimeFormatter.formatTime(Alert.alertQueue[0].hour)):\(minute)"
                newController.label_course.stringValue = Alert.alertQueue[0].course
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
    
    let hour: Int
    let minute: Int
    let course: String
    let content: String
    let question: String?
    let deny: String
    let action: Selector?
    let target: AnyObject?
    
    /// Question parameter is the label applied to accepting the notification's action but can be
    /// provided with a nil in order for the accept button not to be displayed.
    init(hour: Int, minute: Int, course: String, content: String, question: String?, deny: String, action: Selector?, target: AnyObject?) {
        self.hour = hour
        self.minute = minute
        self.course = course
        self.content = content
        self.question = question
        self.deny = deny
        self.action = action
        self.target = target
        
        if question != nil {
            if question == "Remove Course" {
                for alert in Alert.alertQueue {
                    if alert.question != nil {
                        if alert.question == "Remove Course" && alert.course == course {
                            // Don't add this alert since a remove course request already exists
                            return
                        }
                    }
                }
            }
        }

        // Check if this alert does not already exist
        if !Alert.alertQueue.contains(where: {
            $0.hour == self.hour &&
            $0.minute == self.minute &&
            $0.course == self.course &&
            $0.content == self.content }) {
            
            Alert.alertQueue.append(self)
            
            if !Alert.alertShowing {
                Alert.display(.dropdown)
            }
        }
    }
    
    /// This initializer will assume the hour and minute is the current calendar time. Convenience initializer.
    convenience init(course: String, content: String, question: String?, deny: String, action: Selector?, target: AnyObject?) {
        let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
        let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
        
        self.init(hour: hour, minute: minute, course: course, content: content, question: question, deny: deny, action: action, target: target)
    }
    
    ///
    @objc public static func closeAlert() {
        
        if let controller = Alert.alertControllers[0] as? HXAlertDropdown {
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
}
