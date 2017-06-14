//
//  EditorViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/2/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class EditorViewController: NSViewController {
    
    var masterViewController: MasterViewController!

    // MARK: View References
    @IBOutlet weak var lectureStack: NSStackView!
    @IBOutlet weak var lectureLedgerStack: NSStackView!
    @IBOutlet weak var lectureBottomBufferView: HXBottomBufferView!
    @IBOutlet weak var lectureScroller: NSScrollView!
    @IBOutlet weak var lectureClipper: HXFlippedClipView!
    var oldClipperHeight: CGFloat = 0
    // These 2 labels are displayed when no course is selected
    @IBOutlet weak var labelNoCourse: NSTextField!
    @IBOutlet weak var subLabelNoCourse: NSTextField!    
    
    // This constraint is for an invisible view at the bottom of lecture stack to allow user to scroll
    // enough for the last lecture's textView to be in middle of screen.
    @IBOutlet weak var lectureBottomConstraint: NSLayoutConstraint!
    
    // MARK: Object models
    
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    let sharedFontManager = NSFontManager.shared()
    var selectedCourse: Course! {
        didSet {
            if masterViewController.isExporting {
                masterViewController.isExporting = false
            } else if masterViewController.isPrinting {
                masterViewController.isPrinting = false
            } else if masterViewController.isFinding {
                masterViewController.isFinding = false
            }
            // Setting selectedCourse, immediately updates visuals
            if selectedCourse != nil {
                // Populate new lecture visuals
                loadLectures(from: selectedCourse)
            } else {
                labelNoCourse.stringValue = "No Course Selected"
                subLabelNoCourse.stringValue = "Courses are selectable to the left."
                // Animate hiding the lecture
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().completionHandler = {
                    if self.selectedCourse == nil {
                        self.popLectures()
                    }
                }
                NSAnimationContext.current().duration = 0.25
                stickyHeaderBox.animator().alphaValue = 0
                lectureScroller.animator().alphaValue = 0
                NSAnimationContext.current().duration = 0.4
                labelNoCourse.animator().alphaValue = 1
                subLabelNoCourse.animator().alphaValue = 1
                NSAnimationContext.endGrouping()
            }
        }
    }
    
    // MARK: Initialize editorViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stickyHeaderBox.alphaValue = 0
        lectureScroller.alphaValue = 0
        
        // Setup observers for scrolling lectures
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.didLiveScroll),
                                               name: .NSScrollViewDidLiveScroll, object: lectureScroller)
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.didScroll),
                                               name: .NSViewBoundsDidChange, object: lectureClipper)
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.notifyCustomTitleUpdate),
                                               name: .NSControlTextDidEndEditing, object: stickyHeaderCustomTitle)
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.notifyCustomTitleChange),
                                               name: .NSControlTextDidChange, object: stickyHeaderCustomTitle)
        
        stickyHeaderCustomTitle.parentController = self
        
        button_style_underline.alphaValue = 0
        button_style_italicize.alphaValue = 0
        button_style_bold.alphaValue = 0
        button_style_left.alphaValue = 0
        button_style_center.alphaValue = 0
        button_style_right.alphaValue = 0
        
        NSApp.keyWindow?.makeFirstResponder(self)
        NSApp.keyWindow?.initialFirstResponder = self.view
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        
        NSApp.keyWindow?.makeFirstResponder(nil)
        
        lectureBottomBufferView.initialize(owner: self)
    }
    override func viewDidLayout() {
        super.viewDidLayout()

        didScroll()
    }
    // MARK: Load object models ..........................................................................................
    /// Internal usage only. Reach this function by setting selectedCourse.
    private func loadLectures(from course: Course) {
        self.popLectures()
        for case let lecture as Lecture in course.lectures! {
            pushLecture( lecture )
        }
        if course.lectures!.count == 0 {
            labelNoCourse.stringValue = "No Lecture Data"
            subLabelNoCourse.stringValue = "Open HXNotes during an input class period."
            
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.4
            labelNoCourse.animator().alphaValue = 1
            subLabelNoCourse.animator().alphaValue = 1
            stickyHeaderBox.animator().alphaValue = 0
            lectureScroller.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
        } else {
            notifyHeightUpdate()
            
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.5
            stickyHeaderBox.animator().alphaValue = 1
            lectureScroller.animator().alphaValue = 1
            labelNoCourse.animator().alphaValue = 0
            subLabelNoCourse.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
        }
    }
    
    // MARK: Populating stacks ...........................................................................................
    /// Creates a Lecture object for the currently selected course, and pushes an HXLectureLedger plus HXLectureView
    /// to their appropriate stacks.
    private func addLecture(_ lecture: Lecture) {
        
        pushLecture( lecture )
        
    }
    /// Handles purely the visual aspect of lectures. Populates lectureStack.
    private func pushLecture(_ lecture: Lecture) {
        let newController = LectureViewController(nibName: "HXLectureView", bundle: nil)!
        self.addChildViewController(newController)
        lectureStack.insertArrangedSubview(newController.view, at: lectureStack.arrangedSubviews.count - 1)
        newController.initialize(with: lecture)
        // Animate showing the lecture
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        NSAnimationContext.current().duration = 0.5
        lectureScroller.animator().alphaValue = 1
        labelNoCourse.animator().alphaValue = 0
        subLabelNoCourse.animator().alphaValue = 0
        NSAnimationContext.endGrouping()
    }
    /// Handles purely the visual aspect of lectures. Resets lectureLedgerStack, lectureStack, selectedCourse.lectures!.count, and weekCount
    private func popLectures() {
        for case let lectureController as LectureViewController in self.childViewControllers {
            lectureController.view.removeFromSuperview()
            lectureController.removeFromParentViewController()
        }
        lectureClipper.bounds.origin.y = 0
    }
    
    // MARK: Scroll functionality
    /// Comes from the LectureLedger stack, scrolls to supplied lecture number. Lecture guaranteed to exist.
    private func scrollToLecture(_ lecture: String) {
        for case let lectureController as LectureViewController in self.childViewControllers {
            if lectureController.label_lectureTitle.stringValue == lecture {
                NSApp.keyWindow?.makeFirstResponder(lectureController.textView_lecture)
                let yPos = lectureStack.frame.height - lectureController.view.frame.origin.y - lectureController.view.frame.height
                // Animate scroll to lecture
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.5
                lectureClipper.animator().setBoundsOrigin(NSPoint(x: 0, y: yPos))
                NSAnimationContext.endGrouping()
                break
            }
        }
    }
    /// This is called by the users scrolling versus didScroll is called by lectureClipper bounds change.
    /// Distinguished here since user scrolling should cancel any scroll animations. Else the clipper stutters.
    func didLiveScroll() {
        // Stop any scrolling animations currently happening on the clipper
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0 // This overwrites animator proxy object with 0 duration aimation
        lectureClipper.animator().setBoundsOrigin(NSPoint(x: 0, y: lectureClipper.bounds.origin.y))
        NSAnimationContext.endGrouping()
        // Then call didScroll as normal to produce stickyheader effect
        didScroll()
    }
    /// Receives scrolling from lectureScroller NSScrollView and any time clipper changes its bounds.
    /// Is responsible for updating the StickyHeaderBox to simulate the iOS effect of lecture titles
    /// staying at the top of scrollView.
    func didScroll() {
        // didScroll should only be called when the origin.y changes, not the height
        if oldClipperHeight == lectureClipper.bounds.height {
            
        }
        let clipperYPos = lectureClipper.bounds.origin.y
        // The y positions of each view in the stackview can be found by adding the heights of the previous views. Assumes zero spacing.
        var accumulatedHeight: CGFloat = 0
        // Should go through one more iteration after finding the last visible element in stack.
        var foundLowestLecture = false
        for case let lectureController as LectureViewController in self.childViewControllers {
            // Skip updating sticky header title and date if it was the last visible element in stack.
            if !foundLowestLecture {
                // If scroller is using elastic effect don't proceed past first element
                if clipperYPos < 0 {
                    if stickyHeaderCustomTitle.isFocused {
                        lectureController.notifyCustomTitleFocus(true)
                    }
                    stickyHeaderLectureViewController = nil
                    return
                }
                let height = lectureController.view.bounds.height
                accumulatedHeight = accumulatedHeight + height
                // Since the last visible element in stack is not found yet, check if this element is visible still.
                if clipperYPos <= accumulatedHeight {
                    // It is visible so update sticky header VC and dump out of loop after one more iteration
                    if stickyHeaderLectureViewController != lectureController {
                        // Only update stickyHeaderLectureViewController when its a new LectureVC
                        stickyHeaderLectureViewController = lectureController
                    }
                    foundLowestLecture = true
                }
                if self.childViewControllers.last == lectureController {
                    // The last view controller should set its constant to 0 in this iteraiton
                    stickyHeaderTopConstraint.constant = 0
                }
            } else {
                // Check how close the next element is to determine if stickyheader should be pushed aside
                if (clipperYPos + stickyHeaderBox.bounds.height) > (accumulatedHeight) {
                    // Next element is encroaching on header so shift by Y difference
                    stickyHeaderTopConstraint.constant = accumulatedHeight - (clipperYPos + stickyHeaderBox.bounds.height)
                } else {
                    // Next element not encroaching so reset Y to 0.
                    stickyHeaderTopConstraint.constant = 0
                }
                // Stop iterating through controller views
                break
            }
        }
    }
    func bottomBufferClicked() {
        for case let lectureVC as LectureViewController in self.childViewControllers {
            if lectureVC.label_lectureTitle.stringValue == "Lecture \(selectedCourse.lectures!.count)" {
                NSApp.keyWindow?.makeFirstResponder(lectureVC.textView_lecture)
                lectureVC.textView_lecture.setSelectedRange(NSMakeRange((lectureVC.textView_lecture.string?.characters.count)!, 0))
            }
        }
    }
    
    @IBAction func action_customTitle(_ sender: NSTextField) {
        NSApp.keyWindow?.makeFirstResponder(self)
    }
    
    // MARK: Notifiers
    func notifyCustomTitleStartEditing() {
        if stickyHeaderLectureViewController != nil {
            if !stickyHeaderLectureViewController.isTitling {
                stickyHeaderLectureViewController.isTitling = true
            }
        }
    }
    
    func notifyCustomTitleChange() {
        if customTitleFocused != nil {
            customTitleFocused.label_customTitle.stringValue = stickyHeaderCustomTitle.stringValue
        } else {
        }
        if stickyHeaderCustomTitle.stringValue == "" {
            stickyHeaderDivider.alphaValue = 0.3
        } else {
            stickyHeaderDivider.alphaValue = 1
        }
    }
    
    func notifyCustomTitleUpdate() {
        if stickyHeaderLectureViewController != nil {
            stickyHeaderLectureViewController.isTitling = false
            stickyHeaderCustomTitle.stringValue = stickyHeaderCustomTitle.stringValue.trimmingCharacters(in: .whitespaces)
            // If customTitleFocused is nil and this function just got called, it implies that the StickyHeader's
            // customTitle textfield has just finished editing. Need to find current stickyheadered lecture.
            if customTitleFocused == nil {
                for case let lectureController as LectureViewController in self.childViewControllers {
                    if lectureController.label_lectureTitle.stringValue == stickyHeaderTitle.stringValue {
                        lectureController.label_customTitle.stringValue = stickyHeaderCustomTitle.stringValue
                        lectureController.notifyCustomTitleEndEditing()
                    }
                }
            } else {
                customTitleFocused.label_customTitle.stringValue = stickyHeaderCustomTitle.stringValue
                customTitleFocused.notifyCustomTitleEndEditing()
                customTitleFocused = nil
            }
            // Check if it has content
            if stickyHeaderCustomTitle.stringValue == "" {
                stickyHeaderDivider.alphaValue = 0.3
            } else {
                stickyHeaderDivider.alphaValue = 1
            }
        }
    }
    /// Received from LectureViewController on any change to a given lecture text view. Resizes the bottom buffer box
    internal func notifyHeightUpdate() {
        // Get last view in lectureStack
        if let lectureController = childViewControllers.filter({$0 is LectureViewController})[selectedCourse.lectures!.count - 1] as?LectureViewController {
            // Resize last lecture to keep text in the center of screen.
            if lectureController.view.frame.height < lectureScroller.frame.height/2 + 3 {
                lectureBottomConstraint.constant = -lectureController.view.frame.height
            } else {
                lectureBottomConstraint.constant = -lectureScroller.frame.height/2 - 3
            }
        }
    }
    /// Auto scrolling whenever user types. Smoothly scroll clipper until text typing location is centered.
    internal func checkScrollLevel(from sender: LectureViewController) {
        if sender.isStyling {
            let selectionY = sender.textSelectionHeight()
            // Center current typing position to center of lecture scroller
            let yPos = lectureStack.frame.height - selectionY // - lectureScroller.frame.height/2
            // Don't auto-scroll if selection is already visible and above center line of window
            if yPos < (lectureClipper.bounds.origin.y + stickyHeaderBox.frame.height) || yPos > (lectureClipper.bounds.origin.y + lectureScroller.frame.height/2) {
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.5
                // Get clipper to center selection in scroller
                lectureClipper.animator().setBoundsOrigin(NSPoint(x: 0, y: yPos - lectureScroller.frame.height/2))
                NSAnimationContext.endGrouping()
            }
        }
    }
    
    func notifyLectureAddition(lecture: Lecture) {
        addLecture(lecture)
        
        notifyHeightUpdate()
        
        scrollToLecture("Lecture \(lecture.number)")
    }
    func notifyLectureSelection(lecture: String) {
        scrollToLecture(lecture)
    }
    
    func notifyFind() {
        if selectedCourse != nil {
            if lectureFocused != nil {
                lectureFocused.isFinding = !lectureFocused.isFinding
            } else {
                masterViewController.isFinding = !masterViewController.isFinding
            }
        }
    }
    func notifyFindAndReplace() {
        if selectedCourse != nil {
            if lectureFocused != nil {
                lectureFocused.isReplacing = !lectureFocused.isReplacing
            } else {
                masterViewController.isReplacing = !masterViewController.isReplacing
            }
        }
    }
    func notifyPrint() {
        if selectedCourse != nil {
            if lectureFocused != nil {
                
            } else {
                masterViewController.isPrinting = !masterViewController.isPrinting
            }
        }
    }
    func notifyExport() {
        if selectedCourse != nil {
            if lectureFocused != nil {
                lectureFocused.isExporting = !lectureFocused.isExporting
            } else {
                masterViewController.isExporting = !masterViewController.isExporting
            }
        }
    }
    
    // MARK: Find, Print, Export Functions
    @IBAction func actionTest_find(_ sender: NSTextField) {
        find(str: sender.stringValue, allLectures: true, includeTitles: true)
    }
    /// If allLectures is true, will search through all lectures together.
    /// If allLectures is false, will search through currently focused lecture.
    /// If includeTitles is true, will also search the lecture header titles. NYI
    func find(str: String, allLectures: Bool, includeTitles: Bool) {
        print("Running a find on '\(str)'")
        if allLectures {
            // Go through each lecture individually to find word
            var foundCount = 0
            for case let lectureController as LectureViewController in self.childViewControllers {
                var thisStr = lectureController.textView_lecture.string!.lowercased()
                var found = thisStr.range(of: str.lowercased())
                while found != nil {
                    foundCount = foundCount + 1
                    thisStr = thisStr.substring(from: found!.upperBound)
                    found = thisStr.range(of: str.lowercased())
                }
            }
            print("    Found: \(foundCount)")
        } else {
            // Go through selected lecture to find word
            
        }
    }
    ///
    func exportLectures(to url: URL){
        let attribString = NSMutableAttributedString()
        // Combine all data from every lecture
        for case let lectureController as LectureViewController in self.childViewControllers {
            attribString.append(lectureController.label_lectureTitle.attributedStringValue)
            if lectureController.label_customTitle.stringValue != "" {
                attribString.append(NSAttributedString(string: "  -  " + lectureController.label_customTitle.stringValue + "\n"))
            } else {
                attribString.append(NSAttributedString(string: "\n"))
            }
            attribString.append(NSAttributedString(string: lectureController.label_lectureDate.stringValue + "\n\n"))
            attribString.append(lectureController.textView_lecture.attributedString())
            attribString.append(NSAttributedString(string: "\n\n\n"))
        }
        export(content: attribString, to: url)
    }
    ///
    func exportLecture(from lecture: LectureViewController, to url: URL) {
        let attribString = NSMutableAttributedString()
        // Use currently focused lecture
        attribString.append(lecture.label_lectureTitle.attributedStringValue)
        if lecture.label_customTitle.stringValue != "" {
            attribString.append(NSAttributedString(string: "  -  " + lecture.label_customTitle.stringValue + "\n"))
        } else {
            attribString.append(NSAttributedString(string: "\n"))
        }
        attribString.append(NSAttributedString(string: lecture.label_lectureDate.stringValue + "\n\n"))
        attribString.append(lecture.textView_lecture.attributedString())
        export(content: attribString, to: url)
    }
    ///
    private func export(content: NSAttributedString, to url: URL) {
        let fullRange = NSRange(location: 0, length: content.length)
        do {
            let data = try content.fileWrapper(from: fullRange, documentAttributes: [NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType])
            try data.write(to: url, options: .atomic, originalContentsURL: nil) // this for rtfd
        } catch {
            print("Something went wrong.")
        }
    }
    // EXPORT AND PRINT should get file data from same place
    func printAllLectures() {
        if lectureFocused != nil {
            lectureFocused.textView_lecture.print(self)
            
        }
    }
    
    // MARK: Sticky Header Functionality ....................................................................
    var stickyHeaderLectureViewController: LectureViewController! {
        didSet {
            if stickyHeaderLectureViewController != nil {
                stickyHeaderBox.alphaValue = 1
                stickyHeaderTitle.stringValue = stickyHeaderLectureViewController.label_lectureTitle.stringValue
                stickyHeaderDate.stringValue = stickyHeaderLectureViewController.label_lectureDate.stringValue
                stickyHeaderCustomTitle.stringValue = stickyHeaderLectureViewController.label_customTitle.stringValue
                if stickyHeaderCustomTitle.stringValue == "" {
                    stickyHeaderDivider.alphaValue = 0.3
                } else {
                    stickyHeaderDivider.alphaValue = 1
                }
                stickyHeaderCustomTitleTrailingConstraint.isActive = false
                if stickyHeaderLectureViewController.isStyling {
                    button_style_underline.alphaValue = 1
                    button_style_italicize.alphaValue = 1
                    button_style_bold.alphaValue = 1
                    button_style_left.alphaValue = 1
                    button_style_center.alphaValue = 1
                    button_style_right.alphaValue = 1
                    stickyHeaderCustomTitleTrailingConstraint = stickyHeaderCustomTitle.trailingAnchor.constraint(equalTo: button_style_underline.leadingAnchor)
                } else {
                    button_style_underline.alphaValue = 0
                    button_style_italicize.alphaValue = 0
                    button_style_bold.alphaValue = 0
                    button_style_left.alphaValue = 0
                    button_style_center.alphaValue = 0
                    button_style_right.alphaValue = 0
                    stickyHeaderCustomTitleTrailingConstraint = stickyHeaderCustomTitle.trailingAnchor.constraint(equalTo: stickyHeaderDate.leadingAnchor)
                }
                stickyHeaderCustomTitleTrailingConstraint.isActive = true
                if stickyHeaderLectureViewController.isTitling {
                    if !stickyHeaderCustomTitle.isFocused {
                        NSApp.keyWindow?.makeFirstResponder(stickyHeaderCustomTitle)
                    }
                } else if customTitleFocused != nil {
                    if customTitleFocused == stickyHeaderLectureViewController {
                        if !stickyHeaderCustomTitle.isFocused {
                            NSApp.keyWindow?.makeFirstResponder(stickyHeaderCustomTitle)
                        } else {
//                            NSApp.keyWindow?.makeFirstResponder(self)
                        }
                        
                    }
                }
            } else {
                stickyHeaderBox.alphaValue = 0
            }
            
        }
    }
    
    // When a textView is focused, the styling buttons appear which should truncate the lecture's custom title.
    @IBOutlet weak var stickyHeaderCustomTitleTrailingConstraint: NSLayoutConstraint!
    // StickyHeader can be shifted as the next/previous lecture encroaches on the stickyHeader.
    @IBOutlet weak var stickyHeaderTopConstraint: NSLayoutConstraint!
    
    
    var lectureFocused: LectureViewController! {
        didSet {
            stickyHeaderCustomTitleTrailingConstraint.isActive = false
            // Check first if a lecture's textView is focused on at the moment
            if lectureFocused != nil {
                // Lecture is focused, notify masterVC
                masterViewController.notifyLectureFocus(is: lectureFocused.lecture)
                // Check if lecture focused is the same as StickyHeaders LectureVC
                if stickyHeaderLectureViewController != nil {
                    if stickyHeaderLectureViewController == lectureFocused {
                        // Animate revealing the styling buttons on stickyHeader
                        NSAnimationContext.beginGrouping()
                        NSAnimationContext.current().duration = 1
                        button_style_underline.animator().alphaValue = 1
                        button_style_italicize.animator().alphaValue = 1
                        button_style_bold.animator().alphaValue = 1
                        button_style_left.animator().alphaValue = 1
                        button_style_center.animator().alphaValue = 1
                        button_style_right.animator().alphaValue = 1
                        NSAnimationContext.endGrouping()
                        stickyHeaderCustomTitleTrailingConstraint = stickyHeaderCustomTitle.trailingAnchor.constraint(equalTo: button_style_underline.leadingAnchor)
                    } else {
                        stickyHeaderCustomTitleTrailingConstraint = stickyHeaderCustomTitle.trailingAnchor.constraint(equalTo: stickyHeaderDate.leadingAnchor)
                    }
                } else {
                    // StickyHeaders LectureVC is not focused, hide styling buttons
                    // Animate hiding style buttons
                    NSAnimationContext.beginGrouping()
                    NSAnimationContext.current().duration = 0.25
                    button_style_underline.animator().alphaValue = 0
                    button_style_italicize.animator().alphaValue = 0
                    button_style_bold.animator().alphaValue = 0
                    button_style_left.animator().alphaValue = 0
                    button_style_center.animator().alphaValue = 0
                    button_style_right.animator().alphaValue = 0
                    NSAnimationContext.endGrouping()
                    stickyHeaderCustomTitleTrailingConstraint = stickyHeaderCustomTitle.trailingAnchor.constraint(equalTo: stickyHeaderDate.leadingAnchor)
                }
            } else {
                // StickyHeaders LectureVC is not focused, hide styling buttons
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.25
                button_style_underline.animator().alphaValue = 0
                button_style_italicize.animator().alphaValue = 0
                button_style_bold.animator().alphaValue = 0
                button_style_left.animator().alphaValue = 0
                button_style_center.animator().alphaValue = 0
                button_style_right.animator().alphaValue = 0
                NSAnimationContext.endGrouping()
                stickyHeaderCustomTitleTrailingConstraint = stickyHeaderCustomTitle.trailingAnchor.constraint(equalTo: stickyHeaderDate.leadingAnchor)
                // No lecture is focused, notify masterVC
                masterViewController.notifyLectureFocus(is: nil)
            }
            stickyHeaderCustomTitleTrailingConstraint.isActive = true
        }
    }
    
    // For StickyHeader to transfer custom title editing state appropriately, need to keep track of
    // when a custom title is being set on a lecture.
    var customTitleFocused: LectureViewController! {
        didSet {
            // Check if user isTitling a lectureVC
            if customTitleFocused != nil {
                if stickyHeaderLectureViewController != nil {
                    if stickyHeaderLectureViewController == customTitleFocused {
                        if !stickyHeaderCustomTitle.isFocused {
                            NSApp.keyWindow?.makeFirstResponder(stickyHeaderCustomTitle)
                        }
                    }
//                    NSApp.keyWindow?.makeFirstResponder(stickyHeaderCustomTitle)
                } else {
//                    if stickyHeaderCustomTitle.isFocused {
//                        print("4")
//                        NSApp.keyWindow?.makeFirstResponder(self)
//                    }
                }
            }
        }
    }
    
    @IBOutlet weak var stickyHeaderBox: NSBox!
    @IBOutlet weak var stickyHeaderTitle: NSTextField!
    @IBOutlet weak var stickyHeaderDate: NSTextField!
    @IBOutlet weak var stickyHeaderDivider: NSTextField!
    @IBOutlet weak var stickyHeaderCustomTitle: HXStickyCustomTitleField!
    
    @IBOutlet weak var button_style_underline: NSButton!
    @IBOutlet weak var button_style_italicize: NSButton!
    @IBOutlet weak var button_style_bold: NSButton!
    @IBOutlet weak var button_style_left: NSButton!
    @IBOutlet weak var button_style_center: NSButton!
    @IBOutlet weak var button_style_right: NSButton!
    
    @IBAction func action_styleUnderline(_ sender: NSButton) {
        if lectureFocused != nil {
            lectureFocused.action_styleUnderline(sender)
        }
    }
    @IBAction func action_styleItalicize(_ sender: NSButton) {
        if lectureFocused != nil {
            lectureFocused.action_styleItalicize(sender)
        }
    }
    @IBAction func action_styleBold(_ sender: NSButton) {
        if lectureFocused != nil {
            lectureFocused.action_styleBold(sender)
        }
    }
    @IBAction func action_styleLeft(_ sender: NSButton) {
        if lectureFocused != nil {
            lectureFocused.action_styleLeft(sender)
        }
    }
    @IBAction func action_styleCenter(_ sender: NSButton) {
        if lectureFocused != nil {
            lectureFocused.action_styleCenter(sender)
        }
    }
    @IBAction func action_styleRight(_ sender: NSButton) {
        if lectureFocused != nil {
            lectureFocused.action_styleRight(sender)
        }
    }
    
    func textSelectionChange(with traits: NSFontTraitMask, underlined: Bool, alignment: Int) {
        if underlined {
            button_style_underline.state = NSOnState
        } else {
            button_style_underline.state = NSOffState
        }
        
        button_style_left.state = NSOffState
        button_style_center.state = NSOffState
        button_style_right.state = NSOffState
        
        if alignment == 0 {
            button_style_left.state = NSOnState
        } else if alignment == 1 {
            button_style_right.state = NSOnState
        } else if alignment == 2 {
            button_style_center.state = NSOnState
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
    }
}
