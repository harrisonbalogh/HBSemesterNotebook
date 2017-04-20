//
//  CalendarViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/17/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

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
    // Vertical stack view of time labels on left side of window
    @IBOutlet weak var timeStack: NSStackView!
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

    // MARK: Methods __________________________________________________________________________
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize colorAvailability dictionary
        for x in 0..<COLORS_ORDERED.count {
            colorAvailability[x] = true
        }
        // Populate gridStack
        gridStack = [self.gridMonday, self.gridTuesday, self.gridWednesday, self.gridThursday, self.gridFriday]
        
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
                    timeSlots[d].append(TimeSlot(hour: 0, minute: 0, lengthHour: 1, lengthMinute: 0, xDim: d, yDim: t))
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
    }
    
    /// Add a course model and view from template
    func addCourse() {
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
    
    /// Receives mouse down event from an add course template box
    func receiveMouseDownFromAddCourse() {
        addCourse()
    }
    
    func receiveMouseDragFromCourse(course: HXCourseBox, toLocation loc: NSPoint) {
        if self.dragCourseIndex == nil {
            self.dragCourseIndex = course.courseIndex
            // Update drag box visuals to match course being dragged
            courseDragBox.labelCourse.stringValue = course.labelCourse.stringValue
            courseDragBox.fillColor = NSColor(
                red: course.originalColor.redComponent,
                green: course.originalColor.greenComponent,
                blue: course.originalColor.blueComponent,
                alpha: 0.5)
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
    
    func stoppedDraggingCourse(atLocation loc: NSPoint) {
        // Ensure a course was being dragged
        if self.dragCourseIndex != nil {
            // Remove drag box from superview
            self.courseDragBox.removeFromSuperview()
            if isLocationInLastGrid(location: loc) {
                // Update visuals of a grid box
                gridBoxes[lastGridX][lastGridY].update(course: courses[dragCourseIndex])
                // Update model
                courses[dragCourseIndex].assignTime(withTimeSlot: timeSlots[lastGridX][lastGridY])
            }
            self.dragCourseIndex = nil
        }
    }
    
    /// Use this to confirm that mouse location when finishing drag is inside expected grid
    func isLocationInLastGrid(location loc: NSPoint) -> Bool {
        let grid = gridBoxes[lastGridX][lastGridY]
        // Check if the location of the dropped course is within the bounds of this grid space...
        let gridLoc = grid.superview!.convert(grid.frame.origin, to: nil) as NSPoint
        if loc.x > gridLoc.x && loc.x < gridLoc.x + grid.trackingArea.rect.width && loc.y > gridLoc.y && loc.y < gridLoc.y + grid.trackingArea.rect.height {
            return true
        }
        return false
    }
    
    func remove(course: HXCourseBox) {
        for c in courseStack.subviews {
            if let box = c as? HXCourseBox {
                if (box.courseIndex <= course.courseIndex) {
                    continue
                }
                box.updateIndex(index: box.courseIndex - 1)
            }
        }
        for t in courses[course.courseIndex].timeSlotsOccupied {
            gridBoxes[t.xDim][t.yDim].removeCourse()
        }
        courses.remove(at: course.courseIndex)
        releaseColor(color: course.originalColor)
        courseStack.removeView(course)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if let atX = event.trackingArea?.userInfo!["x"] as? Int {
            lastGridX = atX
        }
        if let atY = event.trackingArea?.userInfo!["y"] as? Int {
            lastGridY = atY
        }
        print("Grid location: \(lastGridX), \(lastGridY)")
    }
    
    func updateCourseName(atIndex index: Int, withName name: String) {
        courses[index].title = name
        for t in courses[index].timeSlotsOccupied {
            gridBoxes[t.xDim][t.yDim].labelTitle.stringValue = name
        }
    }
    
}
