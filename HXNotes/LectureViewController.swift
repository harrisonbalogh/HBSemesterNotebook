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
    @IBOutlet weak var box_dropdown: NSBox!
    
    var findViewController: HXFindViewController!
    var replaceViewController: HXFindReplaceViewController!
    var exportViewController: HXExportViewController!
    
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
    var isFinding = false {
        didSet {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            NSAnimationContext.current().duration = 0.25
            if isFinding && (isExporting || isReplacing) {
                if isExporting {
                    isExporting = false
                } else {
                    isReplacing = false
                }
            } else if isFinding {
                box_dropdown.addSubview(findViewController.view)
                findViewController.view.leadingAnchor.constraint(equalTo: box_dropdown.leadingAnchor).isActive = true
                findViewController.view.trailingAnchor.constraint(equalTo: box_dropdown.trailingAnchor).isActive = true
                findViewController.view.topAnchor.constraint(equalTo: box_dropdown.topAnchor).isActive = true
                findViewController.view.bottomAnchor.constraint(equalTo: box_dropdown.bottomAnchor).isActive = true
                
                NSAnimationContext.current().completionHandler = {
                    NSApp.keyWindow?.makeFirstResponder(self.findViewController.textField_find)
                }
                dropdownTopConstraint.animator().constant = box_dropdown.frame.height
                
                owner.notifyLectureSelection(lecture: label_lectureTitle.stringValue)
            } else {
                if NSApp.keyWindow?.firstResponder == findViewController.textField_find {
                    NSApp.keyWindow?.makeFirstResponder(self)
                }
                NSAnimationContext.current().completionHandler = {
                    self.findViewController.view.removeFromSuperview()
                    if self.isExporting {
                        self.isExporting = true
                    } else if self.isReplacing {
                        self.isReplacing = true
                    }
                }
                dropdownTopConstraint.animator().constant = 0
            }
            NSAnimationContext.endGrouping()
        }
    }
    var isReplacing = false {
        didSet {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            NSAnimationContext.current().duration = 0.25
            if isReplacing && (isExporting || isFinding) {
                if isExporting {
                    isExporting = false
                } else {
                    isFinding = false
                }
            } else if isReplacing {
                box_dropdown.addSubview(replaceViewController.view)
                replaceViewController.view.leadingAnchor.constraint(equalTo: box_dropdown.leadingAnchor).isActive = true
                replaceViewController.view.trailingAnchor.constraint(equalTo: box_dropdown.trailingAnchor).isActive = true
                replaceViewController.view.topAnchor.constraint(equalTo: box_dropdown.topAnchor).isActive = true
                replaceViewController.view.bottomAnchor.constraint(equalTo: box_dropdown.bottomAnchor).isActive = true
                
                NSAnimationContext.current().completionHandler = {
//                    NSApp.keyWindow?.makeFirstResponder(self.findViewController.textField_find)
                }
                dropdownTopConstraint.animator().constant = box_dropdown.frame.height
                
                owner.notifyLectureSelection(lecture: label_lectureTitle.stringValue)
            } else {
                if NSApp.keyWindow?.firstResponder == findViewController.textField_find {
                    NSApp.keyWindow?.makeFirstResponder(self)
                }
                NSAnimationContext.current().completionHandler = {
                    self.replaceViewController.view.removeFromSuperview()
                    if self.isExporting {
                        self.isExporting = true
                    } else if self.isFinding {
                        self.isFinding = true
                    }
                }
                dropdownTopConstraint.animator().constant = 0
            }
            NSAnimationContext.endGrouping()
        }
    }
    var isExporting = false {
        didSet {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            NSAnimationContext.current().duration = 0.25
            if isExporting && isFinding {
                isFinding = false
            } else if isExporting {
                box_dropdown.addSubview(exportViewController.view)
                exportViewController.view.leadingAnchor.constraint(equalTo: box_dropdown.leadingAnchor).isActive = true
                exportViewController.view.trailingAnchor.constraint(equalTo: box_dropdown.trailingAnchor).isActive = true
                exportViewController.view.topAnchor.constraint(equalTo: box_dropdown.topAnchor).isActive = true
                exportViewController.view.bottomAnchor.constraint(equalTo: box_dropdown.bottomAnchor).isActive = true

                dropdownTopConstraint.animator().constant = box_dropdown.frame.height
                
                owner.notifyLectureSelection(lecture: label_lectureTitle.stringValue)
            } else {
                if NSApp.keyWindow?.firstResponder == exportViewController.textField_name {
                    NSApp.keyWindow?.makeFirstResponder(self)
                }
                NSAnimationContext.current().completionHandler = {
                    self.exportViewController.view.removeFromSuperview()
                    if self.isFinding {
                        self.isFinding = true
                    } else if self.isReplacing {
                        self.isReplacing = true
                    }
                }
                dropdownTopConstraint.animator().constant = 0
            }
            NSAnimationContext.endGrouping()
        }
    }
    
    @IBOutlet weak var button_style_underline: NSButton!
    @IBOutlet weak var button_style_italicize: NSButton!
    @IBOutlet weak var button_style_bold: NSButton!
    @IBOutlet weak var button_style_left: NSButton!
    @IBOutlet weak var button_style_center: NSButton!
    @IBOutlet weak var button_style_right: NSButton!
    
    let sharedFontManager = NSFontManager.shared()
    
    @IBOutlet weak var textHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dropdownTopConstraint: NSLayoutConstraint!
    var customTitleTrailingConstraint: NSLayoutConstraint!
    
    var lecture: Lecture!
    
    var owner: EditorViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Laggy spot here?
        findViewController = HXFindViewController(nibName: "HXFindView", bundle: nil)
        self.addChildViewController(findViewController)
        exportViewController = HXExportViewController(nibName: "HXExportView", bundle: nil)
        self.addChildViewController(exportViewController)
        replaceViewController = HXFindReplaceViewController(nibName: "HXFindReplaceView", bundle: nil)
        self.addChildViewController(replaceViewController)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        owner.notifyHeightUpdate()
    }
    
    func initialize(with lecture: Lecture) {
        if let parentVC = self.parent as? EditorViewController {
            self.owner = parentVC
        }
        
        label_lectureTitle.stringValue = "Lecture \(lecture.number)"
        
        label_lectureDate.stringValue = "\(lecture.month)/\(lecture.day)/\(lecture.year % 100)"
        
        scrollView_lecture.parentController = self
        textView_lecture.parentController = self
        label_customTitle.parentController = self
        
        if lecture.content != nil {
            textView_lecture.textStorage?.setAttributedString(lecture.content!)
        }
        
        self.lecture = lecture
        
        if lecture.title != nil {
            label_customTitle.stringValue = lecture.title!
            if label_customTitle.stringValue == "" {
                label_titleDivider.alphaValue = 0.3
            } else {
                label_titleDivider.alphaValue = 1
            }
        } else {
            label_titleDivider.alphaValue = 0.3
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
        NotificationCenter.default.addObserver(self, selector: #selector(LectureViewController.traitChange),
                                               name: .NSTextViewDidChangeTypingAttributes, object: textView_lecture)
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        // Update height of view - Distinguish this from textHeight() method
        // Important to calculate height when text container is given a very large height to work with (99999)
        // when laying out. textHeight() should be faster (untested) as it creates far fewer temp objects
        let txtStorage = NSTextStorage(attributedString: textView_lecture.attributedString())
        let txtContainer = NSTextContainer(containerSize: NSSize(width: textView_lecture.frame.width, height: 99999))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(txtContainer)
        txtStorage.addLayoutManager(layoutManager)
        txtStorage.addAttributes([NSFontAttributeName: textView_lecture.font!], range: NSRange(location: 0, length: txtStorage.length))
        txtContainer.lineFragmentPadding = 0
        layoutManager.glyphRange(for: txtContainer)
        // 3 is arbitrary bottom buffer space added
        let textHeight = layoutManager.usedRect(for: txtContainer).size.height + 3
        
        textHeightConstraint.constant = textHeight
    }
    
    // MARK: Notifiers
    ///
    func notifyCustomTitleChange() {
        if label_customTitle.stringValue == "" {
            label_titleDivider.alphaValue = 0.3
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
        let newHeight = textHeight()
        if newHeight != textHeightConstraint.constant {
            textHeightConstraint.constant = newHeight
            owner.notifyHeightUpdate()
        }
        // Save to Model
        lecture.content = textView_lecture.attributedString()
        owner.checkScrollLevel(from: self)
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
    internal func textSelectionHeight() -> CGFloat {
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
    private func textHeight() -> CGFloat {
        return textView_lecture.layoutManager!.usedRect(for: textView_lecture.textContainer!).size.height + 3
        // 3 is arbitrary bottom buffer space added
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
            button_style_center.state = NSOffState
            button_style_right.state = NSOffState
        }
    }
    ///
    @IBAction func action_styleCenter(_ sender: Any) {
        if isStyling {
            textView_lecture.alignCenter(self)
            button_style_left.state = NSOffState
            button_style_right.state = NSOffState
        }
    }
    ///
    @IBAction func action_styleRight(_ sender: Any) {
        if isStyling {
            textView_lecture.alignRight(self)
            button_style_center.state = NSOffState
            button_style_left.state = NSOffState
        }
    }
    func selectionChange() {
        if sharedFontManager.selectedFont == nil || textView_lecture.attributedString().length == 0 {
            return
        }
        
        let traits = sharedFontManager.traits(of: sharedFontManager.selectedFont!)
        var positionOfSelection = textView_lecture.selectedRanges.first!.rangeValue.location
        if positionOfSelection == textView_lecture.attributedString().length {
            positionOfSelection = textView_lecture.attributedString().length - 1
        }
        var isUnderlined = false
        
        if textView_lecture.attributedString().attribute("NSUnderline", at: positionOfSelection, effectiveRange: nil) != nil {
            button_style_underline.state = NSOnState
            isUnderlined = true
        } else {
            button_style_underline.state = NSOffState
            isUnderlined = false
        }
        
        var theAlignment = 0
        if let parStyle = textView_lecture.attributedString().attribute("NSParagraphStyle", at: positionOfSelection, effectiveRange: nil) as? NSParagraphStyle {
            
            button_style_left.state = NSOffState
            button_style_center.state = NSOffState
            button_style_right.state = NSOffState
            
            if parStyle.alignment.rawValue == 0 {
                theAlignment = 0
                button_style_left.state = NSOnState
                button_style_center.state = NSOffState
                button_style_right.state = NSOffState
            } else if parStyle.alignment.rawValue == 1 {
                theAlignment = 1
                button_style_right.state = NSOnState
                button_style_left.state = NSOffState
                button_style_center.state = NSOffState
            } else if parStyle.alignment.rawValue == 2 {
                theAlignment = 2
                button_style_center.state = NSOnState
                button_style_left.state = NSOffState
                button_style_right.state = NSOffState
            }
        }
        
        
        if traits == NSFontTraitMask.boldFontMask {
            button_style_bold.state = NSOnState
            button_style_bold.tag = Int(NSFontTraitMask.unboldFontMask.rawValue)
            button_style_italicize.state = NSOffState
            button_style_italicize.tag = Int(NSFontTraitMask.italicFontMask.rawValue)
        }
        if traits == NSFontTraitMask.italicFontMask {
            button_style_bold.state = NSOffState
            button_style_bold.tag = Int(NSFontTraitMask.boldFontMask.rawValue)
            button_style_italicize.tag = Int(NSFontTraitMask.unitalicFontMask.rawValue)
            button_style_italicize.state = NSOnState
        }
        if traits == NSFontTraitMask.init(rawValue: 0) {
            button_style_bold.state = NSOffState
            button_style_bold.tag = Int(NSFontTraitMask.boldFontMask.rawValue)
            button_style_italicize.state = NSOffState
            button_style_italicize.tag = Int(NSFontTraitMask.italicFontMask.rawValue)
        }
        if traits == NSFontTraitMask.init(rawValue: 3) {
            button_style_bold.state = NSOnState
            button_style_bold.tag = Int(NSFontTraitMask.unboldFontMask.rawValue)
            button_style_italicize.state = NSOnState
            button_style_italicize.tag = Int(NSFontTraitMask.unitalicFontMask.rawValue)
        }
        
        owner.textSelectionChange(with: traits, underlined: isUnderlined, alignment: theAlignment)
    }
    func traitChange() {
        selectionChange()
    }
}
