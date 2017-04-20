//
//  CalendarGridController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/16/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXGridBox: NSBox {
    
    var xDim: Int!
    var yDim: Int!
    var calendar: CalendarViewController!
    
    var trackingArea: NSTrackingArea!
    
    
    // Manually connect course box child elements using identifiers
    let ID_LINE_TRAIL      = "grid_line_trailing"
    let ID_LINE_BOTTOM     = "grid_line_bottom"
    let ID_LABEL_TITLE     = "grid_label_title"
    // Elements of course box
    var labelTitle: NSTextField!
    var lineTrailing: NSBox!
    var lineBottom: NSBox!
    
    /// Call once on a CalendarGrid after view first appears
    func initialize(withCalendar calendar: CalendarViewController, atX: Int, atY: Int, trailBorder: Bool, botBorder: Bool) {
        
        self.calendar = calendar
        
        self.xDim = atX
        
        self.yDim = atY
        
        // Initialize child elements
        for v in self.subviews[0].subviews {
            switch v.identifier! {
            case ID_LINE_TRAIL:
                lineTrailing = v as! NSBox
            case ID_LINE_BOTTOM:
                lineBottom = v as! NSBox
            case ID_LABEL_TITLE:
                labelTitle = v as! NSTextField
            default: continue
            }
        }
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseEnteredAndExited],
            owner: self,//self.calendar,
            userInfo: ["x":xDim, "y":yDim])
        
        addTrackingArea(trackingArea)
        
        // Allows grid to have a right and bottom border
        if trailBorder {
            lineTrailing.isHidden = false
        }
        if botBorder {
            lineBottom.isHidden = false
        }
    }
    
    /// Call whenever the superview is resized
    func resizeTrackingArea() {
        if (trackingArea != nil) {
            removeTrackingArea(trackingArea)
            
            trackingArea = NSTrackingArea(
                rect: bounds,
                options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseEnteredAndExited],
                owner: self,//self.calendar,
                userInfo: ["x":xDim, "y":yDim])
            
            addTrackingArea(trackingArea)
        }
    }
    
    /// Will do its own check if the location of the drop was actually inside grid in case the mouseDrag couldn't keep up
    func update(course: Course, dropLocation loc: NSPoint) {
        // Check if the location of the dropped course is within the bounds of this grid space...
        let gridLoc = self.superview!.convert(self.frame.origin, to: nil) as NSPoint
        if
            loc.x > gridLoc.x &&
            loc.x < gridLoc.x + trackingArea.rect.width &&
            loc.y > gridLoc.y &&
            loc.y < gridLoc.y + trackingArea.rect.height {
            
            fillColor = course.color
            
            labelTitle.stringValue = course.title
        }
    }
    
    /// Clears out the course styling
    func removeCourse() {
        labelTitle.stringValue = ""
        fillColor = NSColor.white
    }
    
    override func viewDidEndLiveResize() {
        // When the user resizes the window, the tracking bounds have to be updated
        resizeTrackingArea()
    }
}
