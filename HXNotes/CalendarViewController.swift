//
//  CalendarViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/17/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa
import Foundation

class CalendarViewController: NSViewController {
    
    // MARK: Interface Builder outlets and referenced Views ..............
    // Vertical stack views containing grid of times
    @IBOutlet weak var gridMonday: NSStackView!
    @IBOutlet weak var gridTuesday: NSStackView!
    @IBOutlet weak var gridWednesday: NSStackView!
    @IBOutlet weak var gridThursday: NSStackView!
    @IBOutlet weak var gridFriday: NSStackView!
    // Horizontal stack view of day labels on top of calendar
    @IBOutlet weak var dayStack: NSStackView!
    // Vertical stack view of time labels on left of calendar
    @IBOutlet weak var timeStack: NSStackView!
    // Reference to all the NSTextFields in the timeStack
    var timeLabels = [NSTextField]()
    // Reference to all the NSTextFields in the dayStack
    var dayLabels = [NSTextField]()
    // Grid stack is an array of all grid'Day' NSStackViews above
    var gridStack = [NSStackView]()
    // Add course button
    // First array dimension is 'day', second is 'time'
    var gridBoxes = [[HXGridBox]]()
    @IBOutlet weak var noCourseLabel: NSTextField!
    @IBOutlet weak var noCourseSubLabel: NSTextField!
    @IBOutlet weak var calendarContainer: NSBox!
    
    // MARK: References for dragging a course to calendar
    // Course drag box for moving courses
    var courseDragBox: HXCourseDragBox!
    // These constraints control the position of courseDragBox
    var dragBoxConstraintLead: NSLayoutConstraint!
    var dragBoxConstraintTop: NSLayoutConstraint!
    // Reference to index of course being dragged, nil when not dragging
    var dragCourse: HXCourseEditBox!
    // Note last grid box mouse dragged into
    var lastGridX = 0
    var lastGridY = 0
    let EMPTY = ""
    
    // MARK: References to handle extending a course timeSlot
    // Will be either the last time in the timeStack or the first occurance of a difference course
    var maxDragExtendIndex = -1
    // Note how far down dragging occurred to clear out transparent grid spaces
    var lowestDragExtendIndex = -1
    
//    // MARK: Color vars
//    // Colors used to give course boxes unique colors
//    let COLORS_ORDERED = [
//        NSColor.init(red: 88/255, green: 205/255, blue: 189/255, alpha: 1),
//        NSColor.init(red: 114/255, green: 205/255, blue: 88/255, alpha: 1),
//        NSColor.init(red: 89/255, green: 138/255, blue: 205/255, alpha: 1),
//        NSColor.init(red: 204/255, green: 88/255, blue: 127/255, alpha: 1),
//        NSColor.init(red: 205/255, green: 142/255, blue: 88/255, alpha: 1),
//        NSColor.init(red: 161/255, green: 88/255, blue: 205/255, alpha: 1),
//        NSColor.init(red: 254/255, green: 0/255, blue: 0/255, alpha: 1),
//        NSColor.init(red: 54/255, green: 255/255, blue: 0/255, alpha: 1),
//        NSColor.init(red: 0/255, green: 240/255, blue: 255/255, alpha: 1),
//        NSColor.init(red: 254/255, green: 0/255, blue: 210/255, alpha: 1)]
//    // Track which colors have been used,
//    // in case user removes a course box in the middle of stack
//    var colorAvailability = [Int: Bool]()
//    /// Return the first color available, or gray if all colors taken
//    func nextColorAvailable() -> NSColor {
//        for x in 0..<colorAvailability.count {
//            if colorAvailability[x] == true {
//                colorAvailability[x] = false
//                return COLORS_ORDERED[x]
//            }
//        }
//        return NSColor.gray
//    }
//    /// Release a color to be usuable again
//    func releaseColor(color: NSColor) {
//        for i in 0..<COLORS_ORDERED.count {
//            if COLORS_ORDERED[i] == color {
//                colorAvailability[i] = true
//            }
//        }
//    }
    
