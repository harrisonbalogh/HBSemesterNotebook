//
//  SidebarViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/26/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController {
    
    var weekCount = 0
    
//    func action_addEditableCourse() {
//        // Creates new course data model and puts new view in ledgerStackView
//        pushEditableCourse( selectedSemester.createCourse() )
//    }

    var bottomBufferView: NSView!
    var bottomBufferHeightConstraint: NSLayoutConstraint!
    @IBOutlet var ledgerStackView: NSStackView!
    @IBOutlet var ledgerClipView: HXFlippedClipView!
    @IBOutlet var ledgerScrollView: NSScrollView!
    var lectureStackView: NSStackView!
    weak var masterViewController: MasterViewController!
    
    // MARK: References - Data Objects
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    var selectedSemester: Semester! {
        didSet {
//            // Clear old course visuals
////            popCourses()
//            // Get courses from this semester
//            if selectedSemester.courses!.count > 0 {
//                for case let course as Course in selectedSemester.courses! {
//                    if course.timeSlots!.count == 0 {
//                        editingMode()
//                        return
//                    }
//                    for case let timeSlot as TimeSlot in course.timeSlots! {
//                        if !timeSlot.valid {
//                            editingMode()
//                            return
//                        }
//                    }
//                }
//                viewingMode()
//                if selectedSemester.courses!.count == 1 {
//                    // Only 1 course in semester, so select it
//                    selectedCourse = (selectedSemester.courses![0] as! Course)
//                } else {
//                    // Prevent getting called twice since lectureCheck() called on selectedCourse set (above).
//                    AppDelegate.scheduleAssistant.checkHappening()
//                }
//            } else {
//                editingMode()
//            }
        }
    }
    var selectedCourse: Course! {
        didSet {
            if selectedCourse != nil {
                selectedCourse.fillAbsentLectures()
                // Populate ledgerStackView
                loadLectures(from: selectedCourse)
                // Fill in absent lectures since last app launch
                AppDelegate.scheduleAssistant.checkHappening()
                // Update editorVC buffer spacing
//                notifyHeightUpdate()
                // Deselect all other buttons excepts selected one.
                for case let courseButton as HXCourseBox in ledgerStackView.arrangedSubviews {
                    if courseButton.labelTitle.stringValue != selectedCourse.title {
                    } else {
                        // Scroll to button
                        let lectureY = ledgerStackView.frame.height - (courseButton.frame.origin.y + courseButton.frame.height) + 2
                        // Animate scroll to course
                        NSAnimationContext.beginGrouping()
                        NSAnimationContext.current().duration = 0.5
                        ledgerClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: lectureY))
                        NSAnimationContext.endGrouping()
                    }
                }
            } else {
                popLectures()
                if bottomBufferHeightConstraint != nil {
                    bottomBufferHeightConstraint.constant = 0
                }
            }
            // Notify masterViewController that a course was selected
            masterViewController.notifyCourseSelection(course: selectedCourse)
        }
    }
    
    // MARK: ––– Initialization –––
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // Sidebar needs to keep an updated representation of the data objects in persistence.
//        NotificationCenter.default.addObserver(self, selector: #selector(notifyContextObjectsUpdate(notification:)),
//                                               name: .NSManagedObjectContextObjectsDidChange, object: appDelegate.managedObjectContext)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
    }

    // MARK: ––– Populating LedgerStackView –––
    
