//
//  CourseLectureBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseLectureBox: NSBox {

    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance(with lecture: Lecture, owner: CoursePageViewController) -> CourseLectureBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("CourseLectureBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is CourseLectureBox}).first as? CourseLectureBox {
            newBox.initialize(with: lecture, owner: owner)
            return newBox
        }
        return nil
    }
    
    weak var lecture: Lecture!
    weak var owner: CoursePageViewController!
    
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelCustomTitle: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var imageLecture: NSImageView!
    
    private func initialize(with lecture: Lecture, owner: CoursePageViewController) {
        self.lecture = lecture
        self.owner = owner
        
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
        
        owner.notifySelected(lecture: lecture)
        
    }
    
    // MARK: - Update visuals
    
    func updateVisual(selected: Bool) {
        if selected {
            imageLecture.image = #imageLiteral(resourceName: "icon_pencil_alt")
        } else {
            imageLecture.image = #imageLiteral(resourceName: "icon_pencil")
        }
        
    }
    
}
