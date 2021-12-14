//
//  CourseLectureBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseLectureBox: NSBox {
    
    var selectionDelegate: SelectionDelegate?

    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance(with lecture: Lecture) -> CourseLectureBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: "CourseLectureBox"), owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is CourseLectureBox}).first as? CourseLectureBox {
            newBox.initialize(with: lecture)
            return newBox
        }
        return nil
    }
    
    var isSelected = false
    
    weak var lecture: Lecture!
    
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelCustomTitle: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var labelAbsent: NSTextField!

    @IBOutlet weak var selectImage: NSImageView!
    
    private func initialize(with lecture: Lecture) {
        self.lecture = lecture
        
        // APPLY DIFFERENCE VISUALS IF lecture.absent is T
        
        if lecture.title != nil {
            labelCustomTitle.stringValue = lecture.title!
        } else {
            labelCustomTitle.stringValue = ""
        }
        
        if lecture.absent {
            labelAbsent.stringValue = "Absent"
        }
        
        labelTitle.stringValue = "Lecture \(lecture.number)"
        
        labelDate.stringValue = "\(lecture.month)/\(lecture.day)"
    }
    
    @IBAction func action_clickLecture(_ sender: Any) {
        selectionDelegate?.isEditing(lecture: lecture)
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
        selectionDelegate?.lectureWasHovered(lecture)
        hoverVisuals(true)
    }
    
    override func mouseExited(with event: NSEvent) {
        hoverVisuals(false)
    }
    
    // MARK: - Update visuals
    
    func hoverVisuals(_ visible: Bool) {
        if isSelected {
            return
        }
        if visible {
            selectImage.alphaValue = 1
            labelDate.alphaValue = 0
            labelAbsent.alphaValue = 0
            labelCustomTitle.stringValue = "Edit Notes"
        } else {
            selectImage.alphaValue = 0
            labelDate.alphaValue = 1
            labelAbsent.alphaValue = 1
            if lecture == nil {
                labelCustomTitle.stringValue = "Deleted"
            } else if lecture.title != nil {
                labelCustomTitle.stringValue = lecture.title!
            } else {
                labelCustomTitle.stringValue = ""
            }
        }
    }
    
    func updateVisual(selected: Bool) {
        isSelected = selected
        if selected {
            let theColor = NSColor(red: CGFloat(lecture.course!.color!.red), green: CGFloat(lecture.course!.color!.green), blue: CGFloat(lecture.course!.color!.blue), alpha: 0.5)
            self.fillColor = theColor
            labelCustomTitle.stringValue = "Notes Open"
        } else {
            self.fillColor = NSColor.clear
            selectImage.alphaValue = 0
            labelDate.alphaValue = 1
            labelAbsent.alphaValue = 1
            if lecture == nil {
                labelCustomTitle.stringValue = "Deleted"
            } else if lecture.title != nil {
                labelCustomTitle.stringValue = lecture.title!
            } else {
                labelCustomTitle.stringValue = ""
            }
        }
    }
    
    func size(reduced: Bool) {
        
    }
}