//    /// Access this function by setting SidebarViewController's selectedSemester.
//    /// Repopulates the ledgerStackView and Sidebar visuals to display HXCourseEditBox's.
//    private func editingMode() {
//        selectedCourse = nil
//        loadEditableCourses(fromSemester: selectedSemester)
//        masterViewController.notifySemesterEditing(semester: selectedSemester)
//        
//        // UI control flow update - Note the RETURN call
//        if selectedSemester.courses!.count == 0 {
//            masterViewController.notifyInvalidSemester()
//        } else {
//            for case let course as Course in selectedSemester.courses! {
//                if course.timeSlots!.count == 0 {
//                    masterViewController.notifyInvalidSemester()
//                    return
//                }
//                for case let timeSlot as TimeSlot in course.timeSlots! {
//                    if !timeSlot.valid {
//                        masterViewController.notifyInvalidSemester()
//                        return
//                    }
//                }
//            }
//            masterViewController.notifyValidSemester()
//        }
//    }
//    
////    /// Access this function by setting SidebarViewController's selectedSemester.
////    /// Repopulates the ledgerStackView and Sidebar visuals to display HXCourseBox's.
//    private func viewingMode() {
//        loadCourses(fromSemester: selectedSemester)
//        masterViewController.notifySemesterViewing(semester: selectedSemester)
//    }
//    
//    / Populates ledgerStackView with all course data from given semester as HXCourseEditBox's.
//    private func loadEditableCourses(fromSemester semester: Semester) {
////        popCourses()
////        if bottomBufferHeightConstraint != nil {
////            bottomBufferHeightConstraint.constant = 0
////        }
//        // When first loading editable courses, append the 'New Course' button at end of ledgerStackView
//        let addBox = HXCourseAddBox.instance(target: self, action: #selector(SidebarViewController.action_addEditableCourse))
//        ledgerStackView.addArrangedSubview(addBox!)
//        addBox?.widthAnchor.constraint(equalTo: ledgerStackView.widthAnchor).isActive = true
//        // Populate ledgerStackView with HXCourseEditBox's
//        for case let course as Course in semester.courses! {
//            pushEditableCourse( course )
//        }
//        if semester.courses!.count != 0 {
//            notifyTimeSlotAdded()
//        }
//    }
    
    /// Handles purely the visual aspect of editable courses. Internal use only. Adds a new HXCourseEditBox to the ledgerStackView.
//    private func pushEditableCourse(_ course: Course) {
//        let newBox = HXCourseEditBox.instance(with: course, withCourseIndex: ledgerStackView.subviews.count-1, withParent: self)
//        ledgerStackView.insertArrangedSubview(newBox!, at: ledgerStackView.subviews.count - 1)
//        newBox?.widthAnchor.constraint(equalTo: ledgerStackView.widthAnchor).isActive = true
//        masterViewController.notifyCourseAddition()
//        if course.timeSlots!.count == 0 {
//            masterViewController.notifyInvalidSemester()
//        }
//    }
    
    /// Handles purely the visual aspect of editable courses. Internal use only. Removes the given HXCourseEditBox from the ledgerStackView
//    private func popEditableCourse(_ course: HXCourseEditBox) {
//        course.removeFromSuperview()
//        appDelegate.managedObjectContext.delete( selectedSemester.retrieveCourse(named: course.labelCourse.stringValue) )
//        appDelegate.saveAction(self)
//        masterViewController.notifyCourseDeletion()
//    }
    
