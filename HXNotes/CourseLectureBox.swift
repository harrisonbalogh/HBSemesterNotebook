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
        Bundle.main.loadNibNamed("CourseLectureBox", owner: nil, topLevelObjects: &theObjects)
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

    @IBOutlet weak var selectImage: NSImageView!
    
    private func initialize(with lecture: Lecture) {
        self.lecture = lecture
        
        // APPLY DIFFERENCE VISUALS IF lecture.absent is T
        
        if lecture.title != nil {
            labelCustomTitle.stringValue = lecture.title!
        } else {
            labelCustomTitle.stringValue = ""
        }
        
        labelTitle.stringValue = "Lecture \(lecture.number)"
        
        labelDate.stringValue = "\(lecture.month)/\(lecture.day)/\(lecture.course!.semester!.year % 100)"
    }
    
    @IBAction func action_clickLecture(_ sender: Any) {
        selectionDelegate?.isEditing(lecture: lecture)
    }
    
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        
        self.trackingAreas.forEach({self.removeTrackingArea($0)})
        
        let trackingArea = NSTrackingArea(rect: self.bounds, options: [.activeInKeyWindow, .cursorUpdate, .mouseEnteredAndExited], owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    override func cursorUpdate(with event: NSEvent) {
        NSCursor.pointingHand().set()
    }
    
    override func mouseEntered(with event: NSEvent) {
        if !isSelected {
            selectImage.alphaValue = 1
            labelDate.alphaValue = 0
            labelCustomTitle.stringValue = "Edit Notes"
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if !isSelected {
            selectImage.alphaValue = 0
            labelDate.alphaValue = 1
            if lecture.title != nil {
                labelCustomTitle.stringValue = lecture.title!
            } else {
                labelCustomTitle.stringValue = ""
            }
        }
    }
    
    // MARK: - Update visuals
    
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
            if lecture.title != nil {
                labelCustomTitle.stringValue = lecture.title!
            } else {
                labelCustomTitle.stringValue = ""
            }
        }
    }
    
}
