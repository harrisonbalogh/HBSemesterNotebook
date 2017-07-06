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
    func tempAction_addLecture() {
        if let courseHappening = selectedSemester.duringCourse() {
            selectedCourse = courseHappening
            let newLec = courseHappening.newLecture()
            addLecture(newLec)
            masterViewController.notifyLectureAddition(lecture: newLec)
        } else {
            let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
            let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
            let _ = Alert(hour: hour, minute: minute, course: "Error:", content: "Can't add a new lecture when a course isn't happening.", question: nil, deny: "Close", action: nil, target: nil)
        }
        Alert.closeAlert()
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
    var bottomBufferView: NSView!
    var bottomBufferHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var ledgerStackView: NSStackView!
    @IBOutlet weak var ledgerClipView: HXFlippedClipView!
    @IBOutlet weak var ledgerScrollView: NSScrollView!
    var lectureStackView: NSStackView!
    var masterViewController: MasterViewController!
    
    // MARK: References - Data Objects
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    private var selectedSemester: Semester! {
        didSet {
            // Clear old course visuals
            popCourses()
            // Get courses from this semester
            if selectedSemester.courses!.count > 0 {
                for case let course as Course in selectedSemester.courses! {
                    if course.timeSlots!.count == 0 {
                        editingMode()
                        return
                    }
                }
                viewingMode()
                if selectedSemester.courses!.count == 1 {
                    print("No course... but there's only one so select it")
                    selectedCourse = (selectedSemester.courses![0] as! Course)
                } else {
                    // Prevent getting called twice since lectureCheck() called selectedCourse set.
                    lectureCheck()
                }
            } else {
                editingMode()
            }
        }
    }
    var selectedCourse: Course! {
        didSet {
            if selectedCourse != nil {
                // Populate ledgerStackView
                loadLectures(from: selectedCourse)
                // Fill in absent lectures since last app launch
                lectureCheck()
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
    
    // MARK: ___ Initialization ___
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup observers
        NotificationCenter.default.addObserver(self, selector: #selector(SidebarViewController.didLiveScroll),
                                               name: .NSScrollViewDidLiveScroll, object: ledgerClipView)
        
        // Start timers
        let date = Date()
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        // Listen for hour change
        let dateMinute = calendar.component(.minute, from: date)
        self.perform(#selector(SidebarViewController.notifyHour), with: nil, afterDelay: Double(60 - dateMinute) * 60)
        // Listen for minute change
        let dateSecond = calendar.component(.second, from: date)
        self.perform(#selector(SidebarViewController.notifyMinute), with: nil, afterDelay: Double(60 - dateSecond))
    }
    
    override func viewDidAppear() {
        // Default to current year
        let yr = NSCalendar.current.component(.year, from: NSDate() as Date)
        yearLabel.stringValue = "\(yr)"
        // Default to current semester by assuming Fall: [July, December]
        let month = NSCalendar.current.component(.month, from: NSDate() as Date)
        if month >= 7 && month <= 12 {
            semesterLabel.stringValue = "Fall"
        } else {
            semesterLabel.stringValue = "Spring"
        }
        tempAction_date()
    }

    // MARK: ––– Populating LedgerStackView  –––
    
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
        let addBox = HXCourseAddBox.instance(target: self, action: #selector(SidebarViewController.addEditableCourse))
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
        masterViewController.notifyCourseDeletion(named: course.labelCourse.stringValue)
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
            let currentLecWeekInYear = (selectedCourse.lectures![selectedCourse.lectures!.count-1] as! Lecture).weekOfYear
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
            let newBox = HXLectureBox.instance(numbered: lecture.number, dated: "\(lecture.month)/\(lecture.day)/\(lecture.year % 100)", owner: self)
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
    
    /// For internal usage. Creates a new Lecture data object and updates
    /// ledgerStackView visuals with a new HXLectureBox.
    private func addLecture(_ lecture: Lecture) {
        // Displays the provided lecture in the ledgerStackView
        pushLecture( lecture )
        
    }
    
    /// For external and internal usage. Creates a new Course data object and updates
    /// ledgerStackView visuals with a new HXCourseEditBox.
    internal func addEditableCourse() {
        // Creates new course data model and puts new view in ledgerStackView
        pushEditableCourse( selectedSemester.newCourse() )
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
    
    /// Notify sidebar that user should be able to finish editing since the
    /// minimum requirement of having at least 1 time established has been met.
    func notifyTimeSlotAdded() {
        // If any course don't have any TimeSlots, don't allow user to proceed to Editor
        for case let course as Course in selectedSemester.courses! {
            if course.timeSlots!.count == 0 {
                return
            }
        }
        editSemesterButton.isEnabled = true
        editSemesterButton.state = NSOnState
    }
    
    /// Notify sidebar that user has removed a time slot from a course and should
    /// check if that was the only time slot for course
    func notifyTimeSlotRemoved() {
        // If any courses don't have any TimeSlots, don't allow user to proceed to Editor
        for case let course as Course in selectedSemester.courses! {
            if course.timeSlots!.count == 0 {
                editSemesterButton.isEnabled = false
                editSemesterButton.state = NSOnState
                break
            }
        }
    }
    
    // MARK: Timing Notifiers - being moved to its own Schedule Assistant class
    /// Check if a lecture is occuring and, if so, prompt user for lecture action
    func lectureCheck() {
        print("Lecture Check...")
        let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
        let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
        
        // If a course is open and they let a lecture pass, implant absent lecture
        if selectedCourse != nil {
            let lecturesToCreate = selectedCourse.theoreticalLectureCount() - selectedCourse.lectures!.count
            if lecturesToCreate > 0 {
                // Need to fill in the dayOfWeek and weekOfYear for each absent lecture.
                // Start with how many lectures there are currently and add course starting day
                let lectureStartingDay = selectedCourse.lectureInWeek(for: Int((selectedCourse.lectures![0] as! Lecture).weekDay)) - 1
                let count = selectedCourse.lectures!.count + lectureStartingDay
                
                for i in 0..<lecturesToCreate {
                    // Mod weekday and convert that lecture index to a specific calendar weekday
                    let weekday = selectedCourse.weekdayForLecture(number: ((count + i) % selectedCourse.daysPerWeek()))!
                    // Number of weeks missing added to starting week for course, mod by max weeks.
                    let weekInYear = (Int((count + i) / selectedCourse.daysPerWeek()) + (selectedCourse.lectures![0] as! Lecture).weekOfYear) % 52
                    pushLecture(selectedCourse.newAbsentLecture(on: Int16(weekday), in: weekInYear))
                }
            }
            print("    selectedCourse.theoreticalLectureCount(): \(selectedCourse.theoreticalLectureCount())")
            if lecturesToCreate == 1 {
                let _ = Alert(hour: hour, minute: minute, course: selectedCourse.title!, content: "lecture missed.", question: nil, deny: "Close", action: nil, target: nil)
            } else if lecturesToCreate > 1 {
                let _ = Alert(hour: hour, minute: minute, course: selectedCourse.title!, content: "\(lecturesToCreate) lectures missed.", question: nil, deny: "Close", action: nil, target: nil)
            }
        }
        if let courseHappening = selectedSemester.duringCourse() {
            // Check if this is the first lecture
            print("    courseHappening.theoreticalLectureCount() for course happening: \(courseHappening.theoreticalLectureCount())")
            if courseHappening.theoreticalLectureCount() == 0 && courseHappening.lectures!.count == 0 {
                let _ = Alert(hour: hour, minute: minute, course: courseHappening.title!, content: "is starting. Create first lecture?", question: "Create Lecture 1", deny: "Ignore", action: #selector(tempAction_addLecture), target: self)
            } else {
                // This will allow a new lecture to be made only once, lectureDisparity will increase to 1 once a new lecture is added.
                let lectureDisparity = courseHappening.theoreticalLectureCount() - courseHappening.lectures!.count
                if lectureDisparity == 0 {
                    let _ = Alert(hour: hour, minute: minute, course: courseHappening.title!, content: "is starting.", question: "Start Lecture", deny: "Ignore", action: #selector(tempAction_addLecture), target: self)
                }
            }
            
        }
        if let futureCourse = selectedSemester.futureCourse() {
            let hour = NSCalendar.current.component(.hour, from: NSDate() as Date)
            let minute = NSCalendar.current.component(.minute, from: NSDate() as Date)
            
            let _ = Alert(hour: hour, minute: minute, course: futureCourse.title!, content: "is starting in \(60 - minute) minutes.", question: nil, deny: "Close", action: nil, target: nil)
        }
    }
    /// Do not call this method. A perform() is called and reset on this notifyHour selector.
    func notifyHour() {
        
        print("Hour")
        
        lectureCheck()
        
        // Place code above. The following resets timer. Do not alter.
        let date = Date()
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let dateComponent = calendar.component(.minute, from: date)
        self.perform(#selector(SidebarViewController.notifyHour), with: nil, afterDelay: Double(60 - dateComponent) * 60)
    }
    /// Do not call this method. A perform() is called and reset on this notifyMinute selector.
    func notifyMinute() {
        
        print("Minute")
        
        lectureCheck()
        
        // Place code above. The following resets timer. Do not alter.
        let date = Date()
        let calendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let dateComponent = calendar.component(.second, from: date)
        self.perform(#selector(SidebarViewController.notifyMinute), with: nil, afterDelay: Double(60 - dateComponent))
    }
}
