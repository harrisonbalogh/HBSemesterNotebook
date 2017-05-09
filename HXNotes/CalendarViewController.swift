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
    // Horizontal stack view of course boxes
    @IBOutlet weak var courseStack: NSStackView!
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
    
    // MARK: References for dragging a course to calendar .................
    // Course drag box for moving courses
    var courseDragBox: HXCourseDragBox!
    // These constraints control the position of courseDragBox
    var dragBoxConstraintLead: NSLayoutConstraint!
    var dragBoxConstraintTop: NSLayoutConstraint!
    // Reference to index of course being dragged, nil when not dragging
    var dragCourse: HXCourseBox!
    // Note last grid box mouse dragged into
    var lastGridX = -1
    var lastGridY = -1
    let EMPTY = ""
    
    // MARK: References to handle extending a course timeSlot
    // Will be either the last time in the timeStack or the first occurance of a difference course
    var maxDragExtendIndex = -1
    // Note how far down dragging occurred to clear out transparent grid spaces
    var lowestDragExtendIndex = -1
    
    // MARK: Color vars .............///...................................
    // Colors used to give course boxes unique colors
    let COLORS_ORDERED = [
        NSColor.init(red: 88/255, green: 205/255, blue: 189/255, alpha: 1),
        NSColor.init(red: 114/255, green: 205/255, blue: 88/255, alpha: 1),
        NSColor.init(red: 89/255, green: 138/255, blue: 205/255, alpha: 1),
        NSColor.init(red: 204/255, green: 88/255, blue: 127/255, alpha: 1),
        NSColor.init(red: 205/255, green: 142/255, blue: 88/255, alpha: 1),
        NSColor.init(red: 161/255, green: 88/255, blue: 205/255, alpha: 1),
        NSColor.init(red: 254/255, green: 0/255, blue: 0/255, alpha: 1),
        NSColor.init(red: 54/255, green: 255/255, blue: 0/255, alpha: 1),
        NSColor.init(red: 0/255, green: 240/255, blue: 255/255, alpha: 1),
        NSColor.init(red: 254/255, green: 0/255, blue: 210/255, alpha: 1)]
    // Track which colors have been used,
    // in case user removes a course box in the middle of stack
    var colorAvailability = [Int: Bool]()
    /// Return the first color available, or gray if all colors taken
    func nextColorAvailable() -> NSColor {
        for x in 0..<colorAvailability.count {
            if colorAvailability[x] == true {
                colorAvailability[x] = false
                return COLORS_ORDERED[x]
            }
        }
        return NSColor.gray
    }
    /// Release a color to be usuable again
    func releaseColor(color: NSColor) {
        for i in 0..<COLORS_ORDERED.count {
            if COLORS_ORDERED[i] == color {
                colorAvailability[i] = true
            }
        }
    }
    
    // MARK: Object models ...................................................
    var thisSemester: Semester!
    var thisYear: Year!
    
    var masterViewController: MasterViewController!
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    // MARK: Methods __________________________________________________________________________
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize colorAvailability dictionary
        for x in 0..<COLORS_ORDERED.count {
            colorAvailability[x] = true
        }
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
        
        // Load course dragged box
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXCourseDragBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXCourseDragBox}).first as? HXCourseDragBox {
            newBox.initialize()
            self.courseDragBox = newBox
        }
        
        // Remove all grid views and generate them from nib template
        for d in 0..<dayStack.subviews.count {
            gridBoxes.append([HXGridBox]())
            gridStack[d].subviews.forEach {$0.removeFromSuperview()}
            for t in 0..<timeStack.subviews.count {
                // Load Grid template from nib
                theObjects = []
                Bundle.main.loadNibNamed("HXGridBox", owner: nil, topLevelObjects: &theObjects)
                // Get NSView from top level objects returned from nib load
                if let newBox = theObjects.filter({$0 is HXGridBox}).first as? HXGridBox {
                    gridBoxes[d].append(newBox)
                    var trailing = false
                    if d == gridStack.count - 1 {
                        trailing = true
                    }
                    var bottoming = false
                    if t == timeStack.subviews.count - 1 {
                        bottoming = true
                    }
                    newBox.initialize(withCalendar: self, atX: d, atY: t, trailBorder: trailing, botBorder: bottoming)
                    gridStack[d].addArrangedSubview(newBox)
                    newBox.widthAnchor.constraint(equalTo: gridStack[d].widthAnchor).isActive = true
                }
            }
        }
    } // end viewDidLoad()
    
    /// Must be called after thisSemester and thisYear are set. Populates course stack
    func loadCourses() {
        // Load courses for this semester:year into courseStack
        let courseFetch = NSFetchRequest<Course>(entityName: "Course")
        do {
            let courses = try appDelegate.managedObjectContext.fetch(courseFetch) as [Course]
            let foundCourses = courses.filter({$0.semester == thisSemester}) as [Course]
            for c in foundCourses {
                // Update Views: Load Course Add Template from nib
                var theObjects: NSArray = []
                Bundle.main.loadNibNamed("HXCourseBox", owner: nil, topLevelObjects: &theObjects)
                // Get NSView from top level objects returned from nib load
                if let newBox = theObjects.filter({$0 is HXCourseBox}).first as? HXCourseBox {
                    newBox.initialize(withCourseIndex: courseStack.subviews.count-1, withColor: nextColorAvailable(), withParent: self)
                    newBox.labelCourse.stringValue = c.title!
                    // Update NSStackView
                    courseStack.insertArrangedSubview(newBox, at: courseStack.subviews.count - 1)
                }
            }
        } catch { fatalError("Failed to fetch times: \(error)") }
    }
    
    // MARK: Handling courses..................................................................
    
    /// Add a course model and view from template
    private func addCourse() {
        // Update Model
        let newCourse = NSEntityDescription.insertNewObject(forEntityName: "Course", into: appDelegate.managedObjectContext) as! Course
        
        // Find next available number for naming Course
        var nextCourseNumber = 1
        var seekingNumber = true
        repeat {
            if (retrieveCourse(withName: "Untitled \(nextCourseNumber)")) == nil {
                seekingNumber = false
            } else {
                nextCourseNumber += 1
            }
        } while(seekingNumber)
        
        newCourse.title = "Untitled \(nextCourseNumber)"
        newCourse.semester = thisSemester
        appDelegate.saveAction(nil)
        
        // Update Views: Load Course Add Template from nib
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXCourseBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXCourseBox}).first as? HXCourseBox {
            newBox.initialize(withCourseIndex: courseStack.subviews.count-1, withColor: nextColorAvailable(), withParent: self)
            newBox.labelCourse.stringValue = newCourse.title!
            // Update NSStackView
            courseStack.insertArrangedSubview(newBox, at: courseStack.subviews.count - 1)
        }
    }
    
    /// Removes all information associated with a course object
    private func removeCourse(_ course: HXCourseBox) {
        
        // Update Model:
        if let fetchedCourse = retrieveCourse(withName: course.labelCourse.stringValue) {
            let timeFetch = NSFetchRequest<TimeSlot>(entityName: "TimeSlot")
            do {
                let times = try appDelegate.managedObjectContext.fetch(timeFetch) as [TimeSlot]
                let courseTimes = times.filter({$0.course == fetchedCourse})
                for t in courseTimes {
                    appDelegate.managedObjectContext.delete(t)
                }
            } catch { fatalError("Failed to fetch times: \(error)") }
            appDelegate.managedObjectContext.delete(fetchedCourse)
            
            // Update Views:
            for x in 0..<gridBoxes.count {
                for y in 0..<gridBoxes[x].count {
                    print ("At \(x),\(y): \(gridSlotKey(x, y))")
                    if gridSlotKey(x, y) == fetchedCourse.title {
                        gridBoxes[x][y].resetGrid()
                    }
                }
            }
            releaseColor(color: course.boxDrag.fillColor)
            course.removeFromSuperview()
        }
    }
    
    // MARK: Handling time slots..................................................................
    
    /// Owner of a grid slot can be identified by its label title as this uniquely identifies a course in this year:semester
    private func gridSlotKey(_ x: Int, _ y: Int) -> String {
        print("The box is \(gridBoxes[x][y]) and the label is \(gridBoxes[x][y].labelTitle!) and the stringValue is '\(gridBoxes[x][y].labelTitle!.stringValue)'")
        return gridBoxes[x][y].labelTitle!.stringValue
    }
    /// Use to update a time slot visuals and data model
    private func updateTimeSlot(xGrid x: Int, yGrid y: Int, course: HXCourseBox) {
        // Clear existing course if needed (visual and data model)
        if gridSlotKey(x,y) != EMPTY {
            clearTimeSlot(xGrid: x, yGrid: y)
        }
        
        // Update Model:
        if let fetchedCourse = retrieveCourse(withName: course.labelCourse.stringValue) {
            let newTime = NSEntityDescription.insertNewObject(forEntityName: "TimeSlot", into: appDelegate.managedObjectContext) as! TimeSlot
            newTime.hour = Int16(y)
            newTime.day = Int16(x)
            newTime.course = fetchedCourse
        }
        
        // Update Views:
        gridBoxes[x][y].update(course: course)
    }
    /// Use to update a time slot visually to match another grid box and data model
    private func updateTimeSlot(xGrid x: Int, yGrid y: Int, matchGridBox box: HXGridBox) {
        // Clear existing course if needed
        if gridSlotKey(x,y) != EMPTY {
            clearTimeSlot(xGrid: x, yGrid: y)
        }
        
        // Update Views:
        gridBoxes[x][y].update(matchBox: box)
        
        // Update model:
        
    }
    
    /// Relinquish time slot data model
    private func clearTimeSlot(xGrid: Int, yGrid: Int) {
        // Update Model
        let fetchRequest = NSFetchRequest<TimeSlot>(entityName: "TimeSlot")
        do {
            let fetch = try appDelegate.managedObjectContext.fetch(fetchRequest) as [TimeSlot]
            print("FETCHING: \(gridSlotKey(xGrid, yGrid))")
            for f in fetch {
                print("    TimeSlot h:\(f.hour) d:\(f.day) courseTitle:\(f.course!.title!) and day == Int16(xGrid): \(f.day == Int16(xGrid))")
            }
            if let found = fetch.filter({$0.course!.title! == gridSlotKey(xGrid, yGrid) && $0.day == Int16(xGrid) && $0.hour == Int16(yGrid)}).first {
                appDelegate.managedObjectContext.delete(found)
                print("Clear time slot")
            }
        } catch { fatalError("Failed to fetch: \(error)") }
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
    
    func clearTransparentExtendedGridSpaces(dragX: Int, dragY: Int) {
        for g in stride(from: (dragY + 1), through: lowestDragExtendIndex, by: 1) {
            if gridSlotKey(dragX, dragY) == EMPTY {
                gridBoxes[dragX][g].update(color: NSColor.white)
            }
        }
        lowestDragExtendIndex = dragY + 1
    }
    
    // MARK: Mouse handlers...........................................................................
    // HXGridBox - Mouse Enter:
    func mouseEntered_gridBox(atX: Int, atY: Int) {
        // If currently dragging, revert color on last grid
        if self.dragCourse != nil && lastGridX != -1 {
            dayLabels[lastGridX].textColor = NSColor.gray
            timeLabels[lastGridY].textColor = NSColor.gray
        }
        lastGridX = atX
        lastGridY = atY
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
        lowestDragExtendIndex = -1
    }
    /// HXGridBox - Mouse Drag: Extend the course in a grid box to more time slots
    func mouseDrag_gridExtend(dragX: Int, dragY: Int, dragHeight h: CGFloat) {
        let indicesDown = Int(Darwin.floor(h / gridBoxes[dragX][dragY].bounds.height) + 1)
        if maxDragExtendIndex == -1 {
            maxDragExtendIndex = timeLabels.count
            lowestDragExtendIndex = dragY + 1
        }
        if (dragY + indicesDown) < maxDragExtendIndex {
            if gridSlotKey(dragX, dragY + indicesDown) == EMPTY {
                gridBoxes[dragX][dragY + indicesDown].update(color: NSColor.init(
                    red: gridBoxes[dragX][dragY].fillColor.redComponent,
                    green: gridBoxes[dragX][dragY].fillColor.greenComponent,
                    blue: gridBoxes[dragX][dragY].fillColor.blueComponent,
                    alpha: 0.5))
            } else if gridSlotKey(dragX, dragY + indicesDown) != gridSlotKey(dragX, dragY) {
                maxDragExtendIndex = dragY + indicesDown
            }
            if lowestDragExtendIndex > (dragY + indicesDown) {
                // Clear transparent grids
                for g in stride(from: (dragY + indicesDown + 1), through: lowestDragExtendIndex, by: 1) {
                    if gridSlotKey(dragX, dragY + indicesDown) == EMPTY {
                        gridBoxes[dragX][g].update(color: NSColor.white)
                    }
                }
            }
            lowestDragExtendIndex = dragY + indicesDown
        }
    }
    /// HXCourseBox - Mouse Up: Stop dragging a course to a time slot
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
                if gridSlotKey(lastGridX, lastGridY) == EMPTY {
                    timeLabels[lastGridY].textColor = NSColor.gray
                    dayLabels[lastGridX].textColor = NSColor.gray
                }
            }
            self.dragCourse = nil
        }
    }
    /// HXCourseBox - Mouse Drag: Drag a course to a time slot
    func mouseDrag_courseBox(course: HXCourseBox, toLocation loc: NSPoint) {
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
    
    // MARK: Action receivers.........................................................................
    /// Button in Course stackView - on MouseDown
    @IBAction func action_addCourseButton(_ sender: Any) {
        addCourse()
    }
    /// CourseLabel in HXCourseBox - on Enter
    internal func action_courseTextField(_ courseBox: HXCourseBox) {
        
        // Update Model:
        if let fetchedCourse = retrieveCourse(withName: courseBox.labelCourse.stringValue) {
            fetchedCourse.title = courseBox.labelCourse.stringValue
        }
        
        //        for t in courses[index].timeSlotsOccupied {
        //            gridBoxes[t.xDim][t.yDim].labelTitle.stringValue = name
        //        }
    }
    /// Button in HXCourseBox - on MouseDown
    internal func action_removeCourseButton(course: HXCourseBox) {
        self.removeCourse(course)
    }
    /// Button in HXGridBox - on MouseDown
    internal func action_clearTimeSlot(xGrid x: Int, yGrid y: Int) {
        self.clearTimeSlot(xGrid: x, yGrid: y)
    }
    @IBAction func action_closeCalendar(_ sender: Any) {
        masterViewController.popCalendar()
        self.view.removeFromSuperview()
    }
    
    internal func retrieveCourse(withName: String) -> Course! {
        let fetchRequest = NSFetchRequest<Course>(entityName: "Course")
        do {
            let times = try appDelegate.managedObjectContext.fetch(fetchRequest) as [Course]
            if let foundCourse = times.filter({$0.title! == withName && $0.semester == thisSemester}).first  {
                return foundCourse
            }
        } catch { fatalError("Failed to fetch times: \(error)") }
        return nil
    }
}
