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
    @IBOutlet weak var lectureBottomBufferView: HXBottomBufferView!
    @IBOutlet weak var lectureScroller: NSScrollView!
    @IBOutlet weak var lectureClipper: HXFlippedClipView!
    var oldClipperHeight: CGFloat = 0
    // These 2 labels are displayed when no course is selected
    @IBOutlet weak var labelNoCourse: NSTextField!
    @IBOutlet weak var subLabelNoCourse: NSTextField!    
    @IBOutlet weak var dropdownView: NSView!
    @IBOutlet weak var dropdownTopConstraint: NSLayoutConstraint!
    
    // This constraint is for an invisible view at the bottom of lecture stack to allow user to scroll
    // enough for the last lecture's textView to be in middle of screen.
    @IBOutlet weak var lectureBottomConstraint: NSLayoutConstraint!
    
    // MARK: Object models
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    let sharedFontManager = NSFontManager.shared()
    var selectedCourse: Course! {
        didSet {
            if isExporting {
                isExporting = false
            } else if isPrinting {
                isPrinting = false
            } else if isFinding {
                isFinding = false
            } else if isReplacing {
                isReplacing = false
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
                lectureScroller.animator().alphaValue = 0
                NSAnimationContext.current().duration = 0.4
                labelNoCourse.animator().alphaValue = 1
                subLabelNoCourse.animator().alphaValue = 1
                NSAnimationContext.endGrouping()
            }
        }
    }
    var lectureFocused: LectureViewController! {
        didSet {
            if lectureFocused == nil {
                masterViewController.notifyLectureFocus(is: nil)
            } else {
                masterViewController.notifyLectureFocus(is: lectureFocused.lecture)
            }
        }
    }
    
    // MARK: ___ Initialization ___
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lectureScroller.alphaValue = 0
        
        // Setup observers for scrolling lectures
