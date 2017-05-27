//
//  EditorViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/2/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class EditorViewController: NSViewController {

    // MARK: View References
    @IBOutlet weak var lectureStack: NSStackView!
    @IBOutlet weak var lectureLedgerStack: NSStackView!
    @IBOutlet weak var lectureListContainer: NSBox!
    @IBOutlet weak var lectureBottomBufferView: HXBottomBufferView!
    @IBOutlet weak var lectureScroller: NSScrollView!
    @IBOutlet weak var lectureClipper: HXFlippedClipView!
    @IBOutlet weak var stickyHeaderBox: NSBox!
    @IBOutlet weak var stickyHeaderTitle: NSTextField!
    @IBOutlet weak var stickyHeaderDate: NSTextField!
    
    @IBOutlet weak var button_style_regular: NSButton!
    @IBOutlet weak var button_style_underline: NSButton!
    @IBOutlet weak var button_style_italicize: NSButton!
    @IBOutlet weak var button_style_bold: NSButton!
    @IBOutlet weak var button_style_left: NSButton!
    @IBOutlet weak var button_style_center: NSButton!
    @IBOutlet weak var button_style_right: NSButton!
    
    var lectureFocused: LectureViewController! {
        didSet {
            if lectureFocused == nil {
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
            } else if stickyHeaderTitle.stringValue == lectureFocused.label_lectureTitle.stringValue {
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
            }
        }
    }
    // Reference lecture lead constraint to hide/show this container
    private var lectureLeadingConstraint: NSLayoutConstraint!
    // This constraint is for an invisible view at the bottom of lecture stack to allow user to scroll
    // enough for the last lecture to be at top of screen regardless of amount of text
    private var lectureBottomConstraint: NSLayoutConstraint!
    // Reference to stickyHeader top constraint
    private var stickyHeaderTopConstraint: NSLayoutConstraint!
    // MARK: Object models
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    var lectureCount = 0
    var weekCount = 0
    var thisCourse: Course! {
        didSet {
            // Setting thisCourse, immediately updates visuals
            if thisCourse != nil {
                // Populate new lecture visuals
                if thisCourse.lectures!.count != 0 {
                    lectureListIsDisclosed(true)
                } else {
                    lectureListIsDisclosed(false)
                }
            } else {
                lectureListIsDisclosed(false)
            }
        }
    }
    
    // MARK: Initialize editorViewController
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lectureLeadingConstraint = lectureListContainer.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        lectureLeadingConstraint.isActive = true
        
        lectureLeadingConstraint.constant = -197
        stickyHeaderBox.alphaValue = 0
        lectureScroller.alphaValue = 0
        
        lectureBottomConstraint = lectureBottomBufferView.heightAnchor.constraint(equalTo: lectureScroller.heightAnchor)
        lectureBottomConstraint.isActive = true
        
        stickyHeaderTopConstraint = stickyHeaderBox.topAnchor.constraint(equalTo: lectureScroller.topAnchor)
        stickyHeaderTopConstraint.isActive = true
        
        // Setup observers for timeline scrolling - start/active/end scrolling years
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.didLiveScroll),
                                               name: .NSScrollViewDidLiveScroll, object: lectureScroller)
        NotificationCenter.default.addObserver(self, selector: #selector(EditorViewController.didScroll),
                                               name: .NSViewBoundsDidChange, object: lectureClipper)
        
        button_style_regular.alphaValue = 0
        button_style_underline.alphaValue = 0
        button_style_italicize.alphaValue = 0
        button_style_bold.alphaValue = 0
        button_style_regular.alphaValue = 0
        button_style_left.alphaValue = 0
        button_style_center.alphaValue = 0
        button_style_right.alphaValue = 0
    }
    override func viewDidAppear() {
        lectureBottomBufferView.initialize(owner: self)
    }
    // MARK: Load object models ..........................................................................................
    /// Called when a course is pressed in the courseStack. Populate stackViews with the loaded lectures from the selected course
    private func loadLectures(from course: Course) {
        self.popAllLectures()
        for case let lecture as Lecture in course.lectures! {
            pushLecture( lecture )
        }
        if lectureCount == 0 {
            stickyHeaderBox.alphaValue = 1
        }
    }
    
    // MARK: Populating stacks ...........................................................................................
    /// Creates a Lecture object for the currently selected course, and pushes an HXLectureLedger plus HXLectureView
    /// to their appropriate stacks. Will also add an HXWeekDividerBox to the lectureLedgerStack if necessary.
    private func addLecture() {
        print("Add lecture")
        pushLecture( newLecture() )
        
    }
    /// Handles purely the visual aspect of lectures. Populates lectureLedgerStack and lectureStack.
    private func pushLecture(_ lecture: Lecture) {
        if Int(lectureCount % 2) == 0 {
            lectureLedgerStack.addArrangedSubview(HXWeekBox.instance(withNumber: (weekCount+1)))
            weekCount += 1
        }
        // Update Views
        let newController = LectureViewController(nibName: "HXLectureView", bundle: nil)!
        self.addChildViewController(newController)
        lectureStack.insertArrangedSubview(newController.view, at: lectureStack.arrangedSubviews.count - 1)
        newController.initialize(withNumber: (lectureCount+1), withDate: "\(lecture.month)/\(lecture.day)/\(lecture.year % 100)", withLecture: lecture, owner: self)
        lectureLedgerStack.addArrangedSubview(HXLectureLedger.instance(withNumber: (lectureCount+1), withDate: "\(lecture.month)/\(lecture.day)/\(lecture.year % 100)", owner: self))
        
        lectureCount += 1
    }
    /// Handles purely the visual aspect of lectures. Resets lectureLedgerStack, lectureStack, lectureCount, and weekCount
    private func popAllLectures() {
        for v in lectureLedgerStack.arrangedSubviews {
            v.removeFromSuperview()
        }
        for v in lectureStack.arrangedSubviews {
            if v.identifier != "BottomBufferView" {
                v.removeFromSuperview()
            }
        }
        lectureCount = 0
        weekCount = 0
        
        for case let lectureController as LectureViewController in self.childViewControllers {
            lectureController.removeFromParentViewController()
        }
    }
    // MARK: Instance object models .....................................................................................
    /// Doesn't require parameters. Accesses local lectureCount, weekCount, thisCourse, and current NSCalendar date
    private func newLecture() -> Lecture {
        let newLecture = NSEntityDescription.insertNewObject(forEntityName: "Lecture", into: appDelegate.managedObjectContext) as! Lecture
        newLecture.course = thisCourse
        print("  With \(thisCourse.title)")
        newLecture.lecture = Int16(lectureCount + 1)
        newLecture.week = Int16(weekCount + 1)
        newLecture.day = Int16(NSCalendar.current.component(.day, from: NSDate() as Date))
        newLecture.month = Int16(NSCalendar.current.component(.month, from: NSDate() as Date))
        newLecture.year = Int16(NSCalendar.current.component(.year, from: NSDate() as Date))
        return newLecture
    }
    
    // MARK: TEMP
    /// Should not be able to simply add lectures this way
    @IBAction func action_addLecture(_ sender: Any) {
        addLecture()
    }
    func lectureListIsDisclosed(_ visible: Bool) {
        if visible {
            loadLectures(from: thisCourse)
            lectureScroller.alphaValue = 0
            // Animate hiding the lecture
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            NSAnimationContext.current().duration = 0.2
            lectureLeadingConstraint.animator().constant = 0
            NSAnimationContext.current().duration = 1
            stickyHeaderBox.animator().alphaValue = 1
            lectureScroller.animator().alphaValue = 1
            NSAnimationContext.endGrouping()
        } else if lectureLeadingConstraint.constant == 0 {
            print("FUCKER: \(lectureListContainer.bounds.origin.x)")
            // Animate showing the lecture
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            NSAnimationContext.current().completionHandler = {self.popAllLectures()}
            NSAnimationContext.current().duration = 0.25
            lectureLeadingConstraint.animator().constant = -197
            stickyHeaderBox.animator().alphaValue = 0
            lectureScroller.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
        }
    }
    /// Comes from the LectureLedger stack, scrolls to supplied lecture number. Lecture guaranteed to exist.
    func scrollToLecture(_ lecture: String) {
        for case let lectureController as LectureViewController in self.childViewControllers {
            if lectureController.label_lectureTitle.stringValue == lecture {
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
                    stickyHeaderTitle.stringValue = lectureController.label_lectureTitle.stringValue
                    stickyHeaderDate.stringValue = lectureController.label_lectureDate.stringValue
                    stickyHeaderTopConstraint.constant = -clipperYPos
                    return
                }
                let height = lectureController.view.bounds.height
                accumulatedHeight = accumulatedHeight + height
                // Since the last visible element in stack is not found yet, check if this element is visible still.
                if clipperYPos <= accumulatedHeight {
                    // It is visible so update sticky header fields and dump out of loop after one more iteration
                    stickyHeaderTitle.stringValue = lectureController.label_lectureTitle.stringValue
                    stickyHeaderDate.stringValue = lectureController.label_lectureDate.stringValue
                    foundLowestLecture = true
                }
                stickyHeaderTopConstraint.constant = 0
                if lectureFocused != nil {
                    if lectureFocused.label_lectureTitle.stringValue != stickyHeaderTitle.stringValue {
                        button_style_regular.alphaValue = 0
                        button_style_underline.alphaValue = 0
                        button_style_italicize.alphaValue = 0
                        button_style_bold.alphaValue = 0
                        button_style_regular.alphaValue = 0
                        button_style_left.alphaValue = 0
                        button_style_center.alphaValue = 0
                        button_style_right.alphaValue = 0
                    } else {
                        button_style_regular.alphaValue = 1
                        button_style_underline.alphaValue = 1
                        button_style_italicize.alphaValue = 1
                        button_style_bold.alphaValue = 1
                        button_style_regular.alphaValue = 1
                        button_style_left.alphaValue = 1
                        button_style_center.alphaValue = 1
                        button_style_right.alphaValue = 1
                    }
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
        for case let lectureController as LectureViewController in self.childViewControllers {
            if lectureController.label_lectureTitle.stringValue == "Lecture \(lectureCount)" {
                lectureController.focusText()
            }
        }
    }
    /// Received from LectureViewController on any change to a given lecture text view. 
    /// Is responsible for auto scrolling the lectureScroller.
    internal func notifyHeightUpdate(from sender: LectureViewController) {
        // Get last view in lectureStack
        if let lectureController = childViewControllers.filter({$0 is LectureViewController})[lectureCount - 1] as?LectureViewController {
            if lectureController.view.frame.height < lectureScroller.frame.height/2 + 50 {
                lectureBottomConstraint.constant = -lectureController.view.frame.height
            } else {
                lectureBottomConstraint.constant = -lectureScroller.frame.height/2 - 50
            }
            // AUTO SCROLL FEATURE: Smooth scroll to center on text line.
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
    // MARK: Print functionality
    @IBAction func actionTest_print(_ sender: Any) {
//        print("print test \n\(printableFormat().string)")
//        exportAllLectures()
        printAllLectures()
    }
    func exportAllLectures(){
        let attribString = NSMutableAttributedString()
        for case let lectureController as LectureViewController in self.childViewControllers {
            attribString.append(NSAttributedString(string: lectureController.label_lectureTitle.stringValue + "\n"))
            attribString.append(NSAttributedString(string: lectureController.label_lectureDate.stringValue + "\n\n"))
            attribString.append(lectureController.textView_lecture.attributedString())
            attribString.append(NSAttributedString(string: "\n"))
        }
        let fullRange = NSRange(location: 0, length: attribString.length)
        do {
            let data1 = try attribString.data(from: fullRange, documentAttributes: [NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType])
            let data3 = attribString.rtfd(from: fullRange, documentAttributes: [NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType])
            let savePanel = NSSavePanel()
            savePanel.nameFieldLabel = "Export As:"
            savePanel.canSelectHiddenExtension = true
            savePanel.nameFieldStringValue = "\(thisCourse.title!) Lectures - \(thisCourse.semester!.title!.capitalized) \(thisCourse.semester!.year!.year)"
            savePanel.prompt = "Export"
            savePanel.allowedFileTypes = [NSRTFDTextDocumentType]
            savePanel.beginSheetModal(for: NSApp.keyWindow!, completionHandler: {result in
                if result == NSFileHandlingPanelOKButton {
                    do {
                        print("File extension: \(savePanel.url!)")
//                        try writableData.write(to: savePanel.url!)
                        try data3!.write(to: savePanel.url!, options: .atomic)
                    } catch {
                    }
                }
            })
        } catch {
        }
    }
    // EXPORT AND PRINT should get file data from
    func printAllLectures() {
        if lectureFocused != nil {
            lectureFocused.textView_lecture.print(self)
        }
    }
    /// Assumes all lectures will be included
    func exportRTF() {
        
    }
    func exportRTF(for lecture: LectureViewController) {
        
    }
    @IBAction func action_styleRegular(_ sender: NSButton) {
        if lectureFocused != nil {
            lectureFocused.action_styleRegular(sender)
        }
    }
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
}
