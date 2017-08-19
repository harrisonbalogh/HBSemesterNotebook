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
            // Deducting 480 (8 hours) removes the hours of 12A-8A from being drawn, and deducting 120 (2 hours)
            // removes the hours of 10P-12A.
            let startMinute = Int(timeSlot.startMinute)
            let stopMinute = Int(timeSlot.stopMinute)
            let y = self.bounds.height - self.bounds.height * CGFloat(startMinute-480)/(1439-480-120)
            let h = self.bounds.height * CGFloat(stopMinute - startMinute)/(1439-480-120)
            
            var textColor = NSColor.black
            var alphaValue: CGFloat = 1
            if !timeSlot.valid {
                textColor = NSColor.red
                alphaValue = 0.5
            }
            
            let bezPath = NSBezierPath(rect: NSRect(x: x, y: y, width: w, height: -h))
            
            NSColor(calibratedRed: CGFloat(timeSlot.course!.color!.red), green: CGFloat(timeSlot.course!.color!.green), blue: CGFloat(timeSlot.course!.color!.blue), alpha: alphaValue).setFill()
            bezPath.fill()
            
            let startString = NSAttributedString(string: HXTimeFormatter.formatTime(Int16(startMinute)), attributes: [NSForegroundColorAttributeName: textColor])
            
            let stopString = NSAttributedString(string: HXTimeFormatter.formatTime(Int16(stopMinute)), attributes: [NSForegroundColorAttributeName: textColor])
            
            let titleString = NSAttributedString(string: timeSlot.course!.title!, attributes: [NSForegroundColorAttributeName: NSColor.darkGray])
            
            // Layout adjustments if the timeSlotVisual height is too small to fit 3 lines of text
            if h < startString.size().height * 2 {
                startString.draw(at: NSPoint(x: x + 1, y: y - h/2 - titleString.size().height/2))
                stopString.draw(at: NSPoint(x: x + w - stopString.size().width, y: y - h/2 - titleString.size().height/2))
            } else if h < startString.size().height * 3 {
                startString.draw(at: NSPoint(x: x + w/2 - startString.size().width/2, y: y - startString.size().height))
                stopString.draw(at: NSPoint(x: x + w/2 - stopString.size().width/2, y: y - h))
            } else {
                startString.draw(at: NSPoint(x: x + w/2 - startString.size().width/2, y: y - startString.size().height))
                stopString.draw(at: NSPoint(x: x + w/2 - stopString.size().width/2, y: y - h))
                titleString.draw(at: NSPoint(x: x + w/2 - titleString.size().width/2, y: y - h/2 - titleString.size().height/2))
            }
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
        timeSlotVisuals.append(timeSlot)
    }
    
    func clearTimeSlotVisuals() {
        timeSlotVisuals = [TimeSlot]()
    }
    
}
