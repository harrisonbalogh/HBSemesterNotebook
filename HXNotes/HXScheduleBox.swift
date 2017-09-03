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
    
    
    // Schedule Time Bounds
    private let DEFAULT_EARLIEST = 480 // 8:00
    private let DEFAULT_LATEST = 1319 // 9:59
    private var earliestTime = 480
    private var latestTime = 1319
    // This are only shown if a class is present on these days
    private var showSaturday = false
    private var showSunday = false
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        for timeSlot in timeSlotVisuals {
            
            var days: CGFloat = 5
            if showSaturday { days += 1 }
            if showSunday { days += 1 }
            
            var day = timeSlot.weekday
            if !showSunday { day -= 1 }
            let w = self.bounds.width/days
            let x = CGFloat(day - 1) * w
            // Deducting 480 (8 hours) removes the hours of 12A-8A from being drawn, and deducting 120 (2 hours)
            // removes the hours of 10P-12A.
            let start = Int(timeSlot.startMinute)
            let stop = Int(timeSlot.stopMinute)
            
            let minutesShown = CGFloat(latestTime - earliestTime + 1)
            
            let y = self.bounds.height - self.bounds.height * CGFloat(start - earliestTime)/(minutesShown)
            let h = self.bounds.height * CGFloat(stop - start)/(minutesShown)
            
            var textColor = NSColor.black
            var alphaValue: CGFloat = 1
            if !timeSlot.valid {
                textColor = NSColor.red
                alphaValue = 0.5
            }
            
            let bezPath = NSBezierPath(rect: NSRect(x: x, y: y, width: w, height: -h))
            
            NSColor(calibratedRed: CGFloat(timeSlot.course!.color!.red), green: CGFloat(timeSlot.course!.color!.green), blue: CGFloat(timeSlot.course!.color!.blue), alpha: alphaValue).setFill()
            bezPath.fill()
            
            let startString = NSAttributedString(string: HXTimeFormatter.formatTime(Int16(start)), attributes: [NSForegroundColorAttributeName: textColor])
            
            let stopString = NSAttributedString(string: HXTimeFormatter.formatTime(Int16(stop)), attributes: [NSForegroundColorAttributeName: textColor])
            
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
        
        let start = Int(timeSlot.startMinute)
        let stop = Int(timeSlot.stopMinute)
        
        // Extend the scheduler outside its normal bounds if required
        if start < earliestTime {
            earliestTime = Int(start / 60) * 60
        }
        if stop > latestTime {
            latestTime = Int(stop / 60 + 1) * 60 - 1
        }
        if timeSlot.weekday == 1 {
            showSunday = true
        }
        if timeSlot.weekday == 7 {
            showSaturday = true
        }
        
        timeSlotVisuals.append(timeSlot)
    }
    
    func clearTimeSlotVisuals() {
        
        // Reset scheduler bounds extension from unusual schedules
        earliestTime = DEFAULT_EARLIEST
        latestTime = DEFAULT_LATEST
        showSaturday = false
        showSunday = false
        
        timeSlotVisuals = [TimeSlot]()
    }
    
}
