//
//  SemesterCourseBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SemesterCourseBox: NSView {

    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance(with course: Course, owner: SemesterPageViewController) -> SemesterCourseBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("SemesterCourseBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is SemesterCourseBox}).first as? SemesterCourseBox {
            newBox.initialize(with: course, owner: owner)
            return newBox
        }
        return nil
    }
    
    weak var course: Course!
    weak var owner: SemesterPageViewController!
    
    @IBOutlet weak var boxDrag: NSBox!
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelDays: NSTextField!
    @IBOutlet weak var buttonOverlay: NSButton!
    
    private func initialize(with course: Course, owner: SemesterPageViewController) {
        self.course = course
        self.owner = owner
        
        labelTitle.stringValue = course.title!
        labelDays.stringValue = course.daysPerWeekPrintable()
        
        let theColor = NSColor(red: CGFloat(course.color!.red), green: CGFloat(course.color!.green), blue: CGFloat(course.color!.blue), alpha: 1)
        self.boxDrag.fillColor = theColor
        
//        let trackArea = NSTrackingArea(
//            rect: self.bounds,
//            options: [NSTrackingAreaOptions.activeInKeyWindow, NSTrackingAreaOptions.mouseEnteredAndExited],
//            owner: self,
//            userInfo: nil)
//        addTrackingArea(trackArea)
    }
    
    @IBAction func goToNotes(_ sender: Any) {
        owner.notifySelected(course: course)
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.pointingHand().push()
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.pointingHand().pop()
    }
    
}
