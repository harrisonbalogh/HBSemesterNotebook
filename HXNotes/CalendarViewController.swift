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
    @IBOutlet weak var courseAddBox: HXCourseAddBox!
    // First array dimension is 'day', second is 'time'
    var gridBoxes = [[HXGridBox]]()
    
    // MARK: References for dragging a course to calendar .................
    // Course drag box for moving courses
    var courseDragBox: HXCourseDragBox!
    // These constraints control the position of courseDragBox
    var dragBoxConstraintLead: NSLayoutConstraint!
    var dragBoxConstraintTop: NSLayoutConstraint!
    // Reference to index of course being dragged, nil when not dragging
    var dragCourseIndex: Int!
    // Note last grid box mouse dragged into
    var lastGridX = -1
    var lastGridY = -1
    
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
    var courses = [Course]()
    var timeSlots = [[TimeSlot]]()
    
    var masterViewController: MasterViewController!

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
        
        // Initialize grid add box button
        courseAddBox.setParentController(controller: self)
        
        // Load course dragged box
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXCourseDragBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXCourseDragBox}).first as? HXCourseDragBox {
            newBox.initialize()
            self.courseDragBox = newBox
        }
        
        // Remove all grid views and generate them from nib template
        for d in 0..<gridStack.count {
            gridBoxes.append([HXGridBox]())
            timeSlots.append([TimeSlot]())
            gridStack[d].subviews.forEach {$0.removeFromSuperview()}
            for t in 0..<timeStack.subviews.count {
                // Load Grid template from nib
                theObjects = []
                Bundle.main.loadNibNamed("HXGridBox", owner: nil, topLevelObjects: &theObjects)
                // Get NSView from top level objects returned from nib load
                if let newBox = theObjects.filter({$0 is HXGridBox}).first as? HXGridBox {
                    gridBoxes[d].append(newBox)
                    // THIS ALL UGLY, FIX IT. MAKE BETTER SYSTEM
                    // AND NOTE THE 8 IN BELOW LINE, SHOULDN'T BE MANUALLY ENTERED, OR DECLARE ABOVE AS CONSTANT
                    timeSlots[d].append(TimeSlot(hour: (t+8), minute: 0, lengthHour: 1, lengthMinute: 0, xDim: d, yDim: t))
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
    
    // MARK: Handling courses..................................................................
    /// Add a course model and view from template
    private func addCourse() {
        // Load Course Add Template from nib
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXCourseBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXCourseBox}).first as? HXCourseBox {
            newBox.initialize(withCourseIndex: courses.count, withColor: nextColorAvailable(), withParent: self)
            // Create object model
            courses.append(Course(withColor: newBox.originalColor))
            // Update NSStackView
            courseStack.insertArrangedSubview(newBox, at: courses.count - 1)
        }
    }
    /// Removes all information associated with a course object
    private func removeCourse(_ course: HXCourseBox) {
        for c in courseStack.subviews {
            if let box = c as? HXCourseBox {
                if (box.courseIndex <= course.courseIndex) {
                    continue
                }
                box.updateIndex(index: box.courseIndex - 1)
            }
        }
        for t in courses[course.courseIndex].timeSlotsOccupied {
            gridBoxes[t.xDim][t.yDim].resetGrid()
        }
        courses[course.courseIndex].remove()
        courses.remove(at: course.courseIndex)
        releaseColor(color: course.originalColor)
        courseStack.removeView(course)
    }
    
    // MARK: Handling time slots..................................................................
    ///
    private func updateTimeSlot(xGrid x: Int, yGrid y: Int, course: Course) {
        // Clear existing course if needed
        if timeSlots[x][y].occupyingCourse != nil {
            resetTimeSlot(xGrid: x, yGrid: y)
        }
        // Update data model and visuals
        let (topTime, botTime) = course.assignTime(withTimeSlot: timeSlots[x][y])
        for g in stride(from: topTime, through: botTime, by: 1) {
            gridBoxes[x][g].update(course: course)
            gridBoxes[x][g].update(topIndex: topTime, botIndex: botTime)
        }
    }
    /// Frees up a time slot from a given course, also visually updates clusters of course times
    private func resetTimeSlot(xGrid: Int, yGrid: Int) {
        
        timeSlots[xGrid][yGrid].clearCourse()

        // Only find above cluster if not earliest time in day
        if yGrid > 0 {
            var (aboveTopTime, aboveBotTime) = (-1,-1)
            let aboveCourseCluster: Course! = timeSlots[xGrid][yGrid-1].occupyingCourse
            if aboveCourseCluster != nil {
                for i in stride(from: (yGrid-1), through: 0, by: -1) {
                    if timeSlots[xGrid][i].occupyingCourse === aboveCourseCluster {
                        if aboveBotTime == -1 {
                            aboveBotTime = i
                        }
                        aboveTopTime = i
                    } else {
                        break
                    }
                }
            }
            if aboveBotTime != -1 {
                for g in stride(from: aboveTopTime, through: aboveBotTime, by: 1) {
                    gridBoxes[xGrid][g].update(course: aboveCourseCluster)
                    gridBoxes[xGrid][g].update(topIndex: aboveTopTime, botIndex: aboveBotTime)
                }
            }
        }
        // Only find below cluster if not latest time in day
        if yGrid < (timeLabels.count - 1) {
            var (belowTopTime, belowBotTime) = (-1,-1)
            let belowCourseCluster: Course! = timeSlots[xGrid][yGrid+1].occupyingCourse
            if belowCourseCluster != nil {
                for i in stride(from: (yGrid+1), through: (timeLabels.count - 1), by: 1) {
                    if timeSlots[xGrid][i].occupyingCourse === belowCourseCluster {
                        if belowTopTime == -1 {
                            belowTopTime = i
                        }
                        belowBotTime = i
                    } else {
                        break
                    }
                }
            }
            if belowTopTime != -1 {
                for g in stride(from: belowTopTime, through: belowBotTime, by: 1) {
                    gridBoxes[xGrid][g].update(course: belowCourseCluster)
                    gridBoxes[xGrid][g].update(topIndex: belowTopTime, botIndex: belowBotTime)
                }
            }
        }
    }
    
//    MAJOR GLITCH:
//        Rewriting other classes by placing one over there other. Changes visual but not data model.
//        Also should re-evaulate clusters on rewrite
//    VISUAL GUARANTEE:
//        Loop through unoccupied timeSlots about the extendDrag position and update their visuals,
//        ... since tracking mouse enter doesn't always happen when moving mouse quickly.
    
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
            if timeSlots[dragX][g].occupyingCourse == nil {
                gridBoxes[dragX][g].update(color: NSColor.white)
            }
        }
        lowestDragExtendIndex = dragY + 1
    }
    
    // MARK: Mouse handlers...........................................................................
    // HXGridBox - Mouse Enter:
    func mouseEntered_gridBox(atX: Int, atY: Int) {
        // If currently dragging, revert color on last grid
        if self.dragCourseIndex != nil && lastGridX != -1 {
            dayLabels[lastGridX].textColor = NSColor.gray
            timeLabels[lastGridY].textColor = NSColor.gray
        }
        lastGridX = atX
        lastGridY = atY
        // If currently dragging, do color update on hovering grid
        if self.dragCourseIndex != nil && lastGridX != -1 {
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
                self.updateTimeSlot(xGrid: dragX, yGrid: i, course: timeSlots[dragX][dragY].occupyingCourse)
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
            if timeSlots[dragX][dragY + indicesDown].occupyingCourse == nil {
                gridBoxes[dragX][dragY + indicesDown].update(color: NSColor.init(
                    red: gridBoxes[dragX][dragY].fillColor.redComponent,
                    green: gridBoxes[dragX][dragY].fillColor.greenComponent,
                    blue: gridBoxes[dragX][dragY].fillColor.blueComponent,
                    alpha: 0.5))
            } else if timeSlots[dragX][dragY + indicesDown].occupyingCourse !== timeSlots[dragX][dragY].occupyingCourse {
                maxDragExtendIndex = dragY + indicesDown
            }
            if lowestDragExtendIndex > (dragY + indicesDown) {
                // Clear transparent grids
                for g in stride(from: (dragY + indicesDown + 1), through: lowestDragExtendIndex, by: 1) {
                    if timeSlots[dragX][g].occupyingCourse == nil {
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
        if self.dragCourseIndex != nil {
            // Remove drag box from superview
            self.courseDragBox.removeFromSuperview()
            if isLocationInLastGrid(location: loc) {
                self.updateTimeSlot(xGrid: lastGridX, yGrid: lastGridY, course: courses[dragCourseIndex])
                // Reset grid hovering colors
                timeLabels[lastGridY].textColor = NSColor.gray
                dayLabels[lastGridX].textColor = NSColor.gray
            } else if lastGridX != -1 {
                if timeSlots[lastGridX][lastGridY].occupyingCourse == nil {
                    timeLabels[lastGridY].textColor = NSColor.gray
                    dayLabels[lastGridX].textColor = NSColor.gray
                }
            }
            self.dragCourseIndex = nil
        }
    }
    /// HXCourseBox - Mouse Drag: Drag a course to a time slot
    func mouseDrag_courseBox(course: HXCourseBox, toLocation loc: NSPoint) {
        if self.dragCourseIndex == nil {
            self.dragCourseIndex = course.courseIndex
            // Update drag box visuals to match course being dragged
            courseDragBox.updateWithCourse(courses[course.courseIndex])
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
    /// Button in HXCourseAddBox - on MouseDown
    internal func action_addCourseButton() {
        addCourse()
    }
    /// CourseLabel in HXCourseBox - on Enter
    internal func action_courseTextField(atIndex index: Int, withName name: String) {
        courses[index].title = name
        for t in courses[index].timeSlotsOccupied {
            gridBoxes[t.xDim][t.yDim].labelTitle.stringValue = name
        }
    }
    /// Button in HXCourseBox - on MouseDown
    internal func action_removeCourseButton(course: HXCourseBox) {
        self.removeCourse(course)
    }
    /// Button in HXGridBox - on MouseDown
    internal func action_clearTimeSlot(xGrid x: Int, yGrid y: Int) {
        self.resetTimeSlot(xGrid: x, yGrid: y)
    }
    @IBAction func action_closeCalendar(_ sender: Any) {
        masterViewController.closeCalendar()
        self.view.removeFromSuperview()
    }
}
