//
//  CourseAddBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/17/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXCourseAddBox: NSBox {
    
    var parentController: CalendarViewController!
    
    func setParentController(controller: CalendarViewController) {
        parentController = controller
    }
    
    override func mouseDown(with event: NSEvent) {
        parentController.action_addCourseButton()
    }
}