//    /// Handles purely the visual aspect of courses. Internal use only. Removes all HXCourseBox's from the ledgerStackView.
//    private func popCourses() {
//        popLectures()
//        for c in ledgerStackView.arrangedSubviews {
//            c.removeFromSuperview()
//        }
//    }
    
    /// Called when a course is pressed in the ledgerStackView. 
    /// Populate ledgerStackView with the loaded lectures from the given course.
    private func loadLectures(from course: Course) {
//        self.popLectures()
//        lectureStackView = NSStackView()
//        lectureStackView.orientation = NSUserInterfaceLayoutOrientation.vertical
//        lectureStackView.spacing = 0
//        var index = 0
//        for case let c as HXCourseBox in ledgerStackView.arrangedSubviews {
//            index += 1
//            if c.labelTitle.stringValue == course.title! {
//                break
//            }
//        }
//        if ledgerStackView.arrangedSubviews.count == index {
//            print("This... never happens...")
//            ledgerStackView.addArrangedSubview(lectureStackView)
//        } else {
//            ledgerStackView.insertArrangedSubview(lectureStackView, at: index)
//        }
//        for case let lecture as Lecture in course.lectures! {
//            print("GTTBOT: loadLectures() - pushLecture")
//            pushLecture( lecture )
//        }
    }
    /// Handles purely the visual aspect of lectures. Internal use only. Adds a new HXLectureBox and possibly HXWeekBox to the ledgerStackView.
    private func pushLecture(_ lecture: Lecture) {
//        print("GTTBOT: pushLecture")
//        // Insert the lecture stack view if it isn't already created.
//        if lectureStackView.superview == nil {
//            lectureStackView = NSStackView()
//            lectureStackView.orientation = NSUserInterfaceLayoutOrientation.vertical
//            lectureStackView.spacing = 0
//            ledgerStackView.addArrangedSubview(lectureStackView)
//        }
//        // Insert weekbox on first lecture, then insert every time week changes from previous lecture.
//        if selectedCourse.lectures!.count == 1 {
//            lectureStackView.addArrangedSubview(HXWeekBox.instance(withNumber: (weekCount+1)))
//            weekCount += 1
//        } else {
//            // Following week deducation requires sorted time slots
//            if lecture.course!.needsSort {
//                lecture.course!.sortTimeSlots()
//            }
//            // If the lecture requested to be pushed is the first time slot in the week, it must be a new week
//            if lecture.course!.timeSlots?.index(of: lecture.timeSlot!) == 0 {
//                lectureStackView.addArrangedSubview(HXWeekBox.instance(withNumber: (weekCount+1)))
//                weekCount += 1
//            }
//        }
//        // If absent, create an absent box, instead of a normal box
//        if lecture.absent {
//            let newBox = HXAbsentLectureBox.instance()
//            lectureStackView.addArrangedSubview(newBox!)
//            newBox!.widthAnchor.constraint(equalTo: ledgerStackView.widthAnchor).isActive = true
//        } else {
//            let year = lecture.course!.semester!.year
//            let newBox = HXLectureBox.instance(numbered: lecture.number, dated: "\(lecture.month)/\(lecture.day)/\(year % 100)", owner: self)
//            lectureStackView.addArrangedSubview(newBox!)
//            newBox?.widthAnchor.constraint(equalTo: ledgerStackView.widthAnchor).isActive = true
//        }
    }
    /// Handles purely the visual aspect of lectures. Internal use only. Removes all HXLectureBox's and HXWeekBox's from the ledgerStackView.
    private func popLectures() {
//        if lectureStackView != nil {
//            for v in lectureStackView.arrangedSubviews {
//                v.removeFromSuperview()
//            }
//            lectureStackView.removeFromSuperview()
//        }
//        weekCount = 0
    }
    
    // MARK: ––– LedgerStackView Visuals –––

    /// Apply course selection visuals. Nil value is appropriate when clearing selection.
    /// See selectedCourse didSet method for more details.
    func select(course: Course?) {
        self.selectedCourse = course
    }
    
    /// Apply lecture focus visuals. Nil value is appropriate when clearing focus.
    func focus(lecture: Lecture?) {
        if lecture == nil {
            // Unfocus all other buttons
            for case let box as HXLectureBox in lectureStackView.arrangedSubviews {
                box.unfocus()
            }
        } else {
            // Unfocus all other buttons except new focus.
            for case let box as HXLectureBox in lectureStackView.arrangedSubviews {
                if box.labelTitle.stringValue != "Lecture \(lecture!.number)" {
                    box.unfocus()
                } else {
                    box.focus()
                    // Scroll to lecture box..................
                    let lectureY = ledgerStackView.frame.height - (lectureStackView.frame.origin.y + box.frame.origin.y + box.frame.height)
                    let clipperY = ledgerClipView.bounds.origin.y
                    // Scroll only if not visible
                    if lectureY > (ledgerScrollView.frame.height + clipperY) || lectureY < clipperY {
                        // Animate scroll to lecture
                        NSAnimationContext.beginGrouping()
                        NSAnimationContext.current().duration = 1
                        ledgerClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: lectureY))
                        NSAnimationContext.endGrouping()
                    }
                }
            }
        }
    }
    
    /// Notify Sidebar from a HXLectureBox that a lecture has been clicked.
    func select(lecture: String) {
        masterViewController.notifyLectureSelection(lecture: lecture)
    }
    
    /// User scrolling should cancel any scroll animations. Else the clipper stutters.
