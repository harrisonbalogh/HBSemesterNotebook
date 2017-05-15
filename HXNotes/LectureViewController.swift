//
//  LectureViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/14/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class LectureViewController: NSViewController {

    @IBOutlet weak var label_lectureTitle: NSTextField!
    @IBOutlet weak var label_lectureDate: NSTextField!
    @IBOutlet weak var scrollView_lecture: HXNonScrollView!
    @IBOutlet var textView_lecture: HXResizingTextView!
    
    var textHeightConstraint: NSLayoutConstraint!
    
    var lecture: Lecture!
    
    func initialize(withNumber: Int, withDate: String, withLecture: Lecture) {
        
        label_lectureTitle.stringValue = "Lecture \(withNumber)"
        
        label_lectureDate.stringValue = withDate
        
        scrollView_lecture.parentController = self
        textView_lecture.parentController = self
        
        textHeightConstraint = scrollView_lecture.heightAnchor.constraint(equalToConstant: 31)
        textHeightConstraint.isActive = true
        
        if withLecture.content != nil {
            textView_lecture.string = withLecture.content
            textHeightConstraint.constant = textHeight()
        }
        
        lecture = withLecture
    }
    
    func notifyScrolling(with event: NSEvent) {
        // Send textView scroller's scrollWheel event to containing scroll view
        self.nextResponder?.scrollWheel(with: event)
    }
    
    func notifyTextChange() {
        // Update height of view
        textHeightConstraint.constant = textHeight()
        // Save to Model
        lecture.content = textView_lecture.string
    }
    
    func textHeight() -> CGFloat {
        let txtStorage = NSTextStorage(string: textView_lecture.string!)
        let txtContainer = NSTextContainer(containerSize: NSSize(width: textView_lecture.frame.width, height: 10000))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(txtContainer)
        txtStorage.addLayoutManager(layoutManager)
        txtStorage.addAttributes([NSFontAttributeName: textView_lecture.font!], range: NSRange(location: 0, length: txtStorage.length))
        txtContainer.lineFragmentPadding = 0
        layoutManager.glyphRange(for: txtContainer)
        return layoutManager.usedRect(for: txtContainer).size.height
    }
}
