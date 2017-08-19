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
            if semesterButton.title == "Spring" {
                selectedSemester = Semester.produceSemester(titled: "spring", in: Int(yearLabel.stringValue)!)
            } else {
                selectedSemester = Semester.produceSemester(titled: "fall", in: Int(yearLabel.stringValue)!)
            }
        }
    }
    func setDate(semester: Semester) {
        lastYearUsed = Int(semester.year)
        yearLabel.stringValue = "\(lastYearUsed)"
        selectedSemester = semester
        semesterButton.title = selectedSemester.title!.capitalized
    }
    @IBOutlet weak var semesterButton: NSButton!
    @IBOutlet weak var semButtonBotConstraint: NSLayoutConstraint!
    @IBOutlet weak var semesterButtonAnimated: NSButton!
    @IBOutlet weak var semButtonAnimBotConstraint: NSLayoutConstraint!
    @IBOutlet weak var yearLabel: NSTextField!
    @IBOutlet weak var yearLabelAnimated: NSTextField!
    @IBOutlet weak var yrButtonBotConstraint: NSLayoutConstraint!
    @IBOutlet weak var yrButtonAnimBotConstraint: NSLayoutConstraint!
    
    var lastYearUsed = 0
    @IBAction func action_incrementTime(_ sender: NSButton) {
        sender.isEnabled = false
        
        semButtonAnimBotConstraint.constant = -30
        if self.semesterButton.title == "Spring" {
            self.semesterButtonAnimated.title = "Fall"
        } else {
            self.semesterButtonAnimated.title = "Spring"
            self.yearLabelAnimated.stringValue = "\(Int(self.yearLabel.stringValue)! + 1)"
            yrButtonAnimBotConstraint.constant = -30
        }
        let recoloredText = NSMutableAttributedString(attributedString: self.semesterButtonAnimated.attributedTitle)
        recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,self.semesterButtonAnimated.attributedTitle.length))
        self.semesterButtonAnimated.attributedTitle = recoloredText
        
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.2
        NSAnimationContext.current().completionHandler = {
            if self.semesterButton.title == "Spring" {
                self.semesterButton.title = "Fall"
            } else {
                self.semesterButton.title = "Spring"
                self.yearLabel.stringValue = "\(Int(self.yearLabel.stringValue)! + 1)"
                self.yrButtonBotConstraint.constant = 0
            }
            let recoloredText = NSMutableAttributedString(attributedString: self.semesterButton.attributedTitle)
            recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,self.semesterButton.attributedTitle.length))
            self.semesterButton.attributedTitle = recoloredText
            self.semButtonBotConstraint.constant = 0
            self.tempAction_date()
            sender.isEnabled = true
        }
        self.semButtonBotConstraint.animator().constant = -semesterButton.frame.height
        if self.semesterButton.title == "Fall" {
            self.yrButtonBotConstraint.animator().constant = semesterButton.frame.height
        }
        NSAnimationContext.endGrouping()
    }
    @IBAction func action_decrementTime(_ sender: NSButton) {
        sender.isEnabled = false
        
        semButtonAnimBotConstraint.constant = 30
        yrButtonAnimBotConstraint.constant = 30
        if self.semesterButton.title == "Fall" {
            self.semesterButtonAnimated.title = "Spring"
        } else {
            self.semesterButtonAnimated.title = "Fall"
            self.yearLabelAnimated.stringValue = "\(Int(self.yearLabel.stringValue)! - 1)"
        }
        let recoloredText = NSMutableAttributedString(attributedString: self.semesterButtonAnimated.attributedTitle)
        recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,self.semesterButtonAnimated.attributedTitle.length))
        self.semesterButtonAnimated.attributedTitle = recoloredText

        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.2
        NSAnimationContext.current().completionHandler = {
            if self.semesterButton.title == "Fall" {
                self.semesterButton.title = "Spring"
                
            } else {
                self.semesterButton.title = "Fall"
                self.yearLabel.stringValue = "\(Int(self.yearLabel.stringValue)! - 1)"
                self.yrButtonBotConstraint.constant = 0
            }
            let recoloredText = NSMutableAttributedString(attributedString: self.semesterButton.attributedTitle)
            recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,self.semesterButton.attributedTitle.length))
            self.semesterButton.attributedTitle = recoloredText
            self.semButtonBotConstraint.constant = 0
            self.tempAction_date()
            sender.isEnabled = true
        }
        self.semButtonBotConstraint.animator().constant = semesterButton.frame.height
        if self.semesterButton.title == "Spring" {
            self.yrButtonBotConstraint.animator().constant = -semesterButton.frame.height
        }
        NSAnimationContext.endGrouping()
    }
    
    @IBAction func action_semesterButton(_ sender: NSButton) {
        if semesterButton.title == "Fall" {
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
    var selectedSemester: Semester! {
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
                        courseButton.select()
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
        
        let recoloredText = NSMutableAttributedString(attributedString: semesterButton.attributedTitle)
        recoloredText.addAttribute(NSForegroundColorAttributeName, value: NSColor.white, range: NSMakeRange(0,semesterButton.attributedTitle.length))
        semesterButton.attributedTitle = recoloredText
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        var course = ""
        if selectedCourse == nil {
            course = "nil"
        } else {
            course = selectedCourse.title!
        }
        
        let key = semesterButton.title.uppercased() + ":" + yearLabel.stringValue + ":" + course
        
        CFPreferencesSetAppValue(NSString(string: "previouslyOpenedCourse"),NSString(string: key), kCFPreferencesCurrentApplication)
        
        CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
    }

    // MARK: ––– Populating LedgerStackView –––
    
    /// Access this function by setting SidebarViewController's selectedSemester.
    /// Repopulates the ledgerStackView and Sidebar visuals to display HXCourseEditBox's.
    private func editingMode() {
        selectedCourse = nil
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
            print("GTTBOT: loadLectures() - pushLecture")
            pushLecture( lecture )
        }
    }
    /// Handles purely the visual aspect of lectures. Internal use only. Adds a new HXLectureBox and possibly HXWeekBox to the ledgerStackView.
    private func pushLecture(_ lecture: Lecture) {
        print("GTTBOT: pushLecture")
        // Insert the lecture stack view if it isn't already created.
        if lectureStackView.superview == nil {
            lectureStackView = NSStackView()
            lectureStackView.orientation = NSUserInterfaceLayoutOrientation.vertical
            lectureStackView.spacing = 0
            ledgerStackView.addArrangedSubview(lectureStackView)
        }
        // Insert weekbox on first lecture, then insert every time week changes from previous lecture.
        if selectedCourse.lectures!.count == 1 {
            lectureStackView.addArrangedSubview(HXWeekBox.instance(withNumber: (weekCount+1)))
            weekCount += 1
        } else {
            // Following week deducation requires sorted time slots
            if lecture.course!.needsSort {
                lecture.course!.sortTimeSlots()
            }
            // If the lecture requested to be pushed is the first time slot in the week, it must be a new week
            if lecture.course!.timeSlots?.index(of: lecture.timeSlot!) == 0 {
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
            let year = lecture.course!.semester!.year
            let newBox = HXLectureBox.instance(numbered: lecture.number, dated: "\(lecture.month)/\(lecture.day)/\(year % 100)", owner: self)
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
        
        if bottomBufferHeightConstraint != nil {
            bottomBufferHeightConstraint.constant = 0
        }
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
            if let timeSlotHappening = currentSemester.duringCourse() {
                if timeSlotHappening.course!.theoreticalLectureCount() != timeSlotHappening.course!.lectures!.count || timeSlotHappening.course!.theoreticalLectureCount() == 0 {
                    if selectedSemester != currentSemester {
                        selectedSemester = currentSemester
                    }
                    if selectedCourse != timeSlotHappening.course! {
                        selectedCourse = timeSlotHappening.course!
                    }
                    // Displays lecture in the ledgerStackView
                    print("GTTBOT: addLecture() before pushLecture")
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
        
        selectedSemester.validateSchedule()
        
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
        
        selectedSemester.validateSchedule()
        
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
}