//    func didLiveScroll() {
//        // Stop any scrolling animations currently happening on the clipper
//        NSAnimationContext.beginGrouping()
//        NSAnimationContext.current().duration = 0 // This overwrites animator proxy object with 0 duration aimation
//        ledgerClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: ledgerClipView.bounds.origin.y))
//        NSAnimationContext.endGrouping()
//    }
    
    /// Reevaluate the height of the bottom buffer space box, which keeps the selected course able
    /// to be scrolled so it aligns with the top of the view.
//    private func notifyHeightUpdate() {
//        
//        if bottomBufferHeightConstraint != nil {
//            bottomBufferHeightConstraint.constant = 0
//        }
//        ledgerScrollView.layoutSubtreeIfNeeded()
//        
//        for case let courseButton as HXCourseBox in ledgerStackView.arrangedSubviews {
//            if courseButton.labelTitle.stringValue == selectedCourse.title {
//                let y = ledgerStackView.frame.height - (courseButton.frame.origin.y + courseButton.frame.height) + 2
//                if (ledgerStackView.frame.height - bottomBufferHeightConstraint.constant) < (ledgerScrollView.frame.height + y) {
//                    bottomBufferHeightConstraint.constant = (ledgerScrollView.frame.height + y) - ledgerStackView.frame.height
//                } else {
//                    bottomBufferHeightConstraint.constant = 0
//                }
//                break
//            }
//        }
//    }
    
    // MARK: ––– Lecture & Course Model –––

    /// Confirms removal of all information associated with a course object. Model and Views
    internal func removeCourse(_ editBox: HXCourseEditBox) {
        // Remove course from ledgerStackView, reset grid spaces of timeSlots, delete data model
//        popEditableCourse(editBox)
        // Prevent user from accessing lecture view if there are no courses
        if selectedSemester.courses!.count == 0 {
            masterViewController.notifyInvalidSemester()
        } else {
            // Check if the remaining courses have any TimeSlots
            for case let course as Course in selectedSemester.courses! {
                if course.timeSlots!.count == 0 {
                    masterViewController.notifyInvalidSemester()
                    return
                }
            }
            masterViewController.notifyValidSemester()
        }
    }
    
    /// Confirms removal of all information associated with a TimeSlot object. Model and Views
    internal func removeTimeSlot(_ timeSlot: TimeSlot) {
        appDelegate.managedObjectContext.delete( timeSlot )
        appDelegate.saveAction(self)
//        masterViewController.notifyTimeSlotDeletion()
    }
    
    /// Creates a new Lecture data object and updates
    /// ledgerStackView visuals with a new HXLectureBox.
    public func addLecture() {
        
        // This assumes that an alert called addLecture.
        Alert.closeAlert()
        
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        // Get calendar date to deduce semester
        let yearComponent = calendar.component(.year, from: Date())
        
        // This should be adjustable in the settings, assumes Jul-Dec is Fall. Jan-Jun is Spring.
        var semesterTitle = "spring"
        if calendar.component(.month, from: Date()) >= 7 {
            semesterTitle = "fall"
        }
        
        // See if the current semester exists in the persistant store
        if let currentSemester = Semester.retrieveSemester(titled: semesterTitle, in: yearComponent) {
            if let timeSlotHappening = currentSemester.duringCourse() {
                if timeSlotHappening.course!.theoreticalLectureCount() != timeSlotHappening.course!.lectures!.count || timeSlotHappening.course!.theoreticalLectureCount() == 0 {
                    if selectedSemester != currentSemester {
                        selectedSemester = currentSemester
                    }
                    if selectedCourse != timeSlotHappening.course! {
                        selectedCourse = timeSlotHappening.course!
                    }
                    // Displays lecture in the ledgerStackView
                    let newLec = timeSlotHappening.course!.createLecture(during: timeSlotHappening.course!.duringTimeSlot()!, on: nil, in: nil)
                    pushLecture( newLec )
                    // Displays lecture in the lectureStackView
                    masterViewController.notifyLectureAddition(lecture: newLec)
                } else {
                    print("No lectures to add??? Theoretical count: \(timeSlotHappening.course!.theoreticalLectureCount())")
                }
            } else {
                // User probably waited too long to accept lecture, so display error
                let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
                let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
                let _ = Alert(hour: hour, minute: minute, course: nil, content: "Can't add a new lecture when a course isn't happening.", question: nil, deny: "Close", action: nil, target: nil, type: .custom)
            }
        }
    }
    
    // MARK: ––– Notifiers –––
    
