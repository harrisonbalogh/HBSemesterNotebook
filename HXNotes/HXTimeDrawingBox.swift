//
//  HXTimeDrawingBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 9/3/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXTimeDrawingBox: NSView {
    
    private var drawsTimeOfDay = true {
        didSet {
            self.needsDisplay = true
            self.display()
        }
    }
    
    // Schedule Time Bounds
    let DEFAULT_EARLIEST = 480 // 8:00
    let DEFAULT_LATEST = 1319 // 9:59
    var earliestTime = 480 {
        didSet {
            self.needsDisplay = true
        }
    }
    var latestTime = 1319 {
        didSet {
            self.needsDisplay = true
        }
    }
    // This are only shown if a class is present on these days
    var showSaturday = false {
        didSet {
            self.needsDisplay = true
        }
    }
    var showSunday = false {
        didSet {
            self.needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        var days: CGFloat = 5
        if showSaturday { days += 1 }
        if showSunday { days += 1 }
        
        let minutesShown = CGFloat(latestTime - earliestTime + 1)

        // Draw the current time visual. Note return calls. This line is not drawn for PDF or printer operations.
        if drawsTimeOfDay && NSGraphicsContext.current!.isDrawingToScreen {
            
            let date = Date()
            let cal = Calendar.current
            var currentDay = cal.component(.weekday, from: date)
            
            if (currentDay == 1 && !showSunday) || (currentDay == 7 && !showSaturday) {
                return
            }
            
            let timeOfDay = cal.component(.hour, from: date) * 60 + cal.component(.minute, from: date) + cal.component(.second, from: date) / 60
            
            if timeOfDay > latestTime || timeOfDay < earliestTime {
                return
            }
            
            if !showSunday { currentDay -= 1 }
            let lineWidth = self.bounds.width/days
            let lineX = CGFloat(currentDay - 1) * lineWidth
            
            let lineY = self.bounds.height - self.bounds.height * CGFloat(timeOfDay - earliestTime)/(minutesShown)
            
            let startString = NSAttributedString(string: HXTimeFormatter.formatTime(Int16(timeOfDay)), attributes: [NSAttributedStringKey.foregroundColor: NSColor.black])
            
            var bezPath = NSBezierPath(rect: NSRect(x: lineX, y: lineY, width: lineWidth, height: 1))
            NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 0.75).setFill()
            bezPath.fill()
            bezPath = NSBezierPath(rect: NSRect(x: lineX, y: lineY - 1, width: lineWidth, height: 1))
            NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.75).setFill()
            bezPath.fill()
            bezPath = NSBezierPath(roundedRect: NSRect(x: lineX + 2, y: lineY - startString.size().height + 1, width: startString.size().width + 2, height: startString.size().height - 3), xRadius: 2, yRadius: 2)
            NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 0.75).setFill()
            bezPath.fill()
            startString.draw(at: NSPoint(x: lineX + 3, y: lineY - startString.size().height))
        }
    }
    
    // MARK - Notifiers
    
    func notifyDrawsTimeOfDay(_ draws: Bool) {
        drawsTimeOfDay = draws
    }

}