    // MARK: Object models
    private var thisSemester: Semester! {
        didSet {
            // Clear old course visuals
//            popAllCourses()
            // Populate new lecture visuals
//            loadCourses(fromSemester: thisSemester)
        }
    }
    var masterViewController: MasterViewController!
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Populate gridStack
        gridStack = [self.gridMonday, self.gridTuesday, self.gridWednesday, self.gridThursday, self.gridFriday]
        // Populate timeLabels
        for t in timeStack.subviews {
            if let label = t.subviews.first?.subviews.first as? NSTextField {
                timeLabels.append(label)
            }
        }
        // Populate dayLabels
        for d in dayStack.subviews {
            if let label = d as? NSTextField {
                dayLabels.append(label)
            }
        }
        
        // Create course dragged box
        self.courseDragBox = HXCourseDragBox.instance()
        
        // Generate grid boxes based on number of day and time labels
        for d in 0..<dayStack.subviews.count {
            gridBoxes.append([HXGridBox]())
            for t in 0..<timeStack.subviews.count {
                let newBox = HXGridBox.instance(atX: d, atY: t, trailBorder: d == gridStack.count - 1, botBorder: t == timeStack.subviews.count - 1, withParent: self)
                gridBoxes[d].append(newBox!)
                gridStack[d].addArrangedSubview(newBox!)
                newBox!.widthAnchor.constraint(equalTo: gridStack[d].widthAnchor).isActive = true
            }
        }
    } // end viewDidLoad()
    
    override func viewDidLayout() {
        for columns in gridBoxes {
            for row in columns {
                row.viewDidEndLiveResize()
            }
        }
    }
    
    func initialize(withSemester semester: Semester) {
        self.thisSemester = semester
    }
    
    // MARK: Load object models ______________________________________________________________________________
    /// Populates course stack.
//    private func loadCourses(fromSemester semester: Semester) {
//        // No-course Visuals
//        if thisSemester.courses!.count == 0 {
//            calendarContainer.alphaValue = 0.25
//        } else {
//            noCourseLabel.isHidden = true
//            noCourseSubLabel.isHidden = true
//            noCourseLabel.isEnabled = false
//            noCourseSubLabel.isEnabled = false
//        }
//        // Load courses for this semester:year into courseStack
//        for case let course as Course in semester.courses! {
//            pushCourse( course )
//            loadTimeSlots(fromCourse: course)
//        }
//    }
    /// Populates populates the time slots of a given course.
    private func loadTimeSlots(fromCourse course: Course) {
        for case let time as TimeSlot in course.timeSlots! {
            pushTimeSlot( time , forCourse: correspondingEditBoxToCourse(course))
        }
    }
    
    // MARK: Populating stacks (visuals) ______________________________________________________________________
    /// Handles purely the visual aspect of courses. Adds a new HXCourseEditBox to the courseStack.
//    private func pushCourse(_ course: Course) {
//        let newBox = HXCourseEditBox.instance(withTitle: course.title!, withCourseIndex: courseStack.subviews.count-1, withColor: nextColorAvailable(), withParent: self)
//        courseStack.insertArrangedSubview(newBox!, at: courseStack.subviews.count - 1)
//    }
    /// Handles purely the visual aspect of courses. Removes the HXCourseEditBox to the courseStack
//    private func popCourse(_ course: HXCourseEditBox) {
//        course.removeFromSuperview()
//        releaseColor(color: course.boxDrag.fillColor)
//    }
    /// Handles purely the visual aspect of timeSlots. Updates visuals on an HXGridBox in the gridBoxes array.
    private func pushTimeSlot(_ time: TimeSlot, forCourse course: HXCourseEditBox) {
        gridBoxes[Int(time.day)][Int(time.hour)].update(course: course)
        updateClusters(Int(time.day), Int(time.hour))
    }
    /// Handles purely the visual aspect of timeSlots. Update visuals on an HXGridBox
    private func popTimeSlot(_ x: Int, _ y: Int) {
        gridBoxes[x][y].resetGrid()
        updateClusters(x, y)
    }
    /// Handles purely the visual aspect of courses. Reset the courseStack