//    func notifySemesterEditing() {
//        editingMode()
//    }
//    func notifyViewingMode() {
//        viewingMode()
//    }
    
//    /// Received from Notification Center on a managed object context change.
//    func notifyContextObjectsUpdate(notification: NSNotification) {
//        guard let userInfo = notification.userInfo else { return }
//        
//        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
//            if inserts.filter({$0 is TimeSlot}).count > 0 {
//                // New TimeSlot added
//            }
//        }
//        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
//            //updates.flatMap({ $0 as? TimeSlot })
//            updates.filter({
//                $0 is TimeSlot && ($0.changedValues().keys.contains("startTime") || $0.changedValues().keys.contains("stopTime"))}).count > 0 {
//                    // Timeslot changed
//                }
//        }
//        if let
//    }
    
    ///
    func notifyTimeSlotChange() {
        
        selectedSemester.validateSchedule()
        
        masterViewController.notifyTimeSlotChange()
        
        // If any course don't have any TimeSlots, don't allow user to proceed to Editor...
        // Also don't proceed if any TimeSlots overlap
        for case let course as Course in selectedSemester.courses! {
            if course.timeSlots!.count == 0 {
                masterViewController.notifyInvalidSemester()
                return
            }
            for case let timeSlot as TimeSlot in course.timeSlots! {
                if !timeSlot.valid {
                    masterViewController.notifyInvalidSemester()
                    return
                }
            }
        }
        masterViewController.notifyValidSemester()
    }
    
    /// Notify sidebar that user should be able to finish editing since the
    /// minimum requirement of having at least 1 time established has been met.
    func notifyTimeSlotAdded() {
        
        selectedSemester.validateSchedule()
        
        // If any course don't have any TimeSlots, don't allow user to proceed to Editor
        for case let course as Course in selectedSemester.courses! {
            if course.timeSlots!.count == 0 {
                masterViewController.notifyInvalidSemester()
                return
            }
            for case let timeSlot as TimeSlot in course.timeSlots! {
                if !timeSlot.valid {
                    masterViewController.notifyInvalidSemester()
                    return
                }
            }
        }
        masterViewController.notifyValidSemester()
    }
    
    /// Notify sidebar that user has removed a time slot from a course and should
    /// check if that was the only time slot for course
    func notifyTimeSlotRemoved() {
        
        selectedSemester.validateSchedule()
        
        masterViewController.notifyTimeSlotChange()
        
        // If any courses don't have any TimeSlots, don't allow user to proceed to Editor
        for case let course as Course in selectedSemester.courses! {
            if course.timeSlots!.count == 0 {
                masterViewController.notifyInvalidSemester()
                break
            }
            for case let timeSlot as TimeSlot in course.timeSlots! {
                if !timeSlot.valid {
                    masterViewController.notifyInvalidSemester()
                    break
                }
            }
        }
                
    }
}
