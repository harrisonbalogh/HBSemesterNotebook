//
//  HXExamBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXExamBox: NSView {
    
    /// Return a new instance of a HXCourseBox based on the nib template.
    static func instance(with test: Test, for courseVC: CoursePageViewController) -> HXExamBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXExamBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXExamBox}).first as? HXExamBox {
            newBox.initialize(with: test, for: courseVC)
            return newBox
        }
        return nil
    }

    @IBOutlet weak var labelExam: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var buttonDetails: NSButton!
    
    weak var test: Test!
    weak var parent: CoursePageViewController!
    
    func initialize(with test: Test, for courseVC: CoursePageViewController) {
        labelExam.stringValue = test.title!
        if test.date == nil {
            labelDate.stringValue = ""
        } else {
            let day = Calendar.current.component(.day, from: test.date!)
            let month = Calendar.current.component(.month, from: test.date!)
            let year = Calendar.current.component(.year, from: test.date!)
            labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
        }
        
        self.test = test
        self.parent = courseVC
    }
    
    @IBAction func action_showDetails(_ sender: NSButton) {
        parent.notifyReveal(examBox: self)
    }
}