//    private func popAllCourses() {
//        for case let v as HXCourseEditBox in courseStack.arrangedSubviews {
//            v.removeFromSuperview()
//        }
//    }
    /// Handles purely the visual aspect of courses. Reset the grixBox visuals
    private func popAllTimeSlots() {
        for x in 0..<gridBoxes.count {
            for y in 0..<gridBoxes[x].count {
                gridBoxes[x][y].resetGrid()
            }
        }
    }
    /// Handles purely the visual aspect of courses. Reset the gridBox visuals for the given course
    private func popTimeSlots(forCourse course: Course) {
        for x in 0..<gridBoxes.count {
            for y in 0..<gridBoxes[x].count {
                if gridSlotTitle(x, y) == course.title {
                    popTimeSlot(x,y)
                }
            }
        }
    }
    
    // MARK: Instance object models ____________________________________________________________________________
    /// Doesn't require parameters. Accesses local thisSemester and determines default name based on other courses present
//    private func newCourse() -> Course {
//        let newCourse = NSEntityDescription.insertNewObject(forEntityName: "Course", into: appDelegate.managedObjectContext) as! Course
//        
//        // Find next available number for naming Course
//        var nextCourseNumber = 1
//        var seekingNumber = true
//        repeat {
//            if (retrieveCourse(withName: "Untitled \(nextCourseNumber)")) == nil {
//                seekingNumber = false
//            } else {
//                nextCourseNumber += 1
//            }
//        } while(seekingNumber)
//        
//        newCourse.title = "Untitled \(nextCourseNumber)"
//        newCourse.semester = thisSemester
//        return newCourse
//    }
    //
    private func newTimeSlot(forCourse course: HXCourseEditBox, atDay day: Int, atHour hour: Int) -> TimeSlot! {
//        if let fetchedCourse = retrieveCourse(withName: course.labelCourse.stringValue) {
//            let newTime = NSEntityDescription.insertNewObject(forEntityName: "TimeSlot", into: appDelegate.managedObjectContext) as! TimeSlot
//            newTime.hour = Int16(hour)
//            newTime.day = Int16(day)
//            newTime.course = fetchedCourse
//            return newTime
//        }
        return nil
    }
    
    // MARK: Populating object model
    /// Add a course model and visual to courseStack
//    private func addCourse() {
//        // No-Course visuals
//        if courseStack.arrangedSubviews.count == 1 {
//            calendarContainer.alphaValue = 1
//            noCourseLabel.isHidden = true
//            noCourseSubLabel.isHidden = true
//            noCourseLabel.isEnabled = false
//            noCourseSubLabel.isEnabled = false
//        }
//        // Creates new course data model and puts new view in courseStack
//        pushCourse( newCourse() )
//    }
    
    /// Removes all information associated with a course object. Model and Views
