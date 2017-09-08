//
//  HXScheduleBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 7/8/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXScheduleBox: NSBox {
    
    var masterVC: MasterViewController!
    
    private var timeSlotVisuals = [TimeSlot]()
    /// This is for greying class times that are not in the selected course
    private var selectedArray = [Bool]()
    private var highlightedArray = [Bool]()
    
    var isHighlighting = false {
        didSet {
            updateTrackingAreas()
        }
    }
    
    // Schedule Time Bounds
    let DEFAULT_EARLIEST = 480 // 8:00
    let DEFAULT_LATEST = 1319 // 9:59
    var earliestTime = 480
    var latestTime = 1319
    private var minutesShown: CGFloat {
        get {
            return CGFloat(latestTime - earliestTime + 1)
        }
    }
    // This are only shown if a class is present on these days
    var showSaturday = false
    var showSunday = false
    private var days: CGFloat {
        get {
            return CGFloat(5 + showSaturday.hashValue + showSunday.hashValue)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
        var ind = 0
        for timeSlot in timeSlotVisuals {
            
            let start = Int(timeSlot.startMinute)
            let stop = Int(timeSlot.stopMinute)
            let day = timeSlot.weekday - (!showSunday).hashValue
            
            let w = self.bounds.width/days
            let x = CGFloat(day - 1) * w
            // Deducting 480 (8 hours) removes the hours of 12A-8A from being drawn, and deducting 120 (2 hours)
            // removes the hours of 10P-12A.
            
            let y = self.bounds.height - self.bounds.height * CGFloat(start - earliestTime)/(minutesShown)
            let h = self.bounds.height * CGFloat(stop - start)/(minutesShown)
            
            var textColor = NSColor.black
            var alphaValue: CGFloat = 1
            if !timeSlot.valid {
                textColor = NSColor.red
                alphaValue = 0.5
            }
            
            let bezPath = NSBezierPath(rect: NSRect(x: x, y: y, width: w, height: -h))
            
            if selectedArray[ind] {
                NSColor(calibratedRed: CGFloat(timeSlot.course!.color!.red), green: CGFloat(timeSlot.course!.color!.green), blue: CGFloat(timeSlot.course!.color!.blue), alpha: alphaValue).setFill()
            } else {
                NSColor(calibratedWhite: 0.85, alpha: 1).setFill()
            }
            bezPath.fill()
            
            var highlightAttribs = [NSForegroundColorAttributeName: NSColor.darkGray]
            if highlightedArray[ind] {
                NSColor.black.setStroke()
                bezPath.stroke()
                highlightAttribs = [NSForegroundColorAttributeName: NSColor.black]
            }
            
            let startString = NSAttributedString(string: HXTimeFormatter.formatTime(Int16(start)), attributes: [NSForegroundColorAttributeName: textColor])
            
            let stopString = NSAttributedString(string: HXTimeFormatter.formatTime(Int16(stop)), attributes: [NSForegroundColorAttributeName: textColor])
            
            let titleString = NSAttributedString(string: timeSlot.course!.title!, attributes: highlightAttribs)
            
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
            ind += 1
        }
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        self.trackingAreas.forEach({self.removeTrackingArea($0)})
        
        if isHighlighting {
            let trackingArea = NSTrackingArea(rect: frame, options: [.activeInKeyWindow, .mouseMoved, .mouseEnteredAndExited], owner: self, userInfo: nil)
            addTrackingArea(trackingArea)
        }
    }
    
    var lastEnteredTimeSlot: TimeSlot!
    override func mouseUp(with event: NSEvent) {
        guard let timeSlot = lastEnteredTimeSlot else { return }
        masterVC.notifySelected(course: timeSlot.course!)
    }
    
    override func mouseMoved(with event: NSEvent) {
        let loc = self.convert(event.locationInWindow, from: nil)
        
        // Drawing code here.
        var ind = 0
        var noIntersections = true
        for timeSlot in timeSlotVisuals {
            
            let start = Int(timeSlot.startMinute)
            let stop = Int(timeSlot.stopMinute)
            let day = timeSlot.weekday - (!showSunday).hashValue
            
            let w = self.bounds.width/days
            let x = CGFloat(day - 1) * w
            
            let y = self.bounds.height - self.bounds.height * CGFloat(start - earliestTime)/(minutesShown) - 1
            let h = -self.bounds.height * CGFloat(stop - start)/(minutesShown)
            
            let rect = NSRect(x: x, y: y, width: w, height: h)
            
            if rect.contains(loc) {
                highlightedArray[ind] = true
                noIntersections = false
                NSCursor.pointingHand().set()
                lastEnteredTimeSlot = timeSlot
            } else {
                highlightedArray[ind] = false
            }
            ind += 1
        }
        if noIntersections {
            lastEnteredTimeSlot = nil
            NSCursor.arrow().set()
            for x in 0..<highlightedArray.count {
                highlightedArray[x] = false
            }
        }
        self.needsDisplay = true
    }
    
    override func mouseExited(with event: NSEvent) {
        lastEnteredTimeSlot = nil
        NSCursor.arrow().set()
        for x in 0..<highlightedArray.count {
            highlightedArray[x] = false
        }
        self.needsDisplay = true
    }
    
    // MARK: - Drawing Schedule Boxes

    func addTimeSlotVisual(_ timeSlot: TimeSlot, selected: Bool) {
        
        timeSlotVisuals.append(timeSlot)
        selectedArray.append(selected)
        highlightedArray.append(false)

    }
    
    func clearTimeSlotVisuals() {
        
        // Reset scheduler bounds extension from unusual schedules
        earliestTime = DEFAULT_EARLIEST
        latestTime = DEFAULT_LATEST
        showSaturday = false
        showSunday = false
        
        timeSlotVisuals = [TimeSlot]()
        selectedArray = [Bool]()
        highlightedArray = [Bool]()
    }    
}
