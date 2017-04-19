//
//  CalendarViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/17/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CalendarViewController: NSViewController {
    
    // Vertical stack views containing grid of times
    @IBOutlet weak var gridMonday: NSStackView!
    @IBOutlet weak var gridTuesday: NSStackView!
    @IBOutlet weak var gridWednesday: NSStackView!
    @IBOutlet weak var gridThursday: NSStackView!
    @IBOutlet weak var gridFriday: NSStackView!
    
    // Grid stack is an array of all NSStackViews above /\
    var gridStack = [NSStackView]()
    // Tracker surrounding entire grid
//    var gridTracker: NSTrackingArea!
    
    // Horizontal stack view of course boxes
    @IBOutlet weak var courseStack: NSStackView!
    
    // CalendarGrid is a subclass of NXBox. 
    // First array dimension is 'day', second is 'time'
    var timeSlots = [[CalendarGrid]]()
    
    // Number of time slots (Precision of time slots)
    let TIME_SLOT_COUNT = 15
    
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
    
    // Course drag box for moving courses
    var courseDragBox: DragBox!
    // Track when mouse starts dragging
    var mouseDraggingBox = false
    // Move these constraints to move the drag box to the mouse
    var dragBoxConstraintLeading: NSLayoutConstraint!
    var dragBoxConstraintTop: NSLayoutConstraint!
    // Note the currently entered grid
    var currentGridX = -1
    var currentGridY = -1
    // Track the course box being dragged
    var draggedCourse: CourseBox!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize colorAvailability dictionary
        for x in 0..<COLORS_ORDERED.count {
            colorAvailability[x] = true
        }
        
        gridStack = [self.gridMonday, self.gridTuesday, self.gridWednesday, self.gridThursday, self.gridFriday]
        
        // Load course dragged box
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("CourseDragged", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let getView = theObjects.filter({$0 is NSView}).first {
            let loadedView = getView as! NSView
            let childDragBox = loadedView.subviews[0] as! DragBox
            childDragBox.initialize()
            self.courseDragBox = childDragBox
        }
        
        // Clear template IB nsbox and add template from Nib
        courseStack.subviews.forEach {$0.removeFromSuperview()}
        addNewCourseToStack()
        
        // Remove all grid views and generate them from nib template
        gridMonday.subviews.forEach {$0.removeFromSuperview()}
        gridTuesday.subviews.forEach {$0.removeFromSuperview()}
        gridWednesday.subviews.forEach {$0.removeFromSuperview()}
        gridThursday.subviews.forEach {$0.removeFromSuperview()}
        gridFriday.subviews.forEach {$0.removeFromSuperview()}
        for d in 0..<gridStack.count {
            timeSlots.append([CalendarGrid]())
            for t in 0..<TIME_SLOT_COUNT {
                // Load Grid template from nib
                theObjects = []
                Bundle.main.loadNibNamed("CalendarGrid", owner: nil, topLevelObjects: &theObjects)
                // Get NSView from top level objects returned from nib load
                if let getView = theObjects.filter({$0 is CalendarGrid}).first {
                    let getBox = getView as! CalendarGrid
                    timeSlots[0].append(getBox)
                    getBox.initializeTrackingArea(with: self, atX: d, atY: t)
                    gridStack[0].addArrangedSubview(getBox)
                }
            }
        }
    }
    
    override func viewDidLayout() {
        for day in timeSlots {
            for slot in day {
                slot.resizeTrackingArea()
            }
        }
    }
    
    /// Add a new course box template to the course stack view
    func addNewCourseToStack() {
        // Load Course Add Template from nib
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("CourseAddTemplate", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let getView = theObjects.filter({$0 is NSView}).first {
            let newCourseView = getView as! NSView
            let newCourseBox = newCourseView.subviews[0] as! CourseAddBox
            newCourseBox.setParentController(controller: self)
            courseStack.addArrangedSubview(newCourseBox)
        }
    }
    
    /// Add a course box template to the course stack view
    func addCourseToStack() {
        // Load Course Add Template from nib
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("CourseTemplate", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let getView = theObjects.filter({$0 is NSView}).first {
            let newCourseView = getView as! NSView
            let newCourseBox = newCourseView.subviews[0] as! CourseBox
            newCourseBox.initialize(withCourseIndex: courseStack.subviews.count, withColor: nextColorAvailable(), withParent: self)
            courseStack.addArrangedSubview(newCourseBox)
        }
    }
    
    /// Receives mouse down event from an add course template box
    func receiveMouseDownFromAddCourse() {
        courseStack.removeView(courseStack.subviews.last!)
        addCourseToStack()
        addNewCourseToStack()
    }
    
//    override func mouseDown(with event: NSEvent) {
//        print("Mouse down event: \(event)")
//    }
    
    func receiveMouseDragFromCourse(course: CourseBox, toLocation loc: NSPoint) {
        if !mouseDraggingBox {
            self.draggedCourse = course
            courseDragBox.fillColor = NSColor(
                red: course.originalColor.redComponent,
                green: course.originalColor.greenComponent,
                blue: course.originalColor.blueComponent,
                alpha: 0.5)
            view.addSubview(courseDragBox)
            dragBoxConstraintLeading = courseDragBox.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: -1000)
            dragBoxConstraintTop = courseDragBox.topAnchor.constraint(equalTo: self.view.topAnchor, constant: -1000)
            dragBoxConstraintLeading.isActive = true
            dragBoxConstraintTop.isActive = true
            mouseDraggingBox = true
            print("String value: \(title)")
            courseDragBox.labelCourse.stringValue = course.labelCourse.stringValue
        } else {
            dragBoxConstraintLeading.constant = loc.x - courseDragBox.bounds.width/2
            dragBoxConstraintTop.constant = self.view.bounds.height - loc.y - 5
        }
    }
    
    func receiveMouseDragStopFromCourse() {
        if mouseDraggingBox {
            courseDragBox.removeFromSuperview()
            mouseDraggingBox = false
            timeSlots[currentGridX][currentGridY].receiveCourse(withColor: draggedCourse.originalColor, withTitle: draggedCourse.labelCourse.stringValue)
            self.draggedCourse = nil
        }
    }
    
    func receiveCourseRemove(course: CourseBox) {
        for c in courseStack.subviews {
            if let box = c as? CourseBox {
                if (box.courseIndex <= course.courseIndex) {
                    continue
                }
                box.updateIndex(index: box.courseIndex - 1)
            }
        }
        releaseColor(color: course.originalColor)
        courseStack.removeView(course)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if let atX = event.trackingArea?.userInfo!["x"] as? Int {
            currentGridX = atX
        }
        if let atY = event.trackingArea?.userInfo!["y"] as? Int {
            currentGridY = atY
        }
        print("currentGrid: \(currentGridX), \(currentGridY)")
        
    }
    
    override func keyDown(with event: NSEvent) {
        print("hey")
    }
    
}
