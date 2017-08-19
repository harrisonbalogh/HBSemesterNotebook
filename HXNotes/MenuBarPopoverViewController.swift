//
//  MenuBarPopover.swift
//  HXNotes
//
//  Created by Harrison Balogh on 7/14/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class MenuBarPopoverViewController: NSViewController {
    
    @IBOutlet weak var lecturesStackView: NSStackView!
    var timeSlotsToday = [TimeSlot]()
    @IBOutlet weak var stackViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var showMoreButton: NSButton!
    @IBOutlet weak var tomorrowLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func action_quitButton(_ sender: NSButton) {
        NSApp.terminate(sender)
    }
    
    @IBAction func action_showMore(_ sender: NSButton) {
        
        for subview in lecturesStackView.subviews {
            subview.removeFromSuperview()
        }
        
        if sender.title == "Show More" {
            for timeSlot in timeSlotsToday {
                let item = MenuBarLectureItem.instance(with: timeSlot)!
                lecturesStackView.addArrangedSubview(item)
                stackViewHeightConstraint.constant = item.frame.height * CGFloat(lecturesStackView.subviews.count)
            }
            showMoreButton.title = "Show Less"
        } else if sender.title == "Show Less" {
            for timeSlot in timeSlotsToday {
                let item = MenuBarLectureItem.instance(with: timeSlot)!
                lecturesStackView.addArrangedSubview(item)
                stackViewHeightConstraint.constant = item.frame.height * CGFloat(lecturesStackView.subviews.count)
                // Only add up to INITIAL_SHOWN time slots, otherwise user will have to use Show More button
                if lecturesStackView.subviews.count == 2 {
                    break
                }
            }
            showMoreButton.title = "Show More"
        }
        
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        updateLectures(from: AppDelegate.scheduleAssistant.currentSemester)
    }
    
    func updateLectures(from semester: Semester) {
        
        for subview in lecturesStackView.subviews {
            subview.removeFromSuperview()
        }
        
        let hour = NSCalendar.current.component(.hour, from: Date())
        let minute = NSCalendar.current.component(.minute, from: Date())
        
        let weekday = NSCalendar.current.component(.weekday, from: Date())
        let minuteOfDay = hour * 60 + minute
        
        timeSlotsToday = [TimeSlot]()
        var timeSlotsTomorrow = [TimeSlot]()
        
        for case let course as Course in semester.courses! {
            for case let timeSlot as TimeSlot in course.timeSlots! {
                let timeDay = Int(timeSlot.weekday)
                let timeStop = Int(timeSlot.stopMinute)
                if timeDay == weekday {
                    if timeStop > minuteOfDay {
                        timeSlotsToday.append(timeSlot)
                    }
                } else {
                    let dayTomorrow = ((weekday + 1) % 8) + Int(floor(Double((weekday+1) / 8)))
                    if timeDay == dayTomorrow {
                        timeSlotsTomorrow.append(timeSlot)
                    }
                }
            }
        }
        
        let INITIAL_SHOWN = 2
        
        if timeSlotsToday.count == 0 {
            showMoreButton.isEnabled = false
            showMoreButton.title = "No upcoming lectures today."
            stackViewHeightConstraint.constant = 0
        } else {
            timeSlotsToday.sort(by: {$0.startMinute < $1.startMinute})
            
            for timeSlot in timeSlotsToday {
                let item = MenuBarLectureItem.instance(with: timeSlot)!
                lecturesStackView.addArrangedSubview(item)
                stackViewHeightConstraint.constant = item.frame.height * CGFloat(lecturesStackView.subviews.count)
                // Only add up to INITIAL_SHOWN time slots, otherwise user will have to use Show More button
                if lecturesStackView.subviews.count == INITIAL_SHOWN {
                    break
                }
            }
            if timeSlotsToday.count > INITIAL_SHOWN && lecturesStackView.subviews.count == INITIAL_SHOWN {
                showMoreButton.isEnabled = true
                showMoreButton.title = "Show More"
            } else {
                showMoreButton.isEnabled = false
                showMoreButton.title = "All Times Shown"
            }
        }
        
        
        
        if timeSlotsTomorrow.count == 0 {
            tomorrowLabel.stringValue = "No lectures tomorrow."
        } else {
            timeSlotsTomorrow.sort(by: {$0.startMinute < $1.startMinute})
            let start = timeSlotsTomorrow[0].startMinute
            tomorrowLabel.stringValue = "First lecture tomorrow is at \(HXTimeFormatter.formatTime(start)) for \(timeSlotsTomorrow[0].course!.title!)."
        }
    }
}
