//
//  LectureEditorViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/23/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class LectureEditorViewController: NSViewController {
    
    let sharedFontManager = NSFontManager.shared()
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    
    var selectionDelegate: SelectionDelegate?
    
    @IBOutlet weak var labelTitle: NSTextField!
    @IBOutlet weak var labelTitleDivider: NSTextField!
    @IBOutlet weak var labelCustomTitle: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    
    @IBOutlet weak var styleLabelFont: NSTextField!
    @IBOutlet weak var styleButtonFont: NSButton!
    @IBOutlet weak var styleBoxColor: NSBox!
    @IBOutlet weak var styleButtonColor: NSButton!
    @IBOutlet weak var styleButtonUnderline: NSButton!
    @IBOutlet weak var styleButtonItalic: NSButton!
    @IBOutlet weak var styleButtonBold: NSButton!
    @IBOutlet weak var styleButtonSuper: NSButton!
    @IBOutlet weak var styleButtonSub: NSButton!
    @IBOutlet weak var styleRadioLeft: NSButton!
    @IBOutlet weak var styleRadioCenter: NSButton!
    @IBOutlet weak var styleRadioRight: NSButton!
    @IBOutlet weak var styleRadioJustify: NSButton!
    
    @IBOutlet weak var customTitleTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var clipViewContent: NSClipView!
    @IBOutlet var textViewContent: HXTextView!
    
    @IBOutlet weak var backdropBox: NSBox!
    @IBOutlet weak var overlayTopConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        guard let parent = self.parent as? MasterViewController else { return }
        
        textViewContent.parentController = self
        
        findViewController = HXFindViewController(nibName: "HXFindView", bundle: nil)
        self.addChildViewController(findViewController)
        replaceViewController = HXFindReplaceViewController(nibName: "HXFindReplaceView", bundle: nil)
        self.addChildViewController(replaceViewController)
        exportViewController = HXExportViewController(nibName: "HXExportView", bundle: nil)
        self.addChildViewController(exportViewController)
        
        styleLabelFont.alphaValue = 0
        styleButtonFont.alphaValue = 0
        styleBoxColor.alphaValue = 0
        styleButtonColor.alphaValue = 0
        styleButtonUnderline.alphaValue = 0
        styleButtonItalic.alphaValue = 0
        styleButtonSuper.alphaValue = 0
        styleButtonSub.alphaValue = 0
        styleButtonBold.alphaValue = 0
        styleRadioLeft.alphaValue = 0
        styleRadioCenter.alphaValue = 0
        styleRadioRight.alphaValue = 0
        styleRadioJustify.alphaValue = 0
        styleLabelFont.isHidden = true
        styleButtonFont.isHidden = true
        styleBoxColor.isHidden = true
        styleButtonColor.isHidden = true
        styleButtonUnderline.isHidden = true
        styleButtonItalic.isHidden = true
        styleButtonBold.isHidden = true
        styleButtonSuper.isHidden = true
        styleButtonSub.isHidden = true
        styleRadioLeft.isHidden = true
        styleRadioCenter.isHidden = true
        styleRadioRight.isHidden = true
        styleRadioJustify.isHidden = true
        
        customTitleTrailingConstraint.isActive = false
        customTitleTrailingConstraint = labelCustomTitle.trailingAnchor.constraint(equalTo: labelDate.trailingAnchor)
        customTitleTrailingConstraint.isActive = true
        
        backdropBox.alphaValue = 0
        overlayTopConstraint.constant = -parent.splitView_content.frame.height
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        NotificationCenter.default.addObserver(self, selector: #selector(action_customTitleUpdate),
                                               name: .NSControlTextDidEndEditing, object: labelCustomTitle)
        NotificationCenter.default.addObserver(self, selector: #selector(action_customTitleUpdate),
                                               name: .NSControlTextDidChange, object: labelCustomTitle)
        
        NotificationCenter.default.addObserver(self, selector: #selector(action_insertionUpdate),
                                               name: .NSTextViewDidChangeSelection, object: textViewContent)
        NotificationCenter.default.addObserver(self, selector: #selector(action_insertionUpdate),
                                               name: .NSTextViewDidChangeTypingAttributes, object: textViewContent)
