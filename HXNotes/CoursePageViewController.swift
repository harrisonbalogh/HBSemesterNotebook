//
//  CoursePageViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/18/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CoursePageViewController: NSViewController {

    var sidebarVC: SidebarPageController!
    
    @IBOutlet weak var courseLabel: NSTextField!
    
    var weekCount = 0
    @IBOutlet weak var lectureStackView: NSStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if sidebarVC.selectedCourse == nil {
            return
        }
        
        courseLabel.stringValue = sidebarVC.selectedCourse.title!
        
        loadLectures()
        
        sidebarVC.selectedCourse.fillAbsentLectures()
        // Fill in absent lectures since last app launch
        AppDelegate.scheduleAssistant.checkHappening()
    }
    
    @IBAction func action_back(_ sender: NSButton) {
        sidebarVC.prev()
    }
    
    // MARK: - Populating Lectures
    
    /// Populate lectureStackView with the loaded lectures from the selected course.
    func loadLectures() {
        
        // Flush old lectures
        popLectures()
        
        // Add the first week box
        if sidebarVC.selectedCourse.lectures!.count > 0 {
            lectureStackView.addArrangedSubview(HXWeekBox.instance(withNumber: (1)))
            weekCount = 1
        }
        
        // Add all lectures and weekboxes
        for case let lecture as Lecture in sidebarVC.selectedCourse.lectures! {
            pushLecture( lecture )
        }
    }
    
    /// Handles purely the visual aspect of lectures. Internal use only. Adds a new HXLectureBox and possibly HXWeekBox to the ledgerStackView.
    private func pushLecture(_ lecture: Lecture) {

        // Insert weekbox every time week changes from previous lecture.
        // Following week deducation requires sorted time slots
        if lecture.course!.needsSort {
            lecture.course!.sortTimeSlots()
        }
        // If the lecture requested to be pushed is the first time slot in the week, it must be a new week
        if lecture.course!.timeSlots?.index(of: lecture.timeSlot!) == 0 && lectureStackView.arrangedSubviews.count != 1 {
            lectureStackView.addArrangedSubview(HXWeekBox.instance(withNumber: (weekCount+1)))
            weekCount += 1
        }
        // If absent, create an absent box, instead of a normal box
        if lecture.absent {
            let newBox = HXAbsentLectureBox.instance()
            lectureStackView.addArrangedSubview(newBox!)
            newBox!.widthAnchor.constraint(equalTo: lectureStackView.widthAnchor).isActive = true
        } else {
            let year = lecture.course!.semester!.year
            let newBox = HXLectureBox.instance(numbered: lecture.number, dated: "\(lecture.month)/\(lecture.day)/\(year % 100)", owner: self)
            lectureStackView.addArrangedSubview(newBox!)
            newBox?.widthAnchor.constraint(equalTo: lectureStackView.widthAnchor).isActive = true
        }
    }
    /// Handles purely the visual aspect of lectures. Internal use only. Removes all HXLectureBox's and HXWeekBox's from the ledgerStackView.
    private func popLectures() {
        if lectureStackView != nil {
            for v in lectureStackView.arrangedSubviews {
                v.removeFromSuperview()
            }
        }
        weekCount = 0
    }
    
}
