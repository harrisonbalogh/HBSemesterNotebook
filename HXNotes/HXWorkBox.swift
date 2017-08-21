//
//  HXWorkBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/20/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXWorkBox: NSView {

    /// Return a new instance of a HXCourseBox based on the nib template.
    static func instance(with work: Work, for courseVC: CoursePageViewController) -> HXWorkBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("HXWorkBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is HXWorkBox}).first as? HXWorkBox {
            newBox.initialize(with: work, for: courseVC)
            return newBox
        }
        return nil
    }
    
    @IBOutlet weak var labelWork: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var buttonDetails: NSButton!
    
    weak var work: Work!
    weak var parent: CoursePageViewController!
    
    func initialize(with work: Work, for courseVC: CoursePageViewController) {
        labelWork.stringValue = work.title!
        if work.date == nil {
            labelDate.stringValue = ""
        } else {
            let day = Calendar.current.component(.day, from: work.date!)
            let month = Calendar.current.component(.month, from: work.date!)
            let year = Calendar.current.component(.year, from: work.date!)
            labelDate.stringValue = "\(month)/\(day)/\(year % 100)"
        }
        
        self.work = work
        self.parent = courseVC
    }
    
    @IBAction func action_showDetails(_ sender: NSButton) {
        parent.notifyReveal(workBox: self)
    }    
}
