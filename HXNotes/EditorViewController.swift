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
    
    // MARK: Initialize editorViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lectureScroller.alphaValue = 0
        
        // Setup observers for scrolling lectures
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.didLiveScroll),
                                               name: .NSScrollViewDidLiveScroll, object: lectureScroller)
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.didScroll),
                                               name: .NSViewBoundsDidChange, object: lectureClipper)
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        
        lectureBottomBufferView.initialize(owner: self)
    }
    override func viewDidLayout() {
        super.viewDidLayout()

        didScroll()
    }
    // MARK: Load object models ............................................................................
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
    
    // MARK: Populating stacks ...........................................................................................
    /// Creates a Lecture object for the currently selected course, and pushes an HXLectureLedger plus HXLectureView
    /// to their appropriate stacks.
    private func addLecture(_ lecture: Lecture) {
        
        pushLecture( lecture )
        
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
        print("DidScroll")
        // didScroll should only be called when the origin.y changes, not the height
        if oldClipperHeight == lectureClipper.bounds.height {
            // nyi
        }
        let clipperYPos = lectureClipper.bounds.origin.y
        // The y positions of each view in the stackview can be found by adding the heights of the previous views. Assumes zero spacing.
        // Should go through one more iteration after finding the last visible element in stack.
        var foundLowestLecture = false
        for case let lectureController as LectureViewController in self.childViewControllers {
            print("    Lecture checked: \(lectureController.label_lectureTitle.stringValue)")
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
    var stickyLecture: LectureViewController! {
        didSet {
            if oldValue != nil {
                oldValue.updateStickyHeader(with: 0)
            }
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
    
    // MARK: Notifiers
    /// Received from LectureViewController on any change to a given lecture text view. 
    /// Resizes the bottom buffer box
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
    /// Auto scrolling whenever user types. 
    /// Smoothly scroll clipper until text typing location is centered.
    internal func checkScrollLevel(from sender: LectureViewController) {
        if sender.isStyling {
            let selectionY = sender.textSelectionHeight()
            // Center current typing position to center of lecture scroller
            let yPos = lectureStack.frame.height - selectionY // - lectureScroller.frame.height/2
            // Don't auto-scroll if selection is already visible and above center line of window
            if yPos < (lectureClipper.bounds.origin.y + stickyLecture.header.frame.height) || yPos > (lectureClipper.bounds.origin.y + lectureScroller.frame.height/2) {
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
}
