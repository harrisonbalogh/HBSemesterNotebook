//
//  HXDeleteConfirmationBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/2/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXDeleteConfirmationBox: NSBox {

    /// Return a new instance of a HXCourseEditBox based on the nib template.
    static func instance(with course: Course, for parent: SidebarViewController) -> HXDeleteConfirmationBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXDeleteConfirmationBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXDeleteConfirmationBox}).first as? HXDeleteConfirmationBox {
            newBox.initialize(with: course, for: parent)
            return newBox
        }
        return nil
    }
    
    var parent: SidebarViewController!
    
    // Manually connect course box child elements using identifiers
    let ID_BUTTON_CANCEL     = "button_cancel_id"
    let ID_BUTTON_DELETE     = "button_delete_id"
    let ID_COPY_TEXT         = "text_copy_id"
    // Elements of course box
    var labelCopy: NSTextField!
    var buttonCancel: NSButton!
    var buttonDelete: NSButton!
    
    func initialize(with course: Course, for parent: SidebarViewController) {
        self.parent = parent
        
        // Initialize child elements
        for v in self.subviews[0].subviews[0].subviews[0].subviews {
            switch v.identifier! {
            case ID_BUTTON_CANCEL:
                buttonCancel = v as! NSButton
            case ID_BUTTON_DELETE:
                buttonDelete = v as! NSButton
            case ID_COPY_TEXT:
                labelCopy = v as! NSTextField
            default: continue
            }
        }
        
        labelCopy.stringValue = "Are you sure you wish to delete course '\(course.title!)'?"
        if course.lectures!.count == 1 {
            labelCopy.stringValue.append("A lecture associated with this course will be lost if you proceed.")
        } else if course.lectures!.count > 1 {
            labelCopy.stringValue.append(" There are \(course.lectures!.count) lectures associated with this course that will be lost if you proceed.")
        }
        
        // Initialize button functionality
        buttonDelete.target = self
        buttonDelete.action = #selector(self.confirmDelete)
        buttonCancel.target = self
        buttonCancel.action = #selector(self.cancelDelete)
    }
    
    func confirmDelete() {
        parent.removeCourseConfirmed()
    }
    func cancelDelete() {
        parent.removeCourseCanceled()
    }
}
