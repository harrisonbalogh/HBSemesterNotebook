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
    func tempAction_date() {
        if let yr = Int(yearLabel.stringValue) {
            lastYearUsed = yr
        } else {
            yearLabel.stringValue = "\(lastYearUsed)"
        }

        if Int(yearLabel.stringValue) != nil {
            if semesterLabel.stringValue == "Spring" {
                selectedSemester = Semester.produceSemester(titled: "spring", in: Int(yearLabel.stringValue)!)
            } else {
                selectedSemester = Semester.produceSemester(titled: "fall", in: Int(yearLabel.stringValue)!)
            }
        }
    }
    func setDate(semester: Semester) {
//        print("    SidebarVC - setting date.")
        lastYearUsed = Int(semester.year)
        yearLabel.stringValue = "\(lastYearUsed)"
        selectedSemester = semester
        semesterLabel.stringValue = selectedSemester.title!.capitalized
    }
    @IBOutlet weak var semesterButtonAnimated: NSButton!
    @IBOutlet weak var semButtonAnimBotConstraint: NSLayoutConstraint!
    @IBOutlet weak var semesterLabel: NSTextField!
    @IBOutlet weak var semesterButton: NSButton!
    @IBOutlet weak var yearButtonAnimated: NSButton!
    @IBOutlet weak var yrButtonAnimBotConstraint: NSLayoutConstraint!
    @IBOutlet weak var yearLabel: NSTextField!
    var lastYearUsed = 0
    @IBAction func action_incrementTime(_ sender: NSButton) {
        NSAnimationContext.runAnimationGroup({context in
            context.duration = 0.3
            if semesterLabel.stringValue == "Spring" {
                semesterButtonAnimated.title = "Fall"
            } else {
                semesterButtonAnimated.title = "Spring"
                yearButtonAnimated.title = "\(Int(self.yearLabel.stringValue)! + 1)"
                yrButtonAnimBotConstraint.animator().constant = semesterButtonAnimated.bounds.height
                yearLabel.animator().setBoundsOrigin(NSPoint(x: 0, y: -semesterButton.bounds.height))
            }
            semButtonAnimBotConstraint.animator().constant = semesterButtonAnimated.bounds.height
            semesterLabel.animator().setBoundsOrigin(NSPoint(x: 0, y: -semesterButton.bounds.height))
        }, completionHandler: {
            if self.semesterLabel.stringValue == "Spring" {
                self.semesterLabel.stringValue = "Fall"
            } else {
                self.semesterLabel.stringValue = "Spring"
                self.yearLabel.stringValue = "\(Int(self.yearLabel.stringValue)! + 1)"
                self.yearLabel.setBoundsOrigin(NSPoint(x: 0, y: 0))
            }
            self.semesterLabel.setBoundsOrigin(NSPoint(x: 0, y: 0))
            self.tempAction_date()
            self.semButtonAnimBotConstraint.constant = 0
            self.yrButtonAnimBotConstraint.constant = 0
        })
    }
    @IBAction func action_decrementTime(_ sender: NSButton) {
        NSAnimationContext.runAnimationGroup({context in
            semButtonAnimBotConstraint.constant = 2 * semesterButtonAnimated.bounds.height
            yrButtonAnimBotConstraint.constant = 2 * semesterButtonAnimated.bounds.height
            context.duration = 0.3
            if semesterLabel.stringValue == "Fall" {
                semesterButtonAnimated.title = "Spring"
            } else {
                semesterButtonAnimated.title = "Fall"
                yearButtonAnimated.title = "\(Int(self.yearLabel.stringValue)! - 1)"
                yrButtonAnimBotConstraint.animator().constant = semesterButtonAnimated.bounds.height
                yearLabel.animator().setBoundsOrigin(NSPoint(x: 0, y: semesterButton.bounds.height))
            }
            semButtonAnimBotConstraint.animator().constant = semesterButtonAnimated.bounds.height
            semesterLabel.animator().setBoundsOrigin(NSPoint(x: 0, y: semesterButton.bounds.height))
        }, completionHandler: {
            if self.semesterLabel.stringValue == "Fall" {
                self.semesterLabel.stringValue = "Spring"
            } else {
                self.semesterLabel.stringValue = "Fall"
                self.yearLabel.stringValue = "\(Int(self.yearLabel.stringValue)! - 1)"
                self.yearLabel.setBoundsOrigin(NSPoint(x: 0, y: 0))
            }
            self.semesterLabel.setBoundsOrigin(NSPoint(x: 0, y: 0))
            self.tempAction_date()
            self.semButtonAnimBotConstraint.constant = 0
            self.yrButtonAnimBotConstraint.constant = 0
        })
    }
    
    @IBAction func action_semesterButton(_ sender: NSButton) {
        if semesterLabel.stringValue == "Fall" {
            action_decrementTime(sender)
        } else {
            action_incrementTime(sender)
        }
    }
    @IBAction func action_editYear(_ sender: Any) {
        NSApp.keyWindow?.makeFirstResponder(self)
        tempAction_date()
    }
    @IBOutlet weak var editSemesterButton: NSButton!
    @IBAction func action_editSemester(_ sender: NSButton) {
        if sender.state == NSOnState {
            editingMode()
        } else {
            viewingMode()
        }
    }
    func action_addEditableCourse() {
        // Creates new course data model and puts new view in ledgerStackView
        pushEditableCourse( selectedSemester.createCourse() )
    }

    var bottomBufferView: NSView!
    var bottomBufferHeightConstraint: NSLayoutConstraint!
    @IBOutlet var ledgerStackView: NSStackView!
    @IBOutlet var ledgerClipView: HXFlippedClipView!
    @IBOutlet var ledgerScrollView: NSScrollView!
    var lectureStackView: NSStackView!
    weak var masterViewController: MasterViewController!
    
    // MARK: References - Data Objects
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    private var selectedSemester: Semester! {
        didSet {
            if oldValue != nil && oldValue == selectedSemester {
                return
            }
            
            // Clear old course visuals
            popCourses()
            // Get courses from this semester
            if selectedSemester.courses!.count > 0 {
                for case let course as Course in selectedSemester.courses! {
                    if course.timeSlots!.count == 0 {
                        editingMode()
                        return
                    }
                    for case let timeSlot as TimeSlot in course.timeSlots! {
                        if !timeSlot.valid {
                            editingMode()
                            return
                        }
                    }
                }
                viewingMode()
                if selectedSemester.courses!.count == 1 {
                    // Only 1 course in semester, so select it
                    selectedCourse = (selectedSemester.courses![0] as! Course)
                } else {
                    // Prevent getting called twice since lectureCheck() called on selectedCourse set (above).
                    AppDelegate.scheduleAssistant.checkHappening()
                }
            } else {
                editingMode()
            }
        }
    }
    var selectedCourse: Course! {
        didSet {
            if oldValue != nil && selectedCourse != nil && oldValue == selectedCourse {
                return
            }
            
            if selectedCourse != nil {
                selectedCourse.fillAbsentLectures()
                // Populate ledgerStackView
                loadLectures(from: selectedCourse)
                // Fill in absent lectures since last app launch
                AppDelegate.scheduleAssistant.checkHappening()
                // Update editorVC buffer spacing
                notifyHeightUpdate()
                // Deselect all other buttons excepts selected one.
                for case let courseButton as HXCourseBox in ledgerStackView.arrangedSubviews {
                    if courseButton.labelTitle.stringValue != selectedCourse.title {
                        courseButton.deselect()
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
                // Deselect all other buttons
                for case let courseButton as HXCourseBox in ledgerStackView.arrangedSubviews {
                    courseButton.deselect()
                }
                bottomBufferHeightConstraint.constant = 0
            }
            // Notify masterViewController that a course was selected
            masterViewController.notifyCourseSelection(course: selectedCourse)
        }
    }
    
    // MARK: ––– Initialization –––
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup observers
//        NotificationCenter.default.addObserver(self, selector: #selector(SidebarViewController.didLiveScroll),
//                                               name: .NSScrollViewDidLiveScroll, object: ledgerClipView)
    }

    // MARK: ––– Populating LedgerStackView –––
    
    /// Access this function by setting SidebarViewController's selectedSemester.
    /// Repopulates the ledgerStackView and Sidebar visuals to display HXCourseEditBox's.
    private func editingMode() {
        loadEditableCourses(fromSemester: selectedSemester)
        masterViewController.notifySemesterEditing(semester: selectedSemester)
        
        // UI control flow update - Note the RETURN call
        editSemesterButton.state = NSOnState
        if selectedSemester.courses!.count == 0 {
            editSemesterButton.isEnabled = false
        } else {
            for case let course as Course in selectedSemester.courses! {
                if course.timeSlots!.count == 0 {
                    editSemesterButton.isEnabled = false
                    return
                }
                for case let timeSlot as TimeSlot in course.timeSlots! {
                    if !timeSlot.valid {
                        editSemesterButton.isEnabled = false
                        return
                    }
                }
            }
            editSemesterButton.isEnabled = true
        }
    }
    
    /// Access this function by setting SidebarViewController's selectedSemester.
    /// Repopulates the ledgerStackView and Sidebar visuals to display HXCourseBox's.
    private func viewingMode() {
        editSemesterButton.isEnabled = true
        editSemesterButton.state = NSOffState
        loadCourses(fromSemester: selectedSemester)
        masterViewController.notifySemesterViewing(semester: selectedSemester)
    }
    
    /// Populates ledgerStackView with all course data from given semester as HXCourseBox's.
    private func loadCourses(fromSemester semester: Semester) {
        popCourses()
        // Add the buffer region for the course list
        bottomBufferView = NSView()
        ledgerStackView.addArrangedSubview(bottomBufferView)
        bottomBufferView.translatesAutoresizingMaskIntoConstraints = false
        bottomBufferView.widthAnchor.constraint(equalTo: ledgerStackView.widthAnchor).isActive = true
        bottomBufferHeightConstraint = bottomBufferView.heightAnchor.constraint(equalToConstant: 0)
        bottomBufferHeightConstraint.isActive = true
        // Add the courses in this semester
        for case let course as Course in semester.courses! {
            pushCourse( course )
        }
    }
    
    /// Populates ledgerStackView with all course data from given semester as HXCourseEditBox's.
    private func loadEditableCourses(fromSemester semester: Semester) {
        popCourses()
        if bottomBufferHeightConstraint != nil {
            bottomBufferHeightConstraint.constant = 0
        }
        // When first loading editable courses, append the 'New Course' button at end of ledgerStackView
        let addBox = HXCourseAddBox.instance(target: self, action: #selector(SidebarViewController.action_addEditableCourse))
        ledgerStackView.addArrangedSubview(addBox!)
        addBox?.widthAnchor.constraint(equalTo: ledgerStackView.widthAnchor).isActive = true
        // Populate ledgerStackView with HXCourseEditBox's
        for case let course as Course in semester.courses! {
            pushEditableCourse( course )
        }
        if semester.courses!.count != 0 {
            notifyTimeSlotAdded()
        }
    }
    
    /// Handles purely the visual aspect of courses. Internal use only. Adds a new HXCourseBox to the ledgerStackView.
    private func pushCourse(_ course: Course) {
        let newBox = HXCourseBox.instance(with: course, owner: self)
        ledgerStackView.insertArrangedSubview(newBox!, at: ledgerStackView.arrangedSubviews.count - 1)
        newBox?.widthAnchor.constraint(equalTo: ledgerStackView.widthAnchor).isActive = true
    }
    
    /// Handles purely the visual aspect of editable courses. Internal use only. Adds a new HXCourseEditBox to the ledgerStackView.
    private func pushEditableCourse(_ course: Course) {
        let newBox = HXCourseEditBox.instance(with: course, withCourseIndex: ledgerStackView.subviews.count-1, withParent: self)
        ledgerStackView.insertArrangedSubview(newBox!, at: ledgerStackView.subviews.count - 1)
        newBox?.widthAnchor.constraint(equalTo: ledgerStackView.widthAnchor).isActive = true
        masterViewController.notifyCourseAddition()
        if course.timeSlots!.count == 0 {
            editSemesterButton.isEnabled = false
            editSemesterButton.state = NSOnState
        }
    }
    
    /// Handles purely the visual aspect of editable courses. Internal use only. Removes the given HXCourseEditBox from the ledgerStackView
    private func popEditableCourse(_ course: HXCourseEditBox) {
        course.removeFromSuperview()
        appDelegate.managedObjectContext.delete( selectedSemester.retrieveCourse(named: course.labelCourse.stringValue) )
        appDelegate.saveAction(self)
        masterViewController.notifyCourseDeletion()
    }
    
    /// Handles purely the visual aspect of courses. Internal use only. Removes all HXCourseBox's from the ledgerStackView.
    private func popCourses() {
        popLectures()
        for c in ledgerStackView.arrangedSubviews {
            c.removeFromSuperview()
        }
    }
    
    /// Called when a course is pressed in the ledgerStackView. 
    /// Populate ledgerStackView with the loaded lectures from the given course.
    private func loadLectures(from course: Course) {
        self.popLectures()
        lectureStackView = NSStackView()
        lectureStackView.orientation = NSUserInterfaceLayoutOrientation.vertical
        lectureStackView.spacing = 0
        var index = 0
        for case let c as HXCourseBox in ledgerStackView.arrangedSubviews {
            index += 1
            if c.labelTitle.stringValue == course.title! {
                break
            }
        }
        if ledgerStackView.arrangedSubviews.count == index {
            print("This... never happens...")
            ledgerStackView.addArrangedSubview(lectureStackView)
        } else {
            ledgerStackView.insertArrangedSubview(lectureStackView, at: index)
        }
        for case let lecture as Lecture in course.lectures! {
            pushLecture( lecture )
        }
    }
    /// Handles purely the visual aspect of lectures. Internal use only. Adds a new HXLectureBox and possibly HXWeekBox to the ledgerStackView.
    private func pushLecture(_ lecture: Lecture) {
        // Insert the lecture stack view if it isn't already created.
        if lectureStackView.superview == nil {
            lectureStackView = NSStackView()
            lectureStackView.orientation = NSUserInterfaceLayoutOrientation.vertical
            lectureStackView.spacing = 0
            ledgerStackView.addArrangedSubview(lectureStackView)
        }
        // Insert weekbox on first lecture, then insert every time weekInYear changes from previous lecture.
        if selectedCourse.lectures!.count == 1 {
            lectureStackView.addArrangedSubview(HXWeekBox.instance(withNumber: (weekCount+1)))
            weekCount += 1
        } else {
            let prevLecWeekInYear = (selectedCourse.lectures![selectedCourse.lectures!.count-2] as! Lecture).weekOfYear
            let currentLecWeekInYear = (selectedCourse.lectures!.lastObject as! Lecture).weekOfYear
            if currentLecWeekInYear != prevLecWeekInYear {
                lectureStackView.addArrangedSubview(HXWeekBox.instance(withNumber: (weekCount+1)))
                weekCount += 1
            }
        }
        // If absent, create an absent box, instead of a normal box
        if lecture.absent {
            let newBox = HXAbsentLectureBox.instance()
            lectureStackView.addArrangedSubview(newBox!)
            newBox!.widthAnchor.constraint(equalTo: ledgerStackView.widthAnchor).isActive = true
        } else {
            let newBox = HXLectureBox.instance(numbered: lecture.number, dated: "\(lecture.monthInYear())/\(lecture.dayInMonth())/\(lecture.course!.semester!.year % 100)", owner: self)
            lectureStackView.addArrangedSubview(newBox!)
            newBox?.widthAnchor.constraint(equalTo: ledgerStackView.widthAnchor).isActive = true
        }
    }
    /// Handles purely the visual aspect of lectures. Internal use only. Removes all HXLectureBox's and HXWeekBox's from the ledgerStackView.
    private func popLectures() {
        if lectureStackView != nil {
            for v in lectureStackView.arrangedSubviews {
                v.removeFromSuperview()
            }
            lectureStackView.removeFromSuperview()
        }
        weekCount = 0
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
    func didLiveScroll() {
        // Stop any scrolling animations currently happening on the clipper
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0 // This overwrites animator proxy object with 0 duration aimation
        ledgerClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: ledgerClipView.bounds.origin.y))
        NSAnimationContext.endGrouping()
    }
    
    /// Reevaluate the height of the bottom buffer space box, which keeps the selected course able
    /// to be scrolled so it aligns with the top of the view.
    private func notifyHeightUpdate() {
        
        bottomBufferHeightConstraint.constant = 0
        ledgerScrollView.layoutSubtreeIfNeeded()
        
        for case let courseButton as HXCourseBox in ledgerStackView.arrangedSubviews {
            if courseButton.labelTitle.stringValue == selectedCourse.title {
                let y = ledgerStackView.frame.height - (courseButton.frame.origin.y + courseButton.frame.height) + 2
                if (ledgerStackView.frame.height - bottomBufferHeightConstraint.constant) < (ledgerScrollView.frame.height + y) {
                    bottomBufferHeightConstraint.constant = (ledgerScrollView.frame.height + y) - ledgerStackView.frame.height
                } else {
                    bottomBufferHeightConstraint.constant = 0
                }
                break
            }
        }
    }
    
    // MARK: ––– Lecture & Course Model –––

    /// Confirms removal of all information associated with a course object. Model and Views
    internal func removeCourse(_ editBox: HXCourseEditBox) {
        // Remove course from ledgerStackView, reset grid spaces of timeSlots, delete data model
        popEditableCourse(editBox)
        // Prevent user from accessing lecture view if there are no courses
        if selectedSemester.courses!.count == 0 {
            editSemesterButton.isEnabled = false
            editSemesterButton.state = NSOnState
        } else {
            // Check if the remaining courses have any TimeSlots
            for case let course as Course in selectedSemester.courses! {
                if course.timeSlots!.count == 0 {
                    editSemesterButton.isEnabled = false
                    editSemesterButton.state = NSOnState
                    return
                }
            }
            editSemesterButton.isEnabled = true
            editSemesterButton.state = NSOnState
        }
    }
    
    /// Confirms removal of all information associated with a TimeSlot object. Model and Views
    internal func removeTimeSlot(_ timeSlot: TimeSlot) {
        appDelegate.managedObjectContext.delete( timeSlot )
        appDelegate.saveAction(self)
        masterViewController.notifyTimeSlotDeletion()
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
            if let courseHappening = currentSemester.duringCourse() {
                if courseHappening.theoreticalLectureCount() - courseHappening.lectures!.count == 1 || courseHappening.theoreticalLectureCount() == 0 {
                    let newLec = courseHappening.createLecture(during: courseHappening.duringTimeSlot()!, absent: nil)
                    // Following two lines won't have any visual effect if they are setting the same value. See didSet
                    selectedSemester = currentSemester
                    selectedCourse = courseHappening
                    // Displays lecture in the ledgerStackView
                    pushLecture( newLec )
                    // Displays lecture in the lectureStackView
                    masterViewController.notifyLectureAddition(lecture: newLec)
                } else {
                    print("No lectures to add??? Theoretical count: \(courseHappening.theoreticalLectureCount())")
                }
            } else {
                // User probably waited too long to accept lecture, so display error
                let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
                let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
                let _ = Alert(hour: hour, minute: minute, course: "Error:", content: "Can't add a new lecture when a course isn't happening.", question: nil, deny: "Close", action: nil, target: nil, type: .custom)
            }
        }
    }
    
    // MARK: ––– Course Drag & Drop Functionality –––
    
    // Reference to index of course being dragged, nil when not dragging
    private var draggedCourse: Course!
    /// HXCourseEditBox - Mouse Up: Stop dragging a course to a time slot
    internal func mouseUp_courseBox(for course: Course, at loc: NSPoint) {
        // Ensure a course was being dragged
        if self.draggedCourse != nil {
            // Remove drag box from superview
            masterViewController.notifyCourseDragEnd(course: course, at: loc)
            self.draggedCourse = nil
        }
    }
    
    /// HXCourseEditBox - Mouse Drag: Drag a course to a time slot
    internal func mouseDrag_courseBox(with editBox: HXCourseEditBox, to loc: NSPoint) {
        if self.draggedCourse == nil {
            self.draggedCourse = editBox.course
            masterViewController.notifyCourseDragStart(editBox: editBox, to: loc)
        } else {
            masterViewController.notifyCourseDragMoved(editBox: editBox, to: loc)
        }
    }
    
    // MARK: ––– Notifiers –––
    
    ///
    func notifyTimeSlotChange() {
        masterViewController.notifyTimeSlotChange()
        
        // If any course don't have any TimeSlots, don't allow user to proceed to Editor...
        // Also don't proceed if any TimeSlots overlap
        for case let course as Course in selectedSemester.courses! {
            if course.timeSlots!.count == 0 {
                editSemesterButton.isEnabled = false
                editSemesterButton.state = NSOffState
                return
            }
            for case let timeSlot as TimeSlot in course.timeSlots! {
                if !timeSlot.valid {
                    editSemesterButton.isEnabled = false
                    editSemesterButton.state = NSOnState
                    return
                }
            }
        }
        editSemesterButton.isEnabled = true
        editSemesterButton.state = NSOnState
    }
    
    /// Notify sidebar that user should be able to finish editing since the
    /// minimum requirement of having at least 1 time established has been met.
    func notifyTimeSlotAdded() {
        
        // If any course don't have any TimeSlots, don't allow user to proceed to Editor
        for case let course as Course in selectedSemester.courses! {
            if course.timeSlots!.count == 0 {
                editSemesterButton.isEnabled = false
                return
            }
            for case let timeSlot as TimeSlot in course.timeSlots! {
                if !timeSlot.valid {
                    editSemesterButton.isEnabled = false
                    return
                }
            }
        }
        editSemesterButton.isEnabled = true
        editSemesterButton.state = NSOnState
    }
    
    /// Notify sidebar that user has removed a time slot from a course and should
    /// check if that was the only time slot for course
    func notifyTimeSlotRemoved() {
        masterViewController.notifyTimeSlotChange()
        // If any courses don't have any TimeSlots, don't allow user to proceed to Editor
        for case let course as Course in selectedSemester.courses! {
            if course.timeSlots!.count == 0 {
                editSemesterButton.isEnabled = false
                editSemesterButton.state = NSOnState
                break
            }
            for case let timeSlot as TimeSlot in course.timeSlots! {
                if !timeSlot.valid {
                    editSemesterButton.isEnabled = false
                    editSemesterButton.state = NSOnState
                    break
                }
            }
        }
                
    }
    
    // MARK: - TESTING
    
    func test_repeat() {
        print("Test loop call")
        
        editingMode()
        
//        action_editSemester(editSemesterButton)
//        if editSemesterButton.state == NSOnState {
//            editSemesterButton.state = NSOffState
//        } else {
//            editSemesterButton.state = NSOnState
//        }
        
        // Code above.
        self.perform(#selector(self.test_repeat), with: nil, afterDelay: 0.5)
    }
}
