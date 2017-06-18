//
//  SidebarViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/26/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController {
    
    // TEMP UI ELEMENTS
    // Need to decide on 2 things with weekCount. Calculate it based on starting lecture?
    // And do I fill in missed lectures
    var weekCount = 0
    var lectureCount = 0
    func tempAction_date() {
        if let yr = Int(yearLabel.stringValue) {
            lastYearUsed = yr
        } else {
            yearLabel.stringValue = "\(lastYearUsed)"
        }

        if Int(yearLabel.stringValue) != nil {
            if semesterLabel.stringValue == "Spring" {
                selectedSemester = produceSemester(titled: "spring", in: produceYear(Int(yearLabel.stringValue)!))
            } else {
                selectedSemester = produceSemester(titled: "fall", in: produceYear(Int(yearLabel.stringValue)!))
            }
        }
    }
    @IBAction func tempAction_addLec(_ sender: NSButton) {
        let newLec = newLecture()
        addLecture(newLec)
        masterViewController.notifyLectureAddition(lecture: newLec)
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
                }
            } else {
                editingMode()
            }
        }
    }
    var selectedCourse: Course! {
        didSet {
            if selectedCourse != nil {
//                // Create sticky header
//                if stickyHeader != nil {
//                    stickyHeader.removeFromSuperview()
//                    stickyHeader = nil
//                }
//                stickyHeader = HXCourseBox.instance(with: selectedCourse, owner: self)
                // Populate ledgerStackView
                loadLectures(from: selectedCourse)
                // Deselect all other buttons excepts selected one.
                for case let courseButton as HXCourseBox in ledgerStackView.arrangedSubviews {
                    if courseButton.labelTitle.stringValue != selectedCourse.title {
                        courseButton.deselect()
                    } else {
                        scrollToCourse(courseButton)
                    }
                }
            } else {
//                // Remove sticky header
//                stickyHeader.removeFromSuperview()
//                stickyHeader = nil
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
    var deleteConfirmationBox: HXDeleteConfirmationBox!
    var courseToBeRemoved: HXCourseEditBox!
    
    // MARK: Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup observers
        NotificationCenter.default.addObserver(self, selector: #selector(SidebarViewController.didLiveScroll),
                                               name: .NSScrollViewDidLiveScroll, object: ledgerClipView)
//        NotificationCenter.default.addObserver(self, selector: #selector(SidebarViewController.didScroll),
//                                               name: .NSViewBoundsDidChange, object: ledgerClipView)
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
        
        if let courseHappening = selectedSemester.duringCourse() {
            print("Course is happening!")
            selectedCourse = courseHappening
            if selectedCourse != courseHappening {
                selectedCourse = courseHappening
            }
            let newLec = newLecture()
            addLecture(newLec)
            masterViewController.notifyLectureAddition(lecture: newLec)
        }
        
//        print("Let's print the current schedule.")
//        for case let course as Course in selectedSemester.courses! {
//            print("    \(course.title!)")
//            print("        \(printableSchedule(for: course))")
//        }
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        if selectedCourse != nil {
//            notifyHeightUpdate()
        }
    }
    
    // MARK: Course Data Model Functions
    /// Will return a year that either has been newly created, or already exists with the given year number.
    private func produceYear(_ year: Int) -> Year{
        // Try fetching this year in persistent store
        let yearFetch = NSFetchRequest<Year>(entityName: "Year")
        do {
            let years = try appDelegate.managedObjectContext.fetch(yearFetch) as [Year]
            if let foundYear = years.filter({$0.year == Int16(year)}).first {
                // This year already present in store so load
                return foundYear
            } else {
                // Create year since it wasn't found
                let newYear = NSEntityDescription.insertNewObject(forEntityName: "Year", into: appDelegate.managedObjectContext) as! Year
                newYear.year = Int16(year)
                return newYear
            }
        } catch { fatalError("Failed to fetch years: \(error)") }
    }
    /// Will return a semester that either has been newly created, or already exists for the given year and title.
    private func produceSemester(titled: String, in year: Year) -> Semester {
        // Try finding this semester in year selected
        for case let foundSemester as Semester in year.semesters! {
            if foundSemester.title! == titled {
                return foundSemester
            }
        }
        // Create semester since it wasn't found
        let newSemester = NSEntityDescription.insertNewObject(forEntityName: "Semester", into: appDelegate.managedObjectContext) as! Semester
        newSemester.title = titled
        newSemester.year = year
        return newSemester
    }

    // MARK: Lecture Data Model Functions
    /// Returns a newly created Lecture data model object following the previous lecture.
    private func newLecture() -> Lecture {
        let newLecture = NSEntityDescription.insertNewObject(forEntityName: "Lecture", into: appDelegate.managedObjectContext) as! Lecture
        newLecture.course = selectedCourse
        newLecture.number = Int16(lectureCount + 1)
        newLecture.week = Int16(weekCount + 1)
        newLecture.day = Int16(NSCalendar.current.component(.day, from: NSDate() as Date))
        newLecture.weekDay = Int16(NSCalendar.current.component(.weekday, from: NSDate() as Date))
        newLecture.month = Int16(NSCalendar.current.component(.month, from: NSDate() as Date))
        newLecture.year = Int16(NSCalendar.current.component(.year, from: NSDate() as Date))
        return newLecture
    }
    
    // MARK: Populate Course Ledger Functions
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
//        ledgerStackView.addArrangedSubview(newBox!)
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
//            editSemesterButton.title = "Set Course Schedule"
        }
    }
    /// Handles purely the visual aspect of editable courses. Internal use only. Removes the given HXCourseEditBox from the ledgerStackView
    private func popEditableCourse(_ course: HXCourseEditBox) {
        course.removeFromSuperview()
        appDelegate.managedObjectContext.delete( selectedSemester.retrieveCourse(named: course.labelCourse.stringValue))
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
    
    // MARK: Populate Lecture Ledger Functions
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
        notifyHeightUpdate()
    }
    /// Handles purely the visual aspect of lectures. Internal use only. Adds a new HXLectureBox and possibly HXWeekBox to the ledgerStackView.
    private func pushLecture(_ lecture: Lecture) {
//        if lectureCount == 0 {
//            lectureStackView.addArrangedSubview(HXWeekBox.instance(withNumber: (weekCount+1)))
//            weekCount += 1
//        } else {
//            
//        }
        
        if lectureStackView.superview == nil {
            lectureStackView = NSStackView()
            lectureStackView.orientation = NSUserInterfaceLayoutOrientation.vertical
            lectureStackView.spacing = 0
            ledgerStackView.addArrangedSubview(lectureStackView)
        }
        
        if Int(lectureCount % 2) == 0 {
            lectureStackView.addArrangedSubview(HXWeekBox.instance(withNumber: (weekCount+1)))
            weekCount += 1
        }
        let newBox = HXLectureBox.instance(numbered: lecture.number, dated: "\(lecture.month)/\(lecture.day)/\(lecture.year % 100)", owner: self)
        lectureStackView.addArrangedSubview(newBox!)
        newBox?.widthAnchor.constraint(equalTo: ledgerStackView.widthAnchor).isActive = true
        lectureCount += 1
    }
    /// Handles purely the visual aspect of lectures. Internal use only. Removes all HXLectureBox's and HXWeekBox's from the ledgerStackView.
    private func popLectures() {
        if lectureStackView != nil {
            for v in lectureStackView.arrangedSubviews {
                v.removeFromSuperview()
            }
            lectureStackView.removeFromSuperview()
        }
        lectureCount = 0
        weekCount = 0
    }
    
    // MARK: Control Course Ledger Functions
    /// CourseLabel in HXCourseEditBox - on Enter
    /// Finds the course with the given name and renames it if possible
    internal func renameCourse(_ courseBox: HXCourseEditBox) {
        if selectedSemester.retrieveCourse(named: courseBox.labelCourse.stringValue) == nil {
            selectedSemester.retrieveCourse(named: courseBox.oldName).title = courseBox.labelCourse.stringValue
            (self.parent! as! MasterViewController).notifyCourseRename(from: courseBox.oldName)
            courseBox.oldName = courseBox.labelCourse.stringValue
        } else {
            courseBox.revokeNameChange()
        }
    }
    /// For external and internal usage. Creates a new Course data object and updates
    /// ledgerStackView visuals with a new HXCourseBox.
    internal func addCourse() {
        // Creates new course data model and puts new view in ledgerStackView
        pushCourse( selectedSemester.newCourse() )
    }
    /// For external and internal usage. Creates a new Course data object and updates 
    /// ledgerStackView visuals with a new HXCourseEditBox.
    internal func addEditableCourse() {
        // Creates new course data model and puts new view in ledgerStackView
        pushEditableCourse( selectedSemester.newCourse() )
    }
    /// Displays the confirmation delete box before proceeding with course removal.
    internal func removeCourse(_ course: HXCourseEditBox) {
        if deleteConfirmationBox == nil {
            course.buttonTrash.isEnabled = false
            courseToBeRemoved = course
            deleteConfirmationBox = HXDeleteConfirmationBox.instance(with: course.course, for: self)
            masterViewController.notifyCourseDeletionConfirmation(deleteConfirmationBox)
        }
    }
    /// Confirms removal of all information associated with a course object. Model and Views
    internal func removeCourseConfirmed() {
        // Remove course from ledgerStackView, reset grid spaces of timeSlots, delete data model
        popEditableCourse( courseToBeRemoved )
        // Prevent user from accessing lecture view if there are no courses
        if selectedSemester.courses!.count == 0 {
            editSemesterButton.isEnabled = false
            editSemesterButton.state = NSOnState
//            editSemesterButton.title = "Add Course Above"
        } else {
            // Check if the remaining courses have any TimeSlots
            for case let course as Course in selectedSemester.courses! {
                if course.timeSlots!.count == 0 {
                    editSemesterButton.isEnabled = false
                    editSemesterButton.state = NSOnState
//                    editSemesterButton.title = "Set Course Schedule"
                    deleteConfirmationBox.removeFromSuperview()
                    deleteConfirmationBox = nil
                    courseToBeRemoved = nil
                    return
                }
            }
            editSemesterButton.isEnabled = true
            editSemesterButton.state = NSOnState
//            editSemesterButton.title = "Finish Editing Semester"
        }
        deleteConfirmationBox.removeFromSuperview()
        deleteConfirmationBox = nil
        courseToBeRemoved = nil
    }
    /// Cancels removal of a course from the HXDeleteConfirmationBox
    internal func removeCourseCanceled() {

        courseToBeRemoved.buttonTrash.isEnabled = true
        
        deleteConfirmationBox.removeFromSuperview()
        deleteConfirmationBox = nil
        courseToBeRemoved = nil
    }
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
                    scrollToLectureBox(box)
                }
            }
        }
    }
    /// Notify Sidebar from a HXLectureBox that a lecture has been clicked.
    func select(lecture: String) {
        masterViewController.notifyLectureSelection(lecture: lecture)
    }
    /// Visually scrolls the sidebar's ledger so the lecture box is visible
    private func scrollToLectureBox(_ box: HXLectureBox) {
        let lectureY = ledgerStackView.frame.height - (lectureStackView.frame.origin.y + box.frame.origin.y + box.frame.height)
        let clipperY = ledgerClipView.bounds.origin.y
//        if stickyHeader != nil {
//            lectureY -= stickyHeader.frame.height
//        }
        // Scroll only if not visible
        if lectureY > (ledgerScrollView.frame.height + clipperY) || lectureY < clipperY {
            // Animate scroll to lecture
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 1
            ledgerClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: lectureY))
            NSAnimationContext.endGrouping()
        }
    }
    /// Visually scrolls the sidebar's ledger so the course box is at the top
    private func scrollToCourse(_ box: HXCourseBox) {
        let lectureY = ledgerStackView.frame.height - (box.frame.origin.y + box.frame.height) + 2
        // Animate scroll to course
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.5
        ledgerClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: lectureY))
        NSAnimationContext.endGrouping()
    }
    /// Access this function by setting SidebarViewController's selectedSemester.
    /// Repopulates the ledgerStackView and Sidebar visuals to display HXCourseEditBox's.
    private func editingMode() {
        loadEditableCourses(fromSemester: selectedSemester)
//        // Remove sticky header
//        if stickyHeader != nil {
//            stickyHeader.removeFromSuperview()
//            stickyHeader = nil
//        }
        masterViewController.notifySemesterEditing(semester: selectedSemester)
        // UI control flow update - Note the RETURN call
        editSemesterButton.state = NSOnState
        if selectedSemester.courses!.count == 0 {
            editSemesterButton.isEnabled = false
//            editSemesterButton.title = "Add Course Above"
        } else {
            for case let course as Course in selectedSemester.courses! {
                if course.timeSlots!.count == 0 {
                    editSemesterButton.isEnabled = false
//                    editSemesterButton.title = "Set Course Schedule"
                    return
                }
            }
//            editSemesterButton.title = "Finish Editing Semester"
            editSemesterButton.isEnabled = true
        }
    }
    /// Access this function by setting SidebarViewController's selectedSemester.
    /// Repopulates the ledgerStackView and Sidebar visuals to display HXCourseBox's.
    private func viewingMode() {
        editSemesterButton.isEnabled = true
        editSemesterButton.state = NSOffState
//        editSemesterButton.title = "Edit Semester Schedule"
        loadCourses(fromSemester: selectedSemester)
        masterViewController.notifySemesterViewing(semester: selectedSemester)
    }
    
    // MARK: Control Lecture Ledger Functions
    /// For external and internal usage. Creates a new Lecture data object and updates
    /// ledgerStackView visuals with a new HXLectureBox.
    private func addLecture(_ lecture: Lecture) {
        
        pushLecture( lecture )
        
    }
    
    // MARK: Dragging Editable Course Functionality
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
    
    // MARK: Notifiers - from MasterViewController
    /// Notify sidebar that user should be able to finish editing since the
    /// minimum requirement of having at least 1 time established has been met.
    func notifyTimeSlotAdded() {
        // If any course don't have any TimeSlots, don't allow user to proceed to Editor
        for case let course as Course in selectedSemester.courses! {
            if course.timeSlots!.count == 0 {
                return
            }
        }
//        editSemesterButton.title = "Finish Editing Semester"
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
//                editSemesterButton.title = "Set Course Schedule"
                break
            }
        }
    }
    
    // MARK: Sticky Header Functionality
    var stickyHeader: HXCourseBox!
    
    /// Called when bottom buffere space needs to reevaluate its height to allow selected course
    /// to be scrollable to the top.
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
    /// This is called by the users scrolling versus didScroll is called by ledgerClipView bounds change.
    /// Distinguished here since user scrolling should cancel any scroll animations. Else the clipper stutters.
    func didLiveScroll() {
        // Stop any scrolling animations currently happening on the clipper
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0 // This overwrites animator proxy object with 0 duration aimation
        ledgerClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: ledgerClipView.bounds.origin.y))
        NSAnimationContext.endGrouping()
