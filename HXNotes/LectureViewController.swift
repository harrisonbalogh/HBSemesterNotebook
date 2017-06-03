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
    @IBOutlet weak var image_corner1: NSImageView!
    @IBOutlet weak var image_corner2: NSImageView!
    @IBOutlet weak var image_corner3: NSImageView!
    @IBOutlet weak var image_corner4: NSImageView!
    
    // Set the when user sets or remove focus to the customTitle textField.
    var isTitling = false {
        didSet {
            if isTitling {
                owner.customTitleFocused = self
//                if NSApp.keyWindow?.firstResponder != label_customTitle {
//                    print("Set label_customTitle to responder")
//                    NSApp.keyWindow?.makeFirstResponder(label_customTitle)
//                    owner.customTitleFocused = self
//                }
                
            } else if owner.customTitleFocused != nil {
                if owner.customTitleFocused == self && NSApp.keyWindow!.firstResponder != owner.stickyHeaderCustomTitle {
                    owner.customTitleFocused = nil
                }
            }
        }
    }
    @IBOutlet weak var label_titleDivider: NSTextField!
    @IBOutlet weak var label_customTitle: HXCustomTitleField!
    @IBAction func action_customTitle(_ sender: HXCustomTitleField) {
        NSApp.keyWindow?.makeFirstResponder(self)
    }
    
    // Set when the user sets or removes focus to the textView_lecture. Will reveal
    // or hide styling buttons and update customTitle textField constraints.
    var isStyling = false {
        didSet {
            // Remove constraint before updating and reinstating
            customTitleTrailingConstraint.isActive = false
            if isStyling {
                // Notify owning EditorVC that this LectureVC's textView is being styled
                owner.lectureFocused = self
                // Animate revealing the styling buttons
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 1
                button_style_underline.animator().alphaValue = 1
                button_style_italicize.animator().alphaValue = 1
                button_style_bold.animator().alphaValue = 1
                button_style_left.animator().alphaValue = 1
                button_style_center.animator().alphaValue = 1
                button_style_right.animator().alphaValue = 1
                image_corner1.animator().alphaValue = 1
                image_corner2.animator().alphaValue = 1
                image_corner3.animator().alphaValue = 1
                image_corner4.animator().alphaValue = 1
                NSAnimationContext.endGrouping()
                // Have to shift the customTitle textField to truncate at the closest style button
                customTitleTrailingConstraint = label_customTitle.trailingAnchor.constraint(equalTo: button_style_underline.leadingAnchor)
            } else {
                if owner.lectureFocused == self {
                    owner.lectureFocused = nil
                }
                // Animate hiding the styling buttons
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.25
                button_style_underline.animator().alphaValue = 0
                button_style_italicize.animator().alphaValue = 0
                button_style_bold.animator().alphaValue = 0
                button_style_left.animator().alphaValue = 0
                button_style_center.animator().alphaValue = 0
                button_style_right.animator().alphaValue = 0
                image_corner1.animator().alphaValue = 0
                image_corner2.animator().alphaValue = 0
                image_corner3.animator().alphaValue = 0
                image_corner4.animator().alphaValue = 0
                NSAnimationContext.endGrouping()
                // Have to shift the customTitle textField to extend to the date label
                customTitleTrailingConstraint = label_customTitle.trailingAnchor.constraint(equalTo: label_lectureDate.leadingAnchor)
            }
            // Reinstate constraint
            customTitleTrailingConstraint.isActive = true
        }
    }
    @IBOutlet weak var button_style_underline: NSButton!
    @IBOutlet weak var button_style_italicize: NSButton!
    @IBOutlet weak var button_style_bold: NSButton!
    @IBOutlet weak var button_style_left: NSButton!
    @IBOutlet weak var button_style_center: NSButton!
    @IBOutlet weak var button_style_right: NSButton!
    
    let sharedFontManager = NSFontManager.shared()
    
    var textHeightConstraint: NSLayoutConstraint!
    var customTitleTrailingConstraint: NSLayoutConstraint!
    
    var lecture: Lecture!
    
    var owner: EditorViewController!
    
    func initialize(with lecture: Lecture) {
        if let parentVC = self.parent as? EditorViewController {
            self.owner = parentVC
        }
        
        label_lectureTitle.stringValue = "Lecture \(lecture.number)"
        
        label_lectureDate.stringValue = "\(lecture.month)/\(lecture.day)/\(lecture.year % 100)"
        
        scrollView_lecture.parentController = self
        textView_lecture.parentController = self
        label_customTitle.parentController = self
        
        textHeightConstraint = scrollView_lecture.heightAnchor.constraint(equalToConstant: 31)
        textHeightConstraint.isActive = true
        
        if lecture.content != nil {
            textView_lecture.textStorage?.setAttributedString(lecture.content!)
            textHeightConstraint.constant = textHeight()
        }
        
        self.lecture = lecture
        
        if lecture.title != nil {
            label_customTitle.stringValue = lecture.title!
            if label_customTitle.stringValue == "" {
                label_titleDivider.alphaValue = 0.3
                lecture.title = nil
            } else {
                label_titleDivider.alphaValue = 1
            }
        } else {
            label_titleDivider.alphaValue = 0.3
            lecture.title = nil
        }
        
        customTitleTrailingConstraint = label_customTitle.trailingAnchor.constraint(equalTo: label_lectureDate.leadingAnchor)
        customTitleTrailingConstraint.isActive = true
        
        button_style_underline.alphaValue = 0
        button_style_italicize.alphaValue = 0
        button_style_bold.alphaValue = 0
        button_style_left.alphaValue = 0
        button_style_center.alphaValue = 0
        button_style_right.alphaValue = 0
        
        image_corner1.alphaValue = 0
        image_corner2.alphaValue = 0
        image_corner3.alphaValue = 0
        image_corner4.alphaValue = 0
        
        NotificationCenter.default.addObserver(self, selector: #selector(LectureViewController.notifyTextViewChange),
                                               name: .NSTextDidChange, object: textView_lecture)
        NotificationCenter.default.addObserver(self, selector: #selector(LectureViewController.notifyCustomTitleEndEditing),
                                               name: .NSControlTextDidEndEditing, object: label_customTitle)
        NotificationCenter.default.addObserver(self, selector: #selector(LectureViewController.notifyCustomTitleChange),
                                               name: .NSControlTextDidChange, object: label_customTitle)
        
        NotificationCenter.default.addObserver(self, selector: #selector(LectureViewController.selectionChange),
                                               name: .NSTextViewDidChangeSelection, object: textView_lecture)
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        // Update height of view
//        textHeightConstraint.constant = textHeight()
        
        notifyTextViewChange()
    }
    
    // MARK: Notifiers
    ///
    func notifyCustomTitleChange() {
        if label_customTitle.stringValue == "" {
            label_titleDivider.alphaValue = 0.3
            lecture.title = nil
        } else {
            label_titleDivider.alphaValue = 1
        }
    }
    ///
    func notifyCustomTitleEndEditing() {
        label_customTitle.stringValue = label_customTitle.stringValue.trimmingCharacters(in: .whitespaces)
        // Check if it has content
        if label_customTitle.stringValue == "" {
            label_titleDivider.alphaValue = 0.3
            lecture.title = nil
        } else {
            lecture.title = label_customTitle.stringValue
            label_titleDivider.alphaValue = 1
        }
        if owner != nil {
            notifyCustomTitleFocus(false)
        }
    }
    /// Received from HXNonScrollView's override of scrollWheel.
    func notifyTextViewScrolling(with event: NSEvent) {
        // Send textView scroller's scrollWheel event to containing scroll view
        self.nextResponder?.scrollWheel(with: event)
    }
    /// Any time the textview text changes, this will resize the textView height and the owning EditorVC's 
    /// stack height. Will also update the object model with the new attributed string.
    func notifyTextViewChange() {
        // Update height of view
        textHeightConstraint.constant = textHeight()
        // Save to Model
        lecture.content = textView_lecture.attributedString()
        owner.notifyHeightUpdate(from: self)
        // Update styling buttons
        selectionChange()
    }
    /// Received from HXCustomTitleField
    func notifyCustomTitleFocus(_ focus: Bool) {
        if isTitling != focus {
            isTitling = focus
        }
    }
    /// Received from HXTextView
    func notifyTextViewFocus(_ focus: Bool) {
        if isStyling != focus {
            isStyling = focus
        }
    }
    
    // MARK: Auto Scroll and Resizing Helper Functions
    /// Return the height to the selected character in the textView
    func textSelectionHeight() -> CGFloat {
        if !self.isStyling {
            // If user is not actively editing this lecture's textView, then the request to get selection
            // height came from a clipView resize, not from the user changing the textView text.
            return 0
        }
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
    /// Return the height of all the text in the textView
    func textHeight() -> CGFloat {
        let txtStorage = NSTextStorage(attributedString: textView_lecture.attributedString())
        let txtContainer = NSTextContainer(containerSize: NSSize(width: textView_lecture.frame.width, height: 10000))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(txtContainer)
        txtStorage.addLayoutManager(layoutManager)
        txtStorage.addAttributes([NSFontAttributeName: textView_lecture.font!], range: NSRange(location: 0, length: txtStorage.length))
        txtContainer.lineFragmentPadding = 0
        layoutManager.glyphRange(for: txtContainer)
        return layoutManager.usedRect(for: txtContainer).size.height + 3 // 3 is arbitrary bottom buffer space added
    }
    
    // MARK: Styling Functionality
    ///
    func textIncrease() {
    }
    ///
    func textDecrease() {
    }
    ///
    func textColor() {
    }
    ///
    func textShowFonts() {
    }
    ///
    @IBAction func action_styleUnderline(_ sender: Any) {
        if isStyling {
            textView_lecture.underline(self)
            textView_lecture.needsDisplay = true
            notifyTextViewChange()
        }
    }

    @IBAction func action_styleItalicize(_ sender: NSButton) {
        sharedFontManager.addFontTrait(sender)
    }
    @IBAction func action_styleBold(_ sender: NSButton) {
        sharedFontManager.addFontTrait(sender)
    }
    
    ///
    @IBAction func action_styleLeft(_ sender: Any) {
        if isStyling {
            textView_lecture.alignLeft(self)
        }
    }
    ///
    @IBAction func action_styleCenter(_ sender: Any) {
        if isStyling {
            textView_lecture.alignCenter(self)
        }
    }
    ///
    @IBAction func action_styleRight(_ sender: Any) {
        if isStyling {
            textView_lecture.alignRight(self)
        }
    }
    func selectionChange() {
        if sharedFontManager.selectedFont == nil {
            return
        }
        
        let traits = sharedFontManager.traits(of: sharedFontManager.selectedFont!)
        
        print("traits: \(traits)")
        if traits == NSFontTraitMask.boldFontMask {
            button_style_bold.state = NSOnState
            button_style_italicize.state = NSOffState
        }
        if traits == NSFontTraitMask.italicFontMask {
            button_style_bold.state = NSOffState
            button_style_italicize.state = NSOnState
        }
        if traits == NSFontTraitMask.init(rawValue: 0) {
            button_style_bold.state = NSOffState
            button_style_italicize.state = NSOffState
        }
        if traits == NSFontTraitMask.init(rawValue: 3) {
            button_style_bold.state = NSOnState
            button_style_italicize.state = NSOnState
        }
        
        owner.textSelectionChange()
    }
    
    
    
    
    

    
}
