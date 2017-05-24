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
    // Note last grid box mouse dragged into
    var lastGridX = 0
    var lastGridY = 0
    let EMPTY = ""
    
    // MARK: References to handle extending a course timeSlot
    // Will be either the last time in the timeStack or the first occurance of a difference course
    var maxDragExtendIndex = -1
    // Note how far down dragging occurred to clear out transparent grid spaces
    var lowestDragExtendIndex = -1
    var extendingCourse: Course!
    
    // MARK: Object models
    private var thisSemester: Semester! {
        didSet {
            // Clear old course visuals
            popAllTimeSlots()
            // Populate new lecture visuals
//            loadCourses(fromSemester: thisSemester)
            for case let course as Course in thisSemester.courses! {
                loadTimeSlots(for: course)
            }
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
    }
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
    /// Populates populates the time slots of a given course.
    private func loadTimeSlots(for course: Course) {
        for case let time as TimeSlot in course.timeSlots! {
            pushTimeSlot( time , for: course)
        }
    }
    
    // MARK: Populating stacks (visuals) ______________________________________________________________________
    /// Handles purely the visual aspect of timeSlots. Updates visuals on an HXGridBox in the gridBoxes array.
    private func pushTimeSlot(_ time: TimeSlot, for course: Course) {
        gridBoxes[Int(time.day)][Int(time.hour)].update(course: course)
        updateClusters(Int(time.day), Int(time.hour))
        evaluateEmptyVisuals()
    }
    /// Handles purely the visual aspect of timeSlots. Update visuals on an HXGridBox
    private func popTimeSlot(_ x: Int, _ y: Int) {
        gridBoxes[x][y].resetGrid()
        updateClusters(x, y)
        evaluateEmptyVisuals()
    }
    /// Handles purely the visual aspect of courses. Reset the grixBox visuals
    private func popAllTimeSlots() {
        for x in 0..<gridBoxes.count {
            for y in 0..<gridBoxes[x].count {
                gridBoxes[x][y].resetGrid()
            }
        }
        evaluateEmptyVisuals()
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
    /// Check if calendar needs to apply visuals based on no courses present
    func evaluateEmptyVisuals() {
        // See if there are any occupied times
        for x in 0..<gridBoxes.count {
            for y in 0..<gridBoxes[x].count {
                if gridSlotTitle(x, y) != EMPTY {
                    calendarContainer.alphaValue = 1
                    noCourseLabel.isHidden = true
                    noCourseSubLabel.isHidden = true
                    noCourseLabel.isEnabled = false
                    noCourseSubLabel.isEnabled = false
                    return
                }
            }
        }
        calendarContainer.alphaValue = 0.25
        noCourseLabel.isHidden = false
        noCourseSubLabel.isHidden = false
        noCourseLabel.isEnabled = true
        noCourseSubLabel.isEnabled = true
        if thisSemester.courses!.count == 0 {
            noCourseLabel.stringValue = "No Course Data"
            noCourseSubLabel.stringValue = "Add a course above."
        } else {
            for case let course as Course in thisSemester.courses! {
                print("    \(course.title!)")
            }
            noCourseLabel.stringValue = "Drag to Here"
            noCourseSubLabel.stringValue = "Mouse over course color."
        }
    }
    
    // MARK: Instance object models ____________________________________________________________________________

    //
    private func newTimeSlot(for course: Course, atDay day: Int, atHour hour: Int) -> TimeSlot {
        let newTime = NSEntityDescription.insertNewObject(forEntityName: "TimeSlot", into: appDelegate.managedObjectContext) as! TimeSlot
        newTime.hour = Int16(hour) // Supplied range is [0,14] but we want it to be actual hour so [8,22]
        newTime.day = Int16(day) // Supplied range is [0,4] but we want it to match Calendar.Component.weekday so [2,6]
        newTime.course = course
        return newTime
    }
    
    // MARK: Populating object model
    /// Remove all timeslots associated with given course
    func clearTimeSlots(named name: String) {
        for x in 0..<gridBoxes.count {
            for y in 0..<gridBoxes[x].count {
                if gridSlotTitle(x, y) == name {
                    popTimeSlot(x,y)
                }
            }
        }
        evaluateEmptyVisuals()
    }
    /// Add a timeslot model and update gridBox visuals
    private func addTimeSlot(for course: Course, atDay day: Int, atHour hour: Int) {
        pushTimeSlot( newTimeSlot(for: course, atDay: day, atHour: hour), for: course)
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
    /// Providing the old name of timeslots that require reloading their matching course name.
    func reloadTimeslotTitles(named name: String) {
        
        for x in 0..<gridBoxes.count {
            for y in 0..<gridBoxes[x].count {
                if gridSlotTitle(x, y) == name {
                    gridBoxes[x][y].labelTitle.stringValue = gridBoxes[x][y].course!.title!
                }
            }
        }
        
    }
    /// Use to update a time slot visuals and data model
    private func updateTimeSlot(xGrid x: Int, yGrid y: Int, course: Course) {
        // Clear existing course visual and model
        removeTimeSlot(x, y)
        // Update model
        addTimeSlot(for: course, atDay: x, atHour: y)
    }
    /// Use to update a time slot visually to match another grid box and data model
    private func updateTimeSlot(xGrid x: Int, yGrid y: Int, matchGridBox box: HXGridBox) {
        // Clear existing course
        removeTimeSlot(x, y)
        // Update model
        addTimeSlot(for: box.course, atDay: x, atHour: y)
    }
    /// Update cluster visuals around the given grid
    func updateClusters(_ x: Int, _ y: Int) {
        // Above cluster
        if gridSlotTitle(x,y-1) != EMPTY {
            let (topIndexAbove, botIndexAbove) = courseRangeIndices(atGridX: x, atGridY: y-1)
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
            for r in stride(from: topIndexBelow, through: botIndexBelow, by: 1) {
                gridBoxes[x][r].updateVisualRange(topIndexBelow, botIndexBelow)
            }
        }
    }
    /// Owner of a grid slot can be identified by its label title as this uniquely identifies a course in this year:semester
    private func gridSlotTitle(_ x: Int, _ y: Int) -> String {
        if x < 0 || x >= gridBoxes.count || y < 0 || y >= gridBoxes[x].count {
            return EMPTY
        }
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
        extendingCourse = nil
    }
    /// HXGridBox - Mouse Drag: Extend the course in a grid box to more time slots
    func mouseDrag_gridExtend(_ x: Int, _ y: Int, dragHeight h: CGFloat) {
        let indicesDown = Int(Darwin.floor(h / gridBoxes[x][y].bounds.height) + 1)
        // First time dragging set the index of the course being extended
        if extendingCourse == nil {
            maxDragExtendIndex = timeLabels.count
            lowestDragExtendIndex = y + 1
            extendingCourse = gridBoxes[x][y].course
        }
        if (y + indicesDown) < maxDragExtendIndex {
            if gridSlotTitle(x, y + indicesDown) == EMPTY {
                // Color all boxes leading up to dragged index
                for h in stride(from: y + 1, through: y + indicesDown, by: 1) {
                    if gridSlotTitle(x, h) == EMPTY {
                        gridBoxes[x][h].update(color: NSColor.init(
                            red: gridBoxes[x][y].fillColor.redComponent,
                            green: gridBoxes[x][y].fillColor.greenComponent,
                            blue: gridBoxes[x][y].fillColor.blueComponent,
                            alpha: 0.5))
                    }
                }
            } else if gridSlotTitle(x, y + indicesDown) != gridSlotTitle(x, y) {
                maxDragExtendIndex = y + indicesDown
            }
            if lowestDragExtendIndex > (y + indicesDown) {
                // Clear transparent grids
                for g in stride(from: (y + indicesDown + 1), through: lowestDragExtendIndex, by: 1) {
                    if gridSlotTitle(x, g) == EMPTY {
                        gridBoxes[x][g].resetGrid()
                    }
                }
            }
            lowestDragExtendIndex = y + indicesDown
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
    /// Button in HXGridBox - on MouseDown
    internal func action_clearTimeSlot(xGrid x: Int, yGrid y: Int) {
        self.removeTimeSlot(x,y)
    }
    @IBAction func action_closeCalendar(_ sender: Any) {
        masterViewController.popCalendar()
        self.view.removeFromSuperview()
    }

    /// Lets the calendar know that there was a drag update from a course
    func drag() {
        // Color update on hovering grid
        if lastGridX != -1 {
            timeLabels[lastGridY].textColor = NSColor.black
            dayLabels[lastGridX].textColor = NSColor.black
            
        }
    }
    /// Lets the calendar know that the course has been dropped on a grid space
    func drop(course: Course, at loc: NSPoint) {
        if isLocationInLastGrid(location: loc) {
            self.updateTimeSlot(xGrid: lastGridX, yGrid: lastGridY, course: course)
            // Reset grid hovering colors
            timeLabels[lastGridY].textColor = NSColor.gray
            dayLabels[lastGridX].textColor = NSColor.gray
        } else if lastGridX != -1 {
            if gridSlotTitle(lastGridX, lastGridY) == EMPTY {
                timeLabels[lastGridY].textColor = NSColor.gray
                dayLabels[lastGridX].textColor = NSColor.gray
            }
        }
    }
}
