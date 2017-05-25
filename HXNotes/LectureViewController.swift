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
    @IBOutlet var textView_lecture: NSTextView!
    
    var textHeightConstraint: NSLayoutConstraint!
    
    var lecture: Lecture!
    
    var owner: EditorViewController!
    
    func initialize(withNumber: Int, withDate: String, withLecture: Lecture, owner: EditorViewController) {
        
        label_lectureTitle.stringValue = "Lecture \(withNumber)"
        
        label_lectureDate.stringValue = withDate
        
        scrollView_lecture.parentController = self
        
        textHeightConstraint = scrollView_lecture.heightAnchor.constraint(equalToConstant: 31)
        textHeightConstraint.isActive = true
        
        if withLecture.content != nil {
            textView_lecture.textStorage?.setAttributedString(withLecture.content!)
            textHeightConstraint.constant = textHeight()
        }
        
        self.lecture = withLecture
        
        self.owner = owner
        
        NotificationCenter.default.addObserver(self, selector: #selector(LectureViewController.notifyTextChange),
                                               name: .NSTextDidChange, object: textView_lecture)
    }
    // ...................................................................................................................
    
    func notifyScrolling(with event: NSEvent) {
        // Send textView scroller's scrollWheel event to containing scroll view
        self.nextResponder?.scrollWheel(with: event)
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        notifyTextChange()
    }
    
    func notifyTextChange() {
        // Update height of view
        textHeightConstraint.constant = textHeight()
        // Save to Model
        lecture.content = textView_lecture.attributedString()
        owner.notifyHeightUpdate(from: self)
    }
    
    func focusText() {
        textView_lecture.window?.makeFirstResponder(textView_lecture)
        // FIX HERE. Need to set text cursor to last element
    }
    
    func textSelectionHeight() -> CGFloat {
        let positionOfSelection = textView_lecture.selectedRanges.first!.rangeValue.location
        let rangeToSelection = NSRange(location: 0, length: positionOfSelection)
        let substring = textView_lecture.attributedString().attributedSubstring(from: rangeToSelection)
        let txtStorage = NSTextStorage(attributedString: substring)
        let txtContainer = NSTextContainer(containerSize: NSSize(width: textView_lecture.frame.width, height: 10000))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(txtContainer)
        txtStorage.addLayoutManager(layoutManager)
        txtStorage.addAttributes([NSFontAttributeName: textView_lecture.font!], range: NSRange(location: 0, length: txtStorage.length))
        txtContainer.lineFragmentPadding = 0
        layoutManager.glyphRange(for: txtContainer)
        return view.frame.origin.y + view.frame.height - (layoutManager.usedRect(for: txtContainer).size.height + 39) // height from top of lecture view to top of text
    }
    
    func textHeight() -> CGFloat {
        let txtStorage = NSTextStorage(attributedString: textView_lecture.attributedString())
        let txtContainer = NSTextContainer(containerSize: NSSize(width: textView_lecture.frame.width, height: 10000))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(txtContainer)
        txtStorage.addLayoutManager(layoutManager)
        txtStorage.addAttributes([NSFontAttributeName: textView_lecture.font!], range: NSRange(location: 0, length: txtStorage.length))
        txtContainer.lineFragmentPadding = 0
        layoutManager.glyphRange(for: txtContainer)
        return layoutManager.usedRect(for: txtContainer).size.height + 50 // 50 is arbitrary bottom buffer space added
    }
}
