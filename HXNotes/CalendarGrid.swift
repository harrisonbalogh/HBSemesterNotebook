//
//  CalendarGridController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/16/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CalendarGrid: NSBox {
    
    var xDim: Int!
    var yDim: Int!
    var calendar: CalendarViewController!
    
    var trackingArea: NSTrackingArea!
    
    /// Call once on a CalendarGrid after view first appears
    func initializeTrackingArea(with calendar: CalendarViewController, atX: Int, atY: Int) {
        self.calendar = calendar
        self.xDim = atX
        self.yDim = atY
        
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseEnteredAndExited],
            owner: self,//self.calendar,
            userInfo: ["x":xDim, "y":yDim])
        
        addTrackingArea(trackingArea)
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
    
    func receiveCourse(withColor color: NSColor, withTitle title: String) {
        fillColor = color
    }
    
//    override func mouseEntered(with event: NSEvent) {
//        fillColor = NSColor.gray
//    }
//    
//    override func mouseExited(with event: NSEvent) {
//        fillColor = NSColor.white
//    }
    override func viewDidEndLiveResize() {
        // When the user resizes the window, the tracking bounds have to be updated
        resizeTrackingArea()
    }
}
