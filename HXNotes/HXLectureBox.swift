//
//  HXLectureLedger.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/9/17.
//  Copyright © 2017 Harxer. All rights reserved.
//
    
import Cocoa

class HXLectureBox: NSBox {
    
    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance(numbered number: Int16, dated date: String, owner: SidebarViewController) -> HXLectureBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXLectureBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXLectureBox}).first as? HXLectureBox {
            newBox.initialize(numbered: Int(number), dated: date, owner: owner)
            return newBox
        }
        return nil
    }
    
    // Manually connect drag box child elements using identifiers
    let ID_LABEL_TITLE      = "lecture_label_title"
    let ID_LABEL_DATE       = "lecture_label_date"
    let ID_IMAGE            = "lecture_image"
    let ID_BUTTON_OVERLAY   = "lecture_button_overlay"
    // Elements of course box
    var labelTitle: NSTextField!
    var labelDate: NSTextField!
    var imageLecture: NSImageView!
    var buttonOverlay: NSButton!
    
    var parentController: SidebarViewController!
    
    func initialize(numbered number: Int, dated date: String, owner: SidebarViewController) {
        
        // Initialize child elements
        for v in self.subviews[0].subviews {
            switch v.identifier! {
            case ID_LABEL_TITLE:
                labelTitle = v as! NSTextField
            case ID_LABEL_DATE:
                labelDate = v as! NSTextField
            case ID_IMAGE:
                imageLecture = v as! NSImageView
            case ID_BUTTON_OVERLAY:
                buttonOverlay = v as! NSButton
            default: continue
            }
        }
        
        labelTitle.stringValue = "Lecture \(number)"
        
        labelDate.stringValue = date
        
        self.parentController = owner
        
        buttonOverlay.target = self
        buttonOverlay.action = #selector(HXLectureBox.action_clickLecture)
    }
    
    func action_clickLecture() {
        
        parentController.select(lecture: labelTitle.stringValue)
    }
    
    func focus() {
        imageLecture.image = #imageLiteral(resourceName: "icon_pencil_alt")
    }
    
    func unfocus() {
        imageLecture.image = #imageLiteral(resourceName: "icon_pencil")
    }
}
