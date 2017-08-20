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
    static func instance(numbered number: Int16, dated date: String, owner: CoursePageViewController) -> HXLectureBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXLectureBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXLectureBox}).first as? HXLectureBox {
            newBox.initialize(numbered: Int(number), dated: date, owner: owner)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var imageLecture: NSImageView!
    
    weak var parentController: CoursePageViewController!
    
    func initialize(numbered number: Int, dated date: String, owner: CoursePageViewController) {
        
        labelTitle.stringValue = "Lecture \(number)"
        
        labelDate.stringValue = date
        
        self.parentController = owner
    }
    
    @IBAction func action_clickLecture(_ sender: Any) {
        
//        parentController.select(lecture: labelTitle.stringValue)
        
    }
    
    func focus() {
        imageLecture.image = #imageLiteral(resourceName: "icon_pencil_alt")
    }
    
    func unfocus() {
        imageLecture.image = #imageLiteral(resourceName: "icon_pencil")
    }
}
