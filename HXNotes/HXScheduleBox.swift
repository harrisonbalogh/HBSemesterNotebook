//
//  HXScheduleBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 7/8/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXScheduleBox: NSBox {
    
    private var timeSlotVisuals = [TimeSlot]()
    
    private var trackingArea: NSTrackingArea!

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        for timeSlot in timeSlotVisuals {
            let w = self.bounds.width/7
            let x = CGFloat(timeSlot.weekday - 1) * w
            let y = self.bounds.height - self.bounds.height * CGFloat(timeSlot.startMinuteOfDay)/1439
            let h = self.bounds.height * CGFloat(timeSlot.stopMinuteOfDay - timeSlot.startMinuteOfDay)/1439
            
            let bezPath = NSBezierPath(rect: NSRect(x: x, y: y, width: w, height: -h))
            
            NSColor(calibratedRed: CGFloat(timeSlot.course!.colorRed), green: CGFloat(timeSlot.course!.colorGreen), blue: CGFloat(timeSlot.course!.colorBlue), alpha: 1).setFill()
            bezPath.fill()
        }
    }
    
    func initialize() {
//        trackingArea = NSTrackingArea(
//            rect: bounds,
//            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseMoved, NSTrackingAreaOptions.enabledDuringMouseDrag, NSTrackingAreaOptions.mouseEnteredAndExited],
//            owner: self,
//            userInfo: nil)
//        
//        addTrackingArea(trackingArea)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
//        removeTrackingArea(trackingArea)
//        
//        trackingArea = NSTrackingArea(
//            rect: bounds,
//            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseMoved, NSTrackingAreaOptions.enabledDuringMouseDrag, NSTrackingAreaOptions.mouseEnteredAndExited],
//            owner: self,
//            userInfo: nil)
//        Swift.print("Bounds: \(bounds)")
//        
//        addTrackingArea(trackingArea)
    }
    
    override func mouseMoved(with event: NSEvent) {
//        Swift.print("Mouse moved: \(event)")
    }
    
    // MARK: - Drawing Schedule Boxes

    func addTimeSlotVisual(_ timeSlot: TimeSlot) {
        Swift.print("Adding timeslot for \(timeSlot.course!.title!) at start minute of day: \(timeSlot.startMinuteOfDay)")
        timeSlotVisuals.append(timeSlot)
    }
    
    func clearTimeSlotVisuals() {
        timeSlotVisuals = [TimeSlot]()
    }
    
}