//    private func removeCourse(_ course: HXCourseEditBox) {
//        // No-Course visuals
//        if courseStack.arrangedSubviews.count == 2 {
//            calendarContainer.alphaValue = 0.25
//            noCourseLabel.isHidden = false
//            noCourseSubLabel.isHidden = false
//            noCourseLabel.isEnabled = true
//            noCourseSubLabel.isEnabled = true
//        }
//        // Remove course from courseStack, reset grid spaces of timeSlots, delete data model
//        popCourse( course )
//        popTimeSlots(forCourse: retrieveCourse(withName: course.labelCourse.stringValue) )
//        appDelegate.managedObjectContext.delete( retrieveCourse(withName: course.labelCourse.stringValue) )
//    }
    /// Add a timeslot model and update gridBox visuals
    private func addTimeSlot(forCourse course: HXCourseEditBox, atDay day: Int, atHour hour: Int) {
        pushTimeSlot( newTimeSlot(forCourse: course, atDay: day, atHour: hour), forCourse: course)
    }
    /// Remove a timeslot model and update gridBox visuals
    private func removeTimeSlot(_ x: Int, _ y: Int) {
        // Update Model
        let fetchRequest = NSFetchRequest<TimeSlot>(entityName: "TimeSlot")
        do {
            let fetch = try appDelegate.managedObjectContext.fetch(fetchRequest) as [TimeSlot]
            if let found = fetch.filter({$0.course!.semester == thisSemester && $0.day == Int16(x) && $0.hour == Int16(y)}).first {
                appDelegate.managedObjectContext.delete(found)
                // Update Visuals
                popTimeSlot(x, y)
            }
        } catch { fatalError("Failed to fetch: \(error)") }
    }
    
    // MARK: Handling time slots..................................................................
    /// Use to update a time slot visuals and data model
    private func updateTimeSlot(xGrid x: Int, yGrid y: Int, course: HXCourseEditBox) {
        // Clear existing course visual and model
        removeTimeSlot(x, y)
        // Update model
        addTimeSlot(forCourse: course, atDay: x, atHour: y)
    }
    /// Use to update a time slot visually to match another grid box and data model
    private func updateTimeSlot(xGrid x: Int, yGrid y: Int, matchGridBox box: HXGridBox) {
        // Clear existing course
        removeTimeSlot(x, y)
        // Update model
        addTimeSlot(forCourse: correspondingEditBoxToCourse(box), atDay: x, atHour: y)
    }
    /// Update cluster visuals around the given grid
    func updateClusters(_ x: Int, _ y: Int) {
        print("Cluster updates after clearTimeSlot.")
        // Above cluster
        if gridSlotTitle(x,y-1) != EMPTY {
            let (topIndexAbove, botIndexAbove) = courseRangeIndices(atGridX: x, atGridY: y-1)
            print("    Above index: \(topIndexAbove) to \(botIndexAbove)")
            for r in stride(from: topIndexAbove, through: botIndexAbove, by: 1) {
                gridBoxes[x][r].updateVisualRange(topIndexAbove, botIndexAbove)
            }
        }
        // Current cluster
        let (topIndex, botIndex) = courseRangeIndices(atGridX: x, atGridY: y)
        for r in stride(from: topIndex, through: botIndex, by: 1) {
            gridBoxes[x][r].updateVisualRange(topIndex, botIndex)
        }
        // Below cluster
        if gridSlotTitle(x,y+1) != EMPTY {
            let (topIndexBelow, botIndexBelow) = courseRangeIndices(atGridX: x, atGridY: y+1)
            print("    Below index: \(topIndexBelow) to \(botIndexBelow)")
            for r in stride(from: topIndexBelow, through: botIndexBelow, by: 1) {
                gridBoxes[x][r].updateVisualRange(topIndexBelow, botIndexBelow)
            }
        }
    }
    /// Returns the HXCourseEditBox that corresponds to the given Course data model
    private func correspondingEditBoxToCourse(_ course: Course) -> HXCourseEditBox! {
//        for case let v as HXCourseEditBox in courseStack.arrangedSubviews {
//            if v.labelCourse.stringValue == course.title {
//                return v
//            }
//        }
        return nil
    }
    /// Returns the HXCourseEditBox that corresponds to the given HXGridBox
    private func correspondingEditBoxToCourse(_ course: HXGridBox) -> HXCourseEditBox! {
//        let title = course.labelTitle.stringValue
//        for case let v as HXCourseEditBox in courseStack.arrangedSubviews {
//            if v.labelCourse.stringValue == title {
//                return v
//            }
//        }
        return nil
    }
    /// Owner of a grid slot can be identified by its label title as this uniquely identifies a course in this year:semester
    private func gridSlotTitle(_ x: Int, _ y: Int) -> String {
        
        if x < 0 || x >= gridBoxes.count || y < 0 || y >= gridBoxes[x].count {
            return EMPTY
        }
        print("The box is \(gridBoxes[x][y]) and the label is \(gridBoxes[x][y].labelTitle!) and the stringValue is '\(gridBoxes[x][y].labelTitle!.stringValue)'")
        return gridBoxes[x][y].labelTitle!.stringValue
    }
    /// Use this to confirm that mouse location when finishing drag is inside expected grid
    func isLocationInLastGrid(location loc: NSPoint) -> Bool {
        if lastGridX != -1 {
            let grid = gridBoxes[lastGridX][lastGridY]
            // Check if the location of the dropped course is within the bounds of this grid space...
            let gridLoc = grid.superview!.convert(grid.frame.origin, to: nil) as NSPoint
            if loc.x > gridLoc.x && loc.x < gridLoc.x + grid.trackingArea.rect.width && loc.y > gridLoc.y && loc.y < gridLoc.y + grid.trackingArea.rect.height {
                return true
            }
        }
        return false
    }
    /// Iterates from lowestDragExtendIndex to dragY to clear the color of the given boxes
    func clearTransparentExtendedGridSpaces(dragX: Int, dragY: Int) {
        if dragY != timeStack.arrangedSubviews.count - 1 {
            for g in stride(from: (dragY + 1), through: lowestDragExtendIndex, by: 1) {
                if gridSlotTitle(dragX, g) == EMPTY {
                    gridBoxes[dragX][g].resetGrid()
                }
            }
            lowestDragExtendIndex = dragY + 1
        }
    }
    
    // MARK: Mouse handlers...........................................................................
    // HXGridBox - Mouse Enter:
    func mouseEntered_gridBox(atX: Int, atY: Int) {
        // Revert color on last grid
        dayLabels[lastGridX].textColor = NSColor.gray
        timeLabels[lastGridY].textColor = NSColor.gray
        // Update grid location
        lastGridY = atY
        if lowestDragExtendIndex != -1 {
            lastGridY = lowestDragExtendIndex
            dayLabels[lastGridX].textColor = NSColor.black
            timeLabels[lastGridY].textColor = NSColor.black
        } else {
            lastGridX = atX
        }
        // If currently dragging, do color update on hovering grid
        if self.dragCourse != nil && lastGridX != -1 {
            timeLabels[lastGridY].textColor = NSColor.black
            dayLabels[lastGridX].textColor = NSColor.black
        }
    }
    /// HXGridBox - Mouse Up: Stop extending the course in a grid box to more time slots
    func mouseUp_gridExtend(dragX: Int, dragY: Int, dragHeight h: CGFloat) {
        let indicesDown = Int(Darwin.floor(h / gridBoxes[dragX][dragY].bounds.height) + 1)
        let lowestIndex = min(dragY + indicesDown, maxDragExtendIndex - 1)
        if lowestIndex > dragY {
            for i in stride(from: (dragY+1), through: lowestIndex, by: 1) {
                self.updateTimeSlot(xGrid: dragX, yGrid: i, matchGridBox: gridBoxes[dragX][dragY])
            }
        }
        maxDragExtendIndex = timeLabels.count
        dayLabels[lastGridX].textColor = NSColor.gray
        timeLabels[lastGridY].textColor = NSColor.gray
        lowestDragExtendIndex = -1
    }
    /// HXGridBox - Mouse Drag: Extend the course in a grid box to more time slots
    func mouseDrag_gridExtend(dragX: Int, dragY: Int, dragHeight h: CGFloat) {
        let indicesDown = Int(Darwin.floor(h / gridBoxes[dragX][dragY].bounds.height) + 1)
        // First time dragging set the index of the course being extended
        if maxDragExtendIndex == -1 {
            maxDragExtendIndex = timeLabels.count
            lowestDragExtendIndex = dragY + 1
        }
        if (dragY + indicesDown) < maxDragExtendIndex {
            if gridSlotTitle(dragX, dragY + indicesDown) == EMPTY {
                // Color all boxes leading up to dragged index
                for y in stride(from: dragY + 1, through: dragY + indicesDown, by: 1) {
                    if gridSlotTitle(dragX, y) == EMPTY {
                        gridBoxes[dragX][y].update(color: NSColor.init(
                            red: gridBoxes[dragX][dragY].fillColor.redComponent,
                            green: gridBoxes[dragX][dragY].fillColor.greenComponent,
                            blue: gridBoxes[dragX][dragY].fillColor.blueComponent,
                            alpha: 0.5))
                    }
                }
            } else if gridSlotTitle(dragX, dragY + indicesDown) != gridSlotTitle(dragX, dragY) {
                maxDragExtendIndex = dragY + indicesDown
            }
            if lowestDragExtendIndex > (dragY + indicesDown) {
                // Clear transparent grids
                for g in stride(from: (dragY + indicesDown + 1), through: lowestDragExtendIndex, by: 1) {
                    if gridSlotTitle(dragX, g) == EMPTY {
                        gridBoxes[dragX][g].resetGrid()
                    }
                }
            }
            lowestDragExtendIndex = dragY + indicesDown
        }
    }
    /// HXCourseEditBox - Mouse Up: Stop dragging a course to a time slot
    func mouseUp_courseBox(atLocation loc: NSPoint) {
        // Ensure a course was being dragged
        if self.dragCourse != nil {
            // Remove drag box from superview
            self.courseDragBox.removeFromSuperview()
            if isLocationInLastGrid(location: loc) {
                self.updateTimeSlot(xGrid: lastGridX, yGrid: lastGridY, course: dragCourse)
                // Reset grid hovering colors
                timeLabels[lastGridY].textColor = NSColor.gray
                dayLabels[lastGridX].textColor = NSColor.gray
            } else if lastGridX != -1 {
                if gridSlotTitle(lastGridX, lastGridY) == EMPTY {
                    timeLabels[lastGridY].textColor = NSColor.gray
                    dayLabels[lastGridX].textColor = NSColor.gray
                }
            }
            self.dragCourse = nil
        }
    }
    /// HXCourseEditBox - Mouse Drag: Drag a course to a time slot
    func mouseDrag_courseBox(course: HXCourseEditBox, toLocation loc: NSPoint) {
        if self.dragCourse == nil {
            self.dragCourse = course
            // Update drag box visuals to match course being dragged
            courseDragBox.updateWithCourse(course)
            // Add drag box back to the superview
            self.view.addSubview(courseDragBox)
            // Try and move these to dragBox initialize in viewDidLoad()
            dragBoxConstraintLead = courseDragBox.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: -1000)
            dragBoxConstraintTop = courseDragBox.topAnchor.constraint(equalTo: self.view.topAnchor, constant: -1000)
            dragBoxConstraintLead.isActive = true
            dragBoxConstraintTop.isActive = true
        } else {
            dragBoxConstraintLead.constant = loc.x - courseDragBox.bounds.width/2
            dragBoxConstraintTop.constant = self.view.bounds.height - loc.y - 5
        }
    }
    
    /// Will identify if same course is directly above or below and return range
    /// in order to create appropriate visuals. Returns tuple: (topIndex,botIndex)
    func courseRangeIndices(atGridX x: Int, atGridY y: Int) -> (Int, Int) {
        let gridIdentifier = gridSlotTitle(x,y)
        if gridIdentifier != EMPTY {
            var topIndex = y
            var botIndex = y
            while gridSlotTitle(x, topIndex - 1) == gridIdentifier {
                topIndex -= 1
            }
            while gridSlotTitle(x, botIndex + 1) == gridIdentifier {
                botIndex += 1
            }
            return (topIndex, botIndex)
        }
        return (y, y)
    }
    // MARK: Action receivers.........................................................................
    /// Button in Course stackView - on MouseDown