//        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.didLiveScroll),
//                                               name: .NSScrollViewDidLiveScroll, object: lectureScroller)
//        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.didScroll),
//                                               name: .NSViewBoundsDidChange, object: lectureClipper)
        
        findViewController = HXFindViewController(nibName: "HXFindView", bundle: nil)
        self.addChildViewController(findViewController)
        exportViewController = HXExportViewController(nibName: "HXExportView", bundle: nil)
        self.addChildViewController(exportViewController)
        replaceViewController = HXFindReplaceViewController(nibName: "HXFindReplaceView", bundle: nil)
        self.addChildViewController(replaceViewController)
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        
        lectureBottomBufferView.initialize(owner: self)
    }
    override func viewDidLayout() {
        super.viewDidLayout()

        didScroll()
    }
    
    // MARK: ––– Populating LectureStackView  –––

    /// Internal usage only. Reach this function by setting selectedCourse.
    private func loadLectures(from course: Course) {
        self.popLectures()
        for case let lecture as Lecture in course.lectures! {
            if !lecture.absent {
                pushLecture( lecture )
            }
        }
        if course.lectures!.count == 0 {
            labelNoCourse.stringValue = "No Lecture Data"
            subLabelNoCourse.stringValue = "Open HXNotes during an input class period."
            
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.4
            labelNoCourse.animator().alphaValue = 1
            subLabelNoCourse.animator().alphaValue = 1
            lectureScroller.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
        } else {
            notifyHeightUpdate()
            
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.5
            lectureScroller.animator().alphaValue = 1
            labelNoCourse.animator().alphaValue = 0
            subLabelNoCourse.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
        }
    }
    
    /// Handles purely the visual aspect of lectures. Populates lectureStack.
    private func pushLecture(_ lecture: Lecture) {
        let newController = LectureViewController(nibName: "HXLectureView", bundle: nil)!
        if let last = self.childViewControllers.last as? LectureViewController {
            last.shadowBottom.isHidden = false
        }
        self.addChildViewController(newController)
        lectureStack.insertArrangedSubview(newController.view, at: lectureStack.arrangedSubviews.count - 1)
        newController.view.widthAnchor.constraint(equalTo: lectureStack.widthAnchor).isActive = true
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
    
    /// Handles purely the visual aspect of lectures. Resets lectureLedgerStack, lectureStack,
    /// selectedCourse.lectures!.count, and weekCount
    private func popLectures() {
        for case let lectureController as LectureViewController in self.childViewControllers {
            lectureController.view.removeFromSuperview()
            lectureController.removeFromParentViewController()
        }
        lectureClipper.bounds.origin.y = 0
    }
    
    // MARK: ––– LectureStackView Visuals –––
    
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
    
    /// This allows user to override any animations placed on the scroller to remove stuttering.
    func didLiveScroll() {
        print("EditorVC - didLiveScroll")
        return;
        // Stop any scrolling animations currently happening on the clipper
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0 // This overwrites animator proxy object with 0 duration aimation
        lectureClipper.animator().setBoundsOrigin(NSPoint(x: 0, y: lectureClipper.bounds.origin.y))
        NSAnimationContext.endGrouping()
    }
    
    /// Receives scrolling from lectureScroller NSScrollView and any time clipper changes its bounds.
    /// Is responsible for updating the headers to simulate the iOS effect of lecture titles
    /// staying at the top of scrollView.
    func didScroll() {
        print("EditorVC - didScroll")
        return;
        // didScroll should only be called when the origin.y changes, not the height
        if oldClipperHeight == lectureClipper.bounds.height {
            // nyi
        }
        let clipperYPos = lectureClipper.bounds.origin.y
        // The y positions of each view in the stackview can be found by adding the heights of the previous views. Assumes zero spacing.
        // Should go through one more iteration after finding the last visible element in stack.
        var foundLowestLecture = false
        for case let lectureController as LectureViewController in self.childViewControllers {
            let lectureYPos = lectureStack.bounds.height - lectureController.view.frame.origin.y
            // Skip updating sticky header title and date if it was the last visible element in stack.
            if !foundLowestLecture {
                // If scroller is using elastic effect don't proceed past first element
                if clipperYPos < 0 {
                    stickyLecture = nil
                    return
                }
                // Since the last visible element in stack is not found yet, check if this element is visible still.
                if clipperYPos <= lectureYPos {
                    // It is visible so update sticky header VC and dump out of loop after one more iteration
                    if stickyLecture != lectureController {
                        // Only update stickyLecture when its a new LectureVC
                        stickyLecture = lectureController
                    } else {
                        // Otherwise tell the current stickyHeader of the current scroll amount
                        let y = clipperYPos - (lectureYPos - lectureController.view.bounds.height)
                        stickyLecture.updateStickyHeader(with: y)
                    }
                    foundLowestLecture = true
                }
            } else {
                // The following handles displacing of two headers that are touching.
                // Check how close the next element is to determine if stickyheader should be pushed aside
                //                print("Yeah")
                //                print("    stickyLecture.header.bounds.height: \(stickyLecture.header.bounds.height)")
                //                print("    clipperYPos: \(clipperYPos + stickyLecture.header.bounds.height)")
                //                print("    lectureYPos: \(lectureYPos - lectureController.view.bounds.height)")
                //                if (clipperYPos + stickyLecture.header.bounds.height) > (lectureYPos - lectureController.view.bounds.height) {
                //                    // Next element is encroaching on header so shift by Y difference
                //                    let y1 = (clipperYPos + stickyLecture.header.bounds.height) - (lectureYPos - lectureController.view.bounds.height)
                //                    let y2 = clipperYPos - (lectureStack.bounds.height - stickyLecture.view.frame.origin.y - stickyLecture.view.bounds.height)
                //                    print("    y: \(y2 - y1)")
                ////                    stickyLecture.updateStickyHeader(with: y)
                //                }
                // Stop iterating through controller views
                break
            }
        }
    }
    // Transitioning to a new stickyHeader should reset the last stickyHeader to zero.
    // Hence the need for a didSet.
    var stickyLecture: LectureViewController! {
        didSet {
            if oldValue != nil {
                oldValue.updateStickyHeader(with: 0)
            }
        }
    }
    
    /// Auto scrolling whenever user types.
    /// Smoothly scroll clipper until text typing location is centered.
    internal func checkScrollLevel(from sender: LectureViewController) {
        //        if sender.isStyling {
        //
        //        }
        let selectionY = sender.textSelectionHeight()
        // Center current typing position to center of lecture scroller
        let yPos = lectureStack.frame.height - selectionY // - lectureScroller.frame.height/2
        // Don't auto-scroll if selection is already visible and above center line of window
        if yPos < (lectureClipper.bounds.origin.y + sender.header.frame.height) || yPos > (lectureClipper.bounds.origin.y + lectureScroller.frame.height/2) {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.5
            // Get clipper to center selection in scroller
            lectureClipper.animator().setBoundsOrigin(NSPoint(x: 0, y: yPos - lectureScroller.frame.height/2))
            NSAnimationContext.endGrouping()
        }
    }
    
    /// Auto scrolling whenever user changes selection.
    /// Will only occur when the selection is outside of the visible area (not within the buffer region).
    internal func checkScrollLevelOutside(from sender: LectureViewController) {
        //        if sender.isStyling {
        //
        //        }
        let selectionY = sender.textSelectionHeight()
        // Position of selection
        let yPos = lectureStack.frame.height - selectionY // - lectureScroller.frame.height/2
        // Don't auto-scroll if selection is visible
        if yPos < (lectureClipper.bounds.origin.y + sender.header.frame.height) || yPos > (lectureClipper.bounds.origin.y + lectureScroller.frame.height) {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.5
            // Get clipper to center selection in scroller
            lectureClipper.animator().setBoundsOrigin(NSPoint(x: 0, y: yPos - lectureScroller.frame.height/2))
            NSAnimationContext.endGrouping()
        }
    }
    
    /// This notifies the editorVC that the bottom buffer view was clicked and
    /// that the last lectureVC should be selected in the stack.
    func bottomBufferClicked() {
        for case let lectureVC as LectureViewController in self.childViewControllers {
            if lectureVC.label_lectureTitle.stringValue == "Lecture \(selectedCourse.lectures!.count)" {
                NSApp.keyWindow?.makeFirstResponder(lectureVC.textView_lecture)
                lectureVC.textView_lecture.setSelectedRange(NSMakeRange((lectureVC.textView_lecture.string?.characters.count)!, 0))
            }
        }
    }
    
    // MARK: ––– Notifiers –––
    
    /// Received from LectureViewController on any change to a given lecture text view.
    /// Resizes the bottom buffer box
    internal func notifyHeightUpdate() {
        // Get last view in lectureStack
        let nonabsentLectureCount = (Array(selectedCourse.lectures!) as! [Lecture]).filter({!$0.absent}).count
        
        if let lectureController = childViewControllers.filter({$0 is LectureViewController})[nonabsentLectureCount - 1] as? LectureViewController {
            // Resize last lecture to keep text in the center of screen.
            if lectureController.view.frame.height < lectureScroller.frame.height/2 + 3 {
                lectureBottomConstraint.constant = -lectureController.view.frame.height
            } else {
                lectureBottomConstraint.constant = -lectureScroller.frame.height/2 - 3
            }
        }
    }
    
    func notifyLectureAddition(lecture: Lecture) {
        pushLecture( lecture )
        
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
                isFinding = !isFinding
            }
        }
    }
    
    func notifyFindAndReplace() {
        if selectedCourse != nil {
            if lectureFocused != nil {
                lectureFocused.isReplacing = !lectureFocused.isReplacing
            } else {
                isReplacing = !isReplacing
            }
        }
    }
    
    func notifyPrint() {
        if selectedCourse != nil {
            if lectureFocused != nil {
                
            } else {
                isPrinting = !isPrinting
            }
        }
    }
    
    func notifyExport() {
        if selectedCourse != nil {
            if lectureFocused != nil {
                lectureFocused.isExporting = !lectureFocused.isExporting
            } else {
                isExporting = !isExporting
            }
        }
    }
    
    // MARK: ––– Find Replace Print Export –––
    
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
        
        let fullRange = NSRange(location: 0, length: attribString.length)
        do {
            let data = try attribString.fileWrapper(from: fullRange, documentAttributes: [NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType])
            try data.write(to: url, options: .atomic, originalContentsURL: nil) // this for rtfd
        } catch {
            print("Something went wrong.")
        }
    }
    
    var findViewController: HXFindViewController!
    var exportViewController: HXExportViewController!
    var replaceViewController: HXFindReplaceViewController!
    
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
                lectureClipper.animator().setBoundsOrigin(NSPoint(x: 0, y: 0))
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
}