//        NotificationCenter.default.addObserver(self, selector: #selector(action_textViewBounds),
//                                               name: .NSViewBoundsDidChange, object: clipViewContent)
        
//        let mainScreen = NSScreen.main()
//        let screenDescrip = mainScreen?.deviceDescription
//        let screenSize = screenDescrip?[NSDeviceSize] as! NSSize
//        let physicalSize = CGDisplayScreenSize(screenDescrip?["NSScreenNumber"] as! CGDirectDisplayID)
//        let scaleFactor = mainScreen?.backingScaleFactor
//        let width = screenSize.width / physicalSize.width * 25.4
//        let height = screenSize.height / physicalSize.height * 25.4
//        print("DPI: \(width), \(height)")
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        // Save model
        if selectedLecture != nil {
            selectedLecture.content = NSAttributedString(attributedString: textViewContent.attributedString())
            (NSApp.delegate as! AppDelegate).saveAction(self)
        }
    }
    
    private weak var selectedLecture: Lecture! {
        didSet {
            
            if selectedLecture == nil {
                return
            }
            
            // Save previous selectedLecture
            if oldValue != nil {
                
                if selectedLecture == oldValue {
                    return
                }
                
                // Changes direction of animation based on higher or lower new lecture number selected
                var signModifier: CGFloat = 1
                if oldValue.number < selectedLecture.number {
                    signModifier = -1
                }
                
                oldValue.content = NSAttributedString(attributedString: textViewContent.attributedString())
                oldValue.title = labelCustomTitle.stringValue.trimmingCharacters(in: .whitespaces)
                
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.2
                NSAnimationContext.current().completionHandler = {
                    
                    self.overlayTopConstraint.constant = signModifier * -self.view.frame.height
                    
                    // Update UI
                    self.labelTitle.stringValue = "Lecture \(self.selectedLecture.number)"
                    self.labelCustomTitle.stringValue = self.selectedLecture.title!
                    let timeYear = self.selectedLecture.course!.semester!.year
                    self.labelDate.stringValue = "\(self.selectedLecture.month)/\(self.selectedLecture.day)/\(timeYear % 100)"
                    self.textViewContent.textStorage?.setAttributedString(self.selectedLecture.content!)
                    
                    self.overlayTopConstraint.animator().constant = 0
                    
                }
                overlayTopConstraint.animator().constant = signModifier * self.view.frame.height
                NSAnimationContext.endGrouping()
                
            } else {
                
                // Update UI
                labelTitle.stringValue = "Lecture \(selectedLecture.number)"
                labelCustomTitle.stringValue = selectedLecture.title!
                let timeYear = selectedLecture.course!.semester!.year
                labelDate.stringValue = "\(selectedLecture.month)/\(selectedLecture.day)/\(timeYear % 100)"
                textViewContent.textStorage?.setAttributedString(selectedLecture.content!)
                
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.4
                self.overlayTopConstraint.animator().constant = 0
                backdropBox.animator().alphaValue = 1
                NSAnimationContext.endGrouping()
            }
        }
    }
    @IBAction func action_closeLecture(_ sender: NSButton) {
        selectionDelegate?.isEditing(lecture: nil)
    }
    
    // MARK: - Page Marking
    
    func action_textViewBounds() {
//        print("textViewContent height: \(textViewContent.bounds.height)")
    }
    
    // MARK: - Update Model
    
    func action_customTitleUpdate() {
        
        tempConfirmDeleteLecture = false
        
        // Check if it has content
        if labelCustomTitle.stringValue == "" {
            labelTitleDivider.alphaValue = 0.3
        } else {
            labelTitleDivider.alphaValue = 1
        }
        // Save to model
        print("labelCustomTitle.stringValue.trimmingCharacters(in: .whitespaces): \(labelCustomTitle.stringValue.trimmingCharacters(in: .whitespaces))")
        if selectedLecture != nil {
            selectedLecture.title = labelCustomTitle.stringValue.trimmingCharacters(in: .whitespaces)
            
            // Notify CourseVC
//            masterVC.notifyRenamed(lecture: selectedLecture)
        }
    }
    
    // MARK: - Updating styling bar
    
    func action_insertionUpdate() {
        
        tempConfirmDeleteLecture = false
        
        if sharedFontManager.selectedFont == nil || textViewContent.attributedString().length == 0 {
            return
        }
        
        let traits = sharedFontManager.traits(of: sharedFontManager.selectedFont!)
        var positionOfSelection = textViewContent.selectedRanges.first!.rangeValue.location
        if positionOfSelection == textViewContent.attributedString().length {
            positionOfSelection = textViewContent.attributedString().length - 1
        }
        
        if textViewContent.attributedString().attribute(NSUnderlineStyleAttributeName, at: positionOfSelection, effectiveRange: nil) != nil {
            styleButtonUnderline.state = NSOnState
        } else {
            styleButtonUnderline.state = NSOffState
        }
        
        styleButtonSuper.state = NSOffState
        styleButtonSub.state = NSOffState
        if let superAttr = textViewContent.attributedString().attribute(NSSuperscriptAttributeName, at: positionOfSelection, effectiveRange: nil) as? Int {
            print("worked!")
            if superAttr == 1 {
                // super
                styleButtonSuper.state = NSOnState
            } else if superAttr == -1 {
                // sub
                styleButtonSub.state = NSOnState
            }
        }
        
        if let color = textViewContent.attributedString().attribute(NSForegroundColorAttributeName, at: positionOfSelection, effectiveRange: nil) as? NSColor {
                styleBoxColor.fillColor = color
        } else if positionOfSelection != 0 {
            if let color = textViewContent.attributedString().attribute(NSForegroundColorAttributeName, at: positionOfSelection - 1, effectiveRange: nil) as? NSColor {
                styleBoxColor.fillColor = color
            } else {
                styleBoxColor.fillColor = NSColor.black
            }
        } else {
            styleBoxColor.fillColor = NSColor.black
        }
        
        if let font = textViewContent.attributedString().attribute(NSFontAttributeName, at: positionOfSelection, effectiveRange: nil) as? NSFont {
            if let name = font.familyName {
                styleLabelFont.stringValue = name
            } else {
                styleLabelFont.stringValue = font.fontName
            }
        }
        
        if let parStyle = textViewContent.attributedString().attribute("NSParagraphStyle", at: positionOfSelection, effectiveRange: nil) as? NSParagraphStyle {
            
            styleRadioLeft.state = NSOffState
            styleRadioCenter.state = NSOffState
            styleRadioRight.state = NSOffState
            styleRadioJustify.state = NSOffState
            
            if parStyle.alignment.rawValue == 0 {
                styleRadioLeft.state = NSOnState
            } else if parStyle.alignment.rawValue == 1 {
                styleRadioRight.state = NSOnState
            } else if parStyle.alignment.rawValue == 2 {
                styleRadioCenter.state = NSOnState
            } else if parStyle.alignment.rawValue == 3 {
                styleRadioJustify.state = NSOnState
            }
        }
        
        if traits.contains(.boldFontMask) {
            styleButtonBold.state = NSOnState
            styleButtonBold.tag = Int(NSFontTraitMask.unboldFontMask.rawValue)
        } else {
            styleButtonBold.state = NSOffState
            styleButtonBold.tag = Int(NSFontTraitMask.boldFontMask.rawValue)
        }
        
        if traits.contains(.italicFontMask) {
            styleButtonItalic.state = NSOnState
            styleButtonItalic.tag = Int(NSFontTraitMask.unitalicFontMask.rawValue)
        } else {
            styleButtonItalic.state = NSOffState
            styleButtonItalic.tag = Int(NSFontTraitMask.italicFontMask.rawValue)
        }
    }
    
    // MARK: - Styling Actions
    
    ///
    @IBAction func action_styleUnderline(_ sender: NSButton) {
        textViewContent.underline(self)
        textViewContent.needsDisplay = true
    }
    @IBAction func action_styleItalicize(_ sender: NSButton) {
        sharedFontManager.addFontTrait(sender)
    }
    @IBAction func action_styleBold(_ sender: NSButton) {
        sharedFontManager.addFontTrait(sender)
    }
    
    
    @IBAction func action_styleSuper(_ sender: NSButton) {
        textViewContent.superscript(self)
        textViewContent.needsDisplay = true
    }
    @IBAction func action_styleSub(_ sender: NSButton) {
        textViewContent.subscript(self)
        textViewContent.needsDisplay = true
    }
    
    ///
    @IBAction func action_styleAlignment(_ sender: NSButton) {
        switch (sender.tag) {
        case 0:
            textViewContent.alignLeft(self)
            break
        case 1:
            textViewContent.alignCenter(self)
            break
        case 2:
            textViewContent.alignRight(self)
            break
        case 3:
            textViewContent.alignJustified(self)
            break
        default: break
        }
    }
    ///
    @IBAction func action_styleFont(_ sender: NSButton) {
        sharedFontManager.orderFrontFontPanel(self)
    }
    ///
    @IBAction func action_styleColor(_ sender: NSButton) {
        NSApp.orderFrontColorPanel(self)
    }
    
    // MARK: - Printing / Exporting / Finding
    
    @IBOutlet weak var dropdownTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var dropdownView: NSView!
    
    var findViewController: HXFindViewController!
    var exportViewController: HXExportViewController!
    var replaceViewController: HXFindReplaceViewController!
    
    /// Reveal or hide the top bar container.
    func topBarShown(_ visible: Bool) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        NSAnimationContext.current().duration = 0.25
        if visible {
            NSAnimationContext.current().completionHandler = {
                // If showing top bar and isFind or isReplace, then set firstResponders
                if self.isReplacing {
                    NSApp.keyWindow?.makeFirstResponder(self.replaceViewController.textField_find)
                } else if self.isFinding {
                    NSApp.keyWindow?.makeFirstResponder(self.findViewController.textField_find)
                }
            }
            dropdownTopConstraint.animator().constant = 0
        } else {
            NSAnimationContext.current().completionHandler = {
                // Make sure all the VC's views are removed from their supers.
                if self.exportViewController.view.superview != nil && !self.isExporting {
                    self.exportViewController.view.removeFromSuperview()
                } else if self.replaceViewController.view.superview != nil && !self.isReplacing {
                    self.replaceViewController.view.removeFromSuperview()
                } else if self.findViewController.view.superview != nil && !self.isFinding {
                    self.findViewController.view.removeFromSuperview()
                } // add for printVC
                
                if self.isFinding {
                    self.isFinding = true
                } else if self.isPrinting {
                    self.isPrinting = true
                } else if self.isReplacing {
                    self.isReplacing = true
                } else if self.isExporting {
                    self.isExporting = true
                }
            }
            dropdownTopConstraint.animator().constant = -dropdownView.frame.height
        }
        NSAnimationContext.endGrouping()
    }
    
    /// Toggles reveal or hide of top bar container.
    func topBarShown() {
        if dropdownTopConstraint.constant == 0 {
            topBarShown(false)
        } else {
            topBarShown(true)
        }
    }
    
    /// Produces a formatted RTFD file and places it at the provided URL.
    func export(to url: URL){
        let attribString = NSMutableAttributedString()
        // Combine all data from every lecture
//        for case let lecture as Lecture in selectedCourse.lectures! {
            //            attribString
//        }
        
        //        for case let lectureController as LectureViewController in self.childViewControllers {
        //            attribString.append(lectureController.label_lectureTitle.attributedStringValue)
        //            if lectureController.label_customTitle.stringValue != "" {
        //                attribString.append(NSAttributedString(string: "  -  " + lectureController.label_customTitle.stringValue + "\n"))
        //            } else {
        //                attribString.append(NSAttributedString(string: "\n"))
        //            }
        //            attribString.append(NSAttributedString(string: lectureController.label_lectureDate.stringValue + "\n\n"))
        //            attribString.append(lectureController.textView_lecture.attributedString())
        //            attribString.append(NSAttributedString(string: "\n\n\n"))
        //        }
        
        let fullRange = NSRange(location: 0, length: attribString.length)
        do {
            let data = try attribString.fileWrapper(from: fullRange, documentAttributes: [NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType])
            try data.write(to: url, options: .atomic, originalContentsURL: nil) // this for rtfd
        } catch {
            print("Something went wrong.")
        }
    }
    
    var isPrinting = false {
        didSet {
            
        }
    }
    
    var isFinding = false {
        didSet {
            if isFinding && (isExporting || isPrinting || isReplacing) {
                if isExporting {
                    isExporting = false
                } else if isPrinting {
                    isPrinting = false
                } else {
                    isReplacing = false
                }
            } else if isFinding {
                dropdownView.addSubview(findViewController.view)
                findViewController.view.leadingAnchor.constraint(equalTo: dropdownView.leadingAnchor).isActive = true
                findViewController.view.trailingAnchor.constraint(equalTo: dropdownView.trailingAnchor).isActive = true
                findViewController.view.topAnchor.constraint(equalTo: dropdownView.topAnchor).isActive = true
                findViewController.view.bottomAnchor.constraint(equalTo: dropdownView.bottomAnchor).isActive = true
                
                topBarShown(true)
            } else {
                if NSApp.keyWindow?.firstResponder == findViewController.textField_find {
                    NSApp.keyWindow?.makeFirstResponder(self)
                }
                topBarShown(false)
            }
        }
    }
    
    var isReplacing = false {
        didSet {
            if isReplacing && (isExporting || isPrinting || isFinding) {
                if isExporting {
                    isExporting = false
                } else if isPrinting {
                    isPrinting = false
                } else {
                    isFinding = false
                }
            } else if isReplacing {
                dropdownView.addSubview(replaceViewController.view)
                replaceViewController.view.leadingAnchor.constraint(equalTo: dropdownView.leadingAnchor).isActive = true
                replaceViewController.view.trailingAnchor.constraint(equalTo: dropdownView.trailingAnchor).isActive = true
                replaceViewController.view.topAnchor.constraint(equalTo: dropdownView.topAnchor).isActive = true
                replaceViewController.view.bottomAnchor.constraint(equalTo: dropdownView.bottomAnchor).isActive = true
                
                topBarShown(true)
            } else {
                if NSApp.keyWindow?.firstResponder == replaceViewController.textField_find || NSApp.keyWindow?.firstResponder == replaceViewController.textField_replace {
                    NSApp.keyWindow?.makeFirstResponder(self)
                }
                topBarShown(false)
            }
        }
    }
    
    var isExporting = false {
        didSet {
            if isExporting && (isFinding || isPrinting || isReplacing) {
                if isFinding {
                    isFinding = false
                } else if isPrinting {
                    isPrinting = false
                } else {
                    isReplacing = false
                }
            } else if isExporting {
                dropdownView.addSubview(exportViewController.view)
                exportViewController.view.leadingAnchor.constraint(equalTo: dropdownView.leadingAnchor).isActive = true
                exportViewController.view.trailingAnchor.constraint(equalTo: dropdownView.trailingAnchor).isActive = true
                exportViewController.view.topAnchor.constraint(equalTo: dropdownView.topAnchor).isActive = true
                exportViewController.view.bottomAnchor.constraint(equalTo: dropdownView.bottomAnchor).isActive = true
                
                // Scroll to top
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.5
                //                lectureClipper.animator().setBoundsOrigin(NSPoint(x: 0, y: 0))
                NSAnimationContext.endGrouping()
                
                topBarShown(true)
            } else {
                if NSApp.keyWindow?.firstResponder == exportViewController.textField_name {
                    NSApp.keyWindow?.makeFirstResponder(self)
                }
                topBarShown(false)
            }
        }
    }
    
    // MARK: - Notifiers
    
    func notifySelected(lecture: Lecture) {
        selectedLecture = lecture
    }
    
    func notifyContentFocus(is focused: Bool) {
        if focused {
            
            styleLabelFont.isHidden = false
            styleButtonFont.isHidden = false
            styleBoxColor.isHidden = false
            styleButtonColor.isHidden = false
            styleButtonUnderline.isHidden = false
            styleButtonItalic.isHidden = false
            styleButtonBold.isHidden = false
            styleButtonSuper.isHidden = false
            styleButtonSub.isHidden = false
            styleRadioLeft.isHidden = false
            styleRadioCenter.isHidden = false
            styleRadioRight.isHidden = false
            styleRadioJustify.isHidden = false
            
            customTitleTrailingConstraint.isActive = false
            customTitleTrailingConstraint = labelCustomTitle.trailingAnchor.constraint(equalTo: styleLabelFont.leadingAnchor)
            customTitleTrailingConstraint.isActive = true
            
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.3
            styleLabelFont.animator().alphaValue = 1
            styleButtonFont.animator().alphaValue = 1
            styleBoxColor.animator().alphaValue = 1
            styleButtonColor.animator().alphaValue = 1
            styleButtonUnderline.animator().alphaValue = 1
            styleButtonItalic.animator().alphaValue = 1
            styleButtonBold.animator().alphaValue = 1
            styleButtonSuper.animator().alphaValue = 1
            styleButtonSub.animator().alphaValue = 1
            styleRadioLeft.animator().alphaValue = 1
            styleRadioCenter.animator().alphaValue = 1
            styleRadioRight.animator().alphaValue = 1
            styleRadioJustify.animator().alphaValue = 1
            NSAnimationContext.endGrouping()
            
        } else {
            
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.3
            NSAnimationContext.current().completionHandler = {
                self.customTitleTrailingConstraint.isActive = false
                self.customTitleTrailingConstraint = self.labelCustomTitle.trailingAnchor.constraint(equalTo: self.labelDate.leadingAnchor)
                self.customTitleTrailingConstraint.isActive = true
                
                self.styleLabelFont.isHidden = true
                self.styleButtonFont.isHidden = true
                self.styleBoxColor.isHidden = true
                self.styleButtonColor.isHidden = true
                self.styleButtonUnderline.isHidden = true
                self.styleButtonItalic.isHidden = true
                self.styleButtonBold.isHidden = true
                self.styleButtonSuper.isHidden = true
                self.styleButtonSub.isHidden = true
                self.styleRadioLeft.isHidden = true
                self.styleRadioCenter.isHidden = true
                self.styleRadioRight.isHidden = true
                self.styleRadioJustify.isHidden = true
            }
            styleLabelFont.animator().alphaValue = 0
            styleButtonFont.animator().alphaValue = 0
            styleBoxColor.animator().alphaValue = 0
            styleButtonColor.animator().alphaValue = 0
            styleButtonUnderline.animator().alphaValue = 0
            styleButtonItalic.animator().alphaValue = 0
            styleButtonBold.animator().alphaValue = 0
            styleButtonSuper.animator().alphaValue = 0
            styleButtonSub.animator().alphaValue = 0
            styleRadioLeft.animator().alphaValue = 0
            styleRadioCenter.animator().alphaValue = 0
            styleRadioRight.animator().alphaValue = 0
            styleRadioJustify.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
        }
    }
    
    // MARK: - TEMP TESTING -
    
    var tempConfirmDeleteLecture = false
    
    @IBAction func temp_action_removeLecture(_ sender: NSButton) {
        if selectedLecture != nil {
            if tempConfirmDeleteLecture {
                tempConfirmDeleteLecture = false
                let lecToRemove = selectedLecture
                selectedLecture = nil
                appDelegate.managedObjectContext.delete( lecToRemove! )
                appDelegate.saveAction(self)
                selectionDelegate?.isEditing(lecture: nil)
            } else {
                tempConfirmDeleteLecture = true
            }
        }
    }
    
}