//    @IBAction func action_addCourseButton(_ sender: Any) {
//        addCourse()
//    }
    /// CourseLabel in HXCourseEditBox - on Enter
//    internal func action_courseTextField(_ courseBox: HXCourseEditBox) {
//        // Update Model:
//        if let fetchedCourse = retrieveCourse(withName: courseBox.oldName) {
//            fetchedCourse.title = courseBox.labelCourse.stringValue
//            let fetchRequest = NSFetchRequest<TimeSlot>(entityName: "TimeSlot")
//            do {
//                let fetch = try appDelegate.managedObjectContext.fetch(fetchRequest) as [TimeSlot]
//                let found = fetch.filter({$0.course == fetchedCourse})
//                for t in found {
//                    gridBoxes[Int(t.day)][Int(t.hour)].labelTitle.stringValue = courseBox.labelCourse.stringValue
//                }
//            } catch { fatalError("Failed to fetch: \(error)") }
//        }
//        courseBox.oldName = courseBox.labelCourse.stringValue
//    }
    /// Button in HXCourseEditBox - on MouseDown
//    internal func action_removeCourseButton(course: HXCourseEditBox) {
//        self.removeCourse(course)
//    }
    /// Button in HXGridBox - on MouseDown
    internal func action_clearTimeSlot(xGrid x: Int, yGrid y: Int) {
        self.removeTimeSlot(x,y)
    }
    @IBAction func action_closeCalendar(_ sender: Any) {
        masterViewController.popCalendar()
        self.view.removeFromSuperview()
    }
    
//    internal func retrieveCourse(withName: String) -> Course! {
//        for case let course as Course in thisSemester.courses! {
//            if course.title! == withName {
//                return course
//            }
//        }
//        return nil
//    }
}