//        // Then call didScroll as normal to produce stickyheader effect
//        didScroll()
    }
    /// Receives scrolling from lectureScroller NSScrollView and any time clipper changes its bounds.
    /// Is responsible for updating the StickyHeaderBox to simulate the iOS effect of lecture titles
    /// staying at the top of scrollView.
    func didScroll() {
        if stickyHeader != nil {
            var box: HXCourseBox!
            for case let courseButton as HXCourseBox in ledgerStackView.arrangedSubviews {
                if courseButton.labelTitle.stringValue == selectedCourse.title {
                    box = courseButton
                    break
                }
            }
            if box == nil {
                return
            }
            let y = ledgerStackView.frame.height - (box.frame.origin.y + box.frame.height) + 2
            if ledgerClipView.bounds.origin.y >= y {
                if stickyHeader.superview == nil {
                    self.view.addSubview(stickyHeader)
                    stickyHeader.leadingAnchor.constraint(equalTo: ledgerScrollView.leadingAnchor).isActive = true
                    stickyHeader.trailingAnchor.constraint(equalTo: ledgerScrollView.trailingAnchor).isActive = true
                    stickyHeader.topAnchor.constraint(equalTo: ledgerScrollView.topAnchor).isActive = true
                    stickyHeader.select()
                }
                
            } else if stickyHeader.superview != nil {
                stickyHeader.removeFromSuperview()
            }
        }
    }
}