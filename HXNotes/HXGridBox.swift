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
    private var calendar: CalendarViewController!
    
    var trackingArea: NSTrackingArea!
    // When the mouse moves within the extend course region
    private var insideExtender = false
    // When the mouse has started dragging while inside extender
    private var extending = false
    
    // Manually connect course box child elements using identifiers
    private let ID_LINE_TRAIL      = "grid_line_trailing"
    private let ID_LINE_BOTTOM     = "grid_line_bottom"
    private let ID_LABEL_TITLE     = "grid_label_title"
    private let ID_RESIZE          = "grid_resize"
    private let ID_BUTTON_REMOVE   = "grid_button_remove"
    // Elements of course box
    var labelTitle: NSTextField!
    private var lineTrailing: NSBox!
    private var lineBottom: NSBox!
    private var buttonResize: NSImageView!
    private var buttonRemove: NSButton!
    
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
            case ID_RESIZE:
                buttonResize = v as! NSImageView
            case ID_BUTTON_REMOVE:
                buttonRemove = v as! NSButton
            default: continue
            }
        }
        
        // Initialize button functionality
        buttonRemove.target = self
        buttonRemove.action = #selector(self.buttonRemoveAction)
        buttonRemove.alphaValue = 0.5
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseMoved, NSTrackingAreaOptions.enabledDuringMouseDrag, NSTrackingAreaOptions.mouseEnteredAndExited],
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
        
        buttonResize.isHidden = true
        
    } // End initialize()
    
    /// Removes visual of occupying course and notifies controller of press
    func buttonRemoveAction() {
        resetGrid()
        calendar.action_clearTimeSlot(xGrid: xDim, yGrid: yDim)
    }
    
    /// Match grid properties with that of provided course object, some
    /// visuals will not display until update:topIndex:botIndex is called
    func update(course: Course) {
        fillColor = course.color
        labelTitle.stringValue = course.title
        buttonRemove.isHidden = false
        buttonRemove.isEnabled = true
    }
    
    /// Color update of a grid space, primarily for previewing extending grid spaces
    func update(color: NSColor) {
        fillColor = color
    }
    
    /// Uses top/bot index of course cluster to deduce what visuals to show/hide
    func update(topIndex: Int, botIndex: Int) {
        if topIndex == yDim {
            labelTitle.isHidden = false
        } else {
            labelTitle.isHidden = true
        }
        if botIndex == yDim {
            // Reveal resize button
            buttonResize.isHidden = false
        } else {
            // Hide resize button
            buttonResize.isHidden = true
        }
        buttonRemove.isHidden = false
        buttonRemove.isEnabled = true
    }
    
    /// Clears out the course styling
    func resetGrid() {
        labelTitle.stringValue = ""
        fillColor = NSColor.white
        buttonResize.isHidden = true
        buttonRemove.isHidden = true
        buttonRemove.isEnabled = false
    }
    
    override func viewDidEndLiveResize() {
        // When the user resizes the window, the tracking bounds have to be updated
        if trackingArea != nil {
            removeTrackingArea(trackingArea)
            
            trackingArea = NSTrackingArea(
                rect: bounds,
                options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseMoved, NSTrackingAreaOptions.enabledDuringMouseDrag, NSTrackingAreaOptions.mouseEnteredAndExited],
                owner: self,
                userInfo: ["x":xDim, "y":yDim])
            
            addTrackingArea(trackingArea)
        }
    }
    
    // MARK: Tracking Area - Mouse Listeners/Receivers......................................................
    // Usage:
    override func mouseEntered(with event: NSEvent) {
        calendar.mouseEntered_gridBox(atX: xDim, atY: yDim);
    }
    // Usage: extend a the course occuyping current grid downwards
    override func mouseDragged(with event: NSEvent) {
        if insideExtender {
            extending = true
            let loc = event.locationInWindow
            let origin = buttonResize.superview!.convert(buttonResize.frame.origin, to: nil) as NSPoint
            if origin.y > loc.y {
                calendar.mouseDrag_gridExtend(dragX: xDim, dragY: yDim, dragHeight: origin.y - loc.y)
            } else {
                calendar.clearTransparentExtendedGridSpaces(dragX: xDim, dragY: yDim)
            }
        }
    }
    // Usage: display the resizeDown() icon when mouse hovers over button
    override func mouseMoved(with event: NSEvent) {
        if !buttonResize.isHidden {
            let origin = buttonResize.superview!.convert(buttonResize.frame.origin, to: nil) as NSPoint
            let loc = event.locationInWindow
            if loc.x > origin.x && loc.x < origin.x + buttonResize.frame.width && loc.y > origin.y && loc.y < origin.y + buttonResize.frame.height {
                if !insideExtender {
                    insideExtender = true
                    NSCursor.resizeDown().push()
                }
            } else {
                if insideExtender {
                    insideExtender = false
                    NSCursor.resizeDown().pop()
                }
            }
        }
    }
    // Usage: hide the resizeDown() icon if it's still showing when exiting the grid box
    override func mouseExited(with event: NSEvent) {
        if insideExtender && !extending {
            insideExtender = false
            NSCursor.resizeDown().pop()
        }
    }
    // Usage: reset if mouse press is lifted when user was dragging mouse in order to extend a course's grid
    override func mouseUp(with event: NSEvent) {
        if extending {
            extending = false
            let origin = buttonResize.superview!.convert(buttonResize.frame.origin, to: nil) as NSPoint
            let loc = event.locationInWindow
            calendar.mouseUp_gridExtend(dragX: xDim, dragY: yDim, dragHeight: origin.y - loc.y)
        }
        if insideExtender {
            // Check when mouse is released if it was released outside of the extender area
            let origin = buttonResize.superview!.convert(buttonResize.frame.origin, to: nil) as NSPoint
            let loc = event.locationInWindow
            if loc.x < origin.x || loc.x > origin.x + buttonResize.frame.width || loc.y < origin.y || loc.y > origin.y + buttonResize.frame.height {
                NSCursor.resizeDown().pop()
                insideExtender = false
            }
        }
    }
}
