//
//  SemesterCourseBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class SemesterCourseBox: NSView {
    
    var selectionDelegate: SelectionDelegate?

    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance(with course: Course) -> SemesterCourseBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: "SemesterCourseBox"), owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is SemesterCourseBox}).first as? SemesterCourseBox {
            newBox.initialize(with: course)
            return newBox
        }
        return nil
    }
    
    weak var course: Course!
    
    @IBOutlet weak var boxDrag: NSBox!
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelLocation: NSTextField!
    @IBOutlet weak var labelLocationHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelProfessor: NSTextField!
    @IBOutlet weak var labelProfessorHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var labelDays: NSTextField!
    @IBOutlet weak var selectImage: NSImageView!
    
    private func initialize(with course: Course) {
        self.course = course
        
        labelTitle.stringValue = course.title!
        if course.location == nil || course.location == "" {
            labelLocation.stringValue = ""
            labelLocationHeightConstraint.constant = 0
        } else {
            labelLocation.stringValue = course.location!
            labelLocationHeightConstraint.constant = 17
        }
        if course.professor == nil || course.professor == "" {
            labelProfessor.stringValue = ""
            labelProfessorHeightConstraint.constant = 0
        } else {
            labelProfessor.stringValue = course.professor!
            labelProfessorHeightConstraint.constant = 17
        }
        labelDays.stringValue = course.daysPerWeekPrintable()
        
        let theColor = NSColor(red: CGFloat(course.color!.red), green: CGFloat(course.color!.green), blue: CGFloat(course.color!.blue), alpha: 1)
        self.boxDrag.fillColor = theColor
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        self.trackingAreas.forEach({self.removeTrackingArea($0)})
        
        let trackingArea = NSTrackingArea(rect: self.bounds, options: [NSTrackingArea.Options.activeInKeyWindow, NSTrackingArea.Options.cursorUpdate, NSTrackingArea.Options.mouseEnteredAndExited], owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    override func cursorUpdate(with event: NSEvent) {
        NSCursor.pointingHand.set()
    }

    override func mouseEntered(with event: NSEvent) {
        selectionDelegate?.courseWasHovered(course)
        hoverVisuals(true)
    }
    
    override func mouseUp(with event: NSEvent) {
        selectionDelegate?.courseWasSelected(course)
    }
    
    override func mouseExited(with event: NSEvent) {
        hoverVisuals(false)
    }
    func hoverVisuals(_ visible: Bool) {
        if visible {
            selectImage.alphaValue = 1
        } else {
            selectImage.alphaValue = 0
        }
    }
}
