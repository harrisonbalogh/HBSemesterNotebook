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
    @IBOutlet var textView_lecture: HXTextView!
    @IBOutlet weak var label_titleDivider: NSTextField!
    @IBOutlet weak var label_customTitle: NSTextField!
    @IBOutlet weak var button_style_regular: NSButton!
    @IBOutlet weak var button_style_underline: NSButton!
    @IBOutlet weak var button_style_italicize: NSButton!
    @IBOutlet weak var button_style_bold: NSButton!
    @IBOutlet weak var button_style_left: NSButton!
    @IBOutlet weak var button_style_center: NSButton!
    @IBOutlet weak var button_style_right: NSButton!
    
    var textHeightConstraint: NSLayoutConstraint!
    var customTitleTrailingConstraint: NSLayoutConstraint!
    
    var lecture: Lecture!
    
    var owner: EditorViewController!
    
    var hasFocus = false {
        didSet {
            customTitleTrailingConstraint.isActive = false
            if hasFocus {
                // Animate scrolling timeline
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 1
                button_style_regular.animator().alphaValue = 1
                button_style_underline.animator().alphaValue = 1
                button_style_italicize.animator().alphaValue = 1
                button_style_bold.animator().alphaValue = 1
                button_style_regular.animator().alphaValue = 1
                button_style_left.animator().alphaValue = 1
                button_style_center.animator().alphaValue = 1
                button_style_right.animator().alphaValue = 1
                NSAnimationContext.endGrouping()
                customTitleTrailingConstraint = label_customTitle.trailingAnchor.constraint(equalTo: button_style_regular.leadingAnchor)
            } else {
                // Animate scrolling timeline
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.25
                button_style_regular.animator().alphaValue = 0
                button_style_underline.animator().alphaValue = 0
                button_style_italicize.animator().alphaValue = 0
                button_style_bold.animator().alphaValue = 0
                button_style_regular.animator().alphaValue = 0
                button_style_left.animator().alphaValue = 0
                button_style_center.animator().alphaValue = 0
                button_style_right.animator().alphaValue = 0
                NSAnimationContext.endGrouping()
                customTitleTrailingConstraint = label_customTitle.trailingAnchor.constraint(equalTo: label_lectureDate.leadingAnchor)
            }
            customTitleTrailingConstraint.isActive = true
        }
    }
    
    func initialize(withNumber: Int, withDate: String, withLecture: Lecture, owner: EditorViewController) {
        
        label_lectureTitle.stringValue = "Lecture \(withNumber)"
        
        label_lectureDate.stringValue = withDate
        
        scrollView_lecture.parentController = self
        textView_lecture.parentController = self
        
        textHeightConstraint = scrollView_lecture.heightAnchor.constraint(equalToConstant: 31)
        textHeightConstraint.isActive = true
        
        if withLecture.content != nil {
            textView_lecture.textStorage?.setAttributedString(withLecture.content!)
            textHeightConstraint.constant = textHeight()
        }
        
        self.lecture = withLecture
        
        if lecture.title == nil {
            label_customTitle.stringValue = ""
        } else {
            label_customTitle.stringValue = lecture.title!
        }
        notifyCustomTitleUpdate()
        
        customTitleTrailingConstraint = label_customTitle.trailingAnchor.constraint(equalTo: label_lectureDate.leadingAnchor)
        customTitleTrailingConstraint.isActive = true
        
        self.owner = owner
        
        button_style_regular.alphaValue = 0
        button_style_underline.alphaValue = 0
        button_style_italicize.alphaValue = 0
        button_style_bold.alphaValue = 0
        button_style_regular.alphaValue = 0
        button_style_left.alphaValue = 0
        button_style_center.alphaValue = 0
        button_style_right.alphaValue = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(LectureViewController.notifyTextChange),
                                               name: .NSTextDidChange, object: textView_lecture)
        NotificationCenter.default.addObserver(self, selector: #selector(LectureViewController.notifyCustomTitleUpdate),
                                               name: .NSControlTextDidEndEditing, object: label_customTitle)
        NotificationCenter.default.addObserver(self, selector: #selector(LectureViewController.notifyCustomTitleChange),
                                               name: .NSControlTextDidChange, object: label_customTitle)

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
    
    @IBAction func action_customTitle(_ sender: Any) {
        NSApp.keyWindow?.makeFirstResponder(self)
    }
    
    func notifyCustomTitleChange() {
        if label_customTitle.stringValue == "" {
            label_titleDivider.alphaValue = 0.3
            lecture.title = nil
        } else {
            label_titleDivider.alphaValue = 1
        }
    }
    
    func notifyCustomTitleUpdate() {
        label_customTitle.stringValue = label_customTitle.stringValue.trimmingCharacters(in: .whitespaces)
        // Check if it has content
        if label_customTitle.stringValue == "" {
            label_titleDivider.alphaValue = 0.3
            lecture.title = nil
        } else {
            lecture.title = label_customTitle.stringValue
            label_titleDivider.alphaValue = 1
        }
    }
    
    func notifyTextChange() {
        // Update height of view
        textHeightConstraint.constant = textHeight()
        // Save to Model
        lecture.content = textView_lecture.attributedString()
        owner.notifyHeightUpdate(from: self)
    }
    
    func notifyFocus(_ focus: Bool) {
        if focus {
            owner.lectureFocused = self
            hasFocus = true
        } else {
            hasFocus = false
            if owner.lectureFocused == self {
                owner.lectureFocused = nil
            }
        }
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
    
    // MARK: Edit text selection
    func textIncrease() {
    }
    func textDecrease() {
    }
    func textColor() {
    }
    func textShowFonts() {
    }
    @IBAction func action_styleRegular(_ sender: Any) {
        if hasFocus {
            textView_lecture.textStorage?.applyFontTraits(.unboldFontMask, range: textView_lecture.selectedRange())
            textView_lecture.textStorage?.applyFontTraits(.unitalicFontMask, range: textView_lecture.selectedRange())
            textView_lecture.needsDisplay = true
            notifyTextChange()
        }
    }
    @IBAction func action_styleUnderline(_ sender: Any) {
        if hasFocus {
            textView_lecture.underline(self)
            textView_lecture.needsDisplay = true
            notifyTextChange()
        }
    }
    @IBAction func action_styleItalicize(_ sender: Any) {
        if hasFocus {
            textView_lecture.textStorage?.applyFontTraits(.italicFontMask, range: textView_lecture.selectedRange())
            textView_lecture.needsDisplay = true
            notifyTextChange()
        }
    }
    @IBAction func action_styleBold(_ sender: Any) {
        if hasFocus {
            textView_lecture.textStorage?.applyFontTraits(.boldFontMask, range: textView_lecture.selectedRange())
            textView_lecture.needsDisplay = true
            notifyTextChange()
        }
    }
    @IBAction func action_styleLeft(_ sender: Any) {
        if hasFocus {
            textView_lecture.alignLeft(self)
        }
    }
    @IBAction func action_styleCenter(_ sender: Any) {
        if hasFocus {
            textView_lecture.alignCenter(self)
        }
    }
    @IBAction func action_styleRight(_ sender: Any) {
        if hasFocus {
            textView_lecture.alignRight(self)
        }
    }
}
