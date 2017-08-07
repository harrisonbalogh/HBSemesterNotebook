//
//  EditorViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/2/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class EditorViewController: NSViewController, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout {
    
    weak var masterViewController: MasterViewController!

    // MARK: View References
    @IBOutlet weak var lectureClipper: HXFlippedClipView!
    var oldClipperHeight: CGFloat = 0
    // These 2 labels are displayed when no course is selected
    @IBOutlet weak var labelNoCourse: NSTextField!
    @IBOutlet weak var subLabelNoCourse: NSTextField!    
    @IBOutlet weak var dropdownView: NSView!
    @IBOutlet weak var dropdownTopConstraint: NSLayoutConstraint!
    
    // MARK: Object models
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    let sharedFontManager = NSFontManager.shared()
    
    weak var selectedCourse: Course! {
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
                
                collectionView.reloadData()
                
                // Animate hiding the lecture
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.25
                collectionView.animator().alphaValue = 1
                NSAnimationContext.current().duration = 0.4
                labelNoCourse.animator().alphaValue = 0
                subLabelNoCourse.animator().alphaValue = 0
                NSAnimationContext.endGrouping()
                
            } else {
                labelNoCourse.stringValue = "No Course Selected"
                subLabelNoCourse.stringValue = "Courses are selectable to the left."
                // Animate hiding the lecture
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().completionHandler = {
                    if self.selectedCourse == nil {
                        self.collectionView.reloadData()
                    }
                }
                NSAnimationContext.current().duration = 0.25
                collectionView.animator().alphaValue = 0
                NSAnimationContext.current().duration = 0.4
                labelNoCourse.animator().alphaValue = 1
                subLabelNoCourse.animator().alphaValue = 1
                NSAnimationContext.endGrouping()
            }
        }
    }
    
    weak var lectureFocused: LectureCollectionViewItem! {
        didSet {
            print("Lecture Focused...")
            if oldValue != nil {
                print("    Old value: \(collectionViewItems.index(of: oldValue)!)")
                headerViews[collectionViewItems.index(of: oldValue)!].notifyTextViewFocus(false)
            }
            if lectureFocused == nil {
                print("    Nil value.")
                masterViewController.notifyLectureFocus(is: nil)
            } else {
                masterViewController.notifyLectureFocus(is: lectureFocused.lecture)
                print("    New Value: \(collectionViewItems.index(of: lectureFocused)!)")
                headerViews[collectionViewItems.index(of: lectureFocused)!].notifyTextViewFocus(true)
            }
        }
    }
    
    // MARK: ___ Initialization ___
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.alphaValue = 0
        
        findViewController = HXFindViewController(nibName: "HXFindView", bundle: nil)
        self.addChildViewController(findViewController)
        exportViewController = HXExportViewController(nibName: "HXExportView", bundle: nil)
        self.addChildViewController(exportViewController)
        replaceViewController = HXFindReplaceViewController(nibName: "HXFindReplaceView", bundle: nil)
        self.addChildViewController(replaceViewController)
        
        self.view.wantsLayer = true
        
        configureCollectionView()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
//        print("ViewDidLayout")
        // To keep dynamic item widths, need to recalculate them when resizing collection view.
        collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    // MARK: - ––– LectureStackView Visuals –––
    
    /// Comes from the LectureLedger stack, scrolls to supplied lecture number. Lecture guaranteed to exist.
    private func scrollToLecture(_ lecture: String) {
        
        var scrollY: CGFloat = 0
        var responder: NSResponder!
        for collectionViewItem in collectionViewItems {
            if "Lecture \(collectionViewItem.lecture.number)" == lecture {
                responder = collectionViewItem.textView_lecture
                scrollY = collectionViewItem.view.frame.origin.y
                break
            }
        }
        
        for headerItem in headerViews {
            if headerItem.label_lectureTitle.stringValue == lecture {
                
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current().duration = 0.25
                NSAnimationContext.current().completionHandler = {NSApp.keyWindow?.makeFirstResponder(responder)}
                collectionClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: scrollY - headerItem.frame.height))
                NSAnimationContext.endGrouping()
                break
            }
        }
    }
    
    /// Auto scrolling whenever user types.
    /// Smoothly scroll clipper until text typing location is centered.
    internal func checkScrollLevel(from sender: LectureCollectionViewItem) {
        let scrollY = sender.textSelectionHeight()
        
        // ADJUSTABLE SETTING SPOT. Change collectionView.frame.height/2 (this is 50% spot)
        if scrollY < collectionClipView.bounds.origin.y + sender.header.frame.height || scrollY > collectionClipView.bounds.origin.y + collectionView.enclosingScrollView!.frame.height/2 {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.25
            collectionClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: scrollY - collectionView.enclosingScrollView!.frame.height/2))
            NSAnimationContext.endGrouping()
            
            collectionView.enclosingScrollView?.flashScrollers()
        }
    }
    
    /// Auto scrolling whenever user changes selection.
    /// Will only occur when the selection is outside of the visible area (not within the buffer region).
    internal func checkScrollLevelOutside(from sender: LectureCollectionViewItem) {
        let scrollY = sender.textSelectionHeight()
        
        // ADJUSTABLE SETTING SPOT. Change collectionView.frame.height/2 (this is 50% spot)
        if scrollY < collectionClipView.bounds.origin.y + sender.header.frame.height || scrollY > collectionClipView.bounds.origin.y + collectionView.enclosingScrollView!.frame.height {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.25
            collectionClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: scrollY - collectionView.enclosingScrollView!.frame.height/2))
            NSAnimationContext.endGrouping()
            
            collectionView.enclosingScrollView?.flashScrollers()
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        print("Mouse down.")
    }
    
    // MARK: - ––– Notifiers –––
    
    /// Received from LectureViewController on any change to a given lecture text view.
    /// Resizes the bottom buffer box
    internal func notifyHeightUpdate() {

        // REPLACE FOLLOWING
//        if let lectureController = childViewControllers.filter({$0 is LectureViewController})[nonabsentLectureCount - 1] as? LectureViewController {
//            // Resize last lecture to keep text in the center of screen.
//            if lectureController.view.frame.height < lectureScroller.frame.height/2 + 3 {
//                lectureBottomConstraint.constant = -lectureController.view.frame.height
//            } else {
//                lectureBottomConstraint.constant = -lectureScroller.frame.height/2 - 3
//            }
//        }
        
        // NOTE
//        collectionView.reloadItems(at: <#T##Set<IndexPath>#>)
//        collectionView.lastBaselineAnchor
        
        
        // REPLACE WITH THIS
//        collectionViewBottomConstraint - SET THIS
    }
    
    func notifyLectureAddition(lecture: Lecture) {
        collectionView.reloadData()
        
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
    
    // MARK: - ––– Collection View Data Source & Delegate (Flow Layout) –––
    
    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var collectionViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionClipView: NSClipView!
    
    
    var headerViews = [LectureHeaderView]()
    var collectionViewItems = [LectureCollectionViewItem]()
    
    fileprivate func configureCollectionView() {
        
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 50, height: 50)
        flowLayout.sectionInset = EdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.sectionHeadersPinToVisibleBounds = true
        collectionView.collectionViewLayout = flowLayout
        collectionView.allowsEmptySelection = true
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        
//        print("Collection view getting number of sections...")
        
        headerViews = [LectureHeaderView]()
        collectionViewItems = [LectureCollectionViewItem]()
        
        if selectedCourse != nil {
            print("    - \(selectedCourse.lectures!.count)")
            return selectedCourse.lectures!.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        // Create LectureCollectionViewItem
        let item = collectionView.makeItem(withIdentifier: "LectureCollectionViewItem", for: indexPath) as! LectureCollectionViewItem
        
//        print("Int(indexPath[0].toIntMax(): \(Int(indexPath[0].toIntMax()))")
        
        // Initialize the LectureCollectionViewItem
        let lecture = selectedCourse.lectures!.array[Int(indexPath[0].toIntMax())] as! Lecture
        item.lecture = lecture
        if lecture.content != nil {
            item.textView_lecture.textStorage?.setAttributedString(lecture.content!)
        }
        item.owner = self
        item.textView_lecture.parentController = item
        
//        print("LectureCollectionViewItem instanced.")
        
        collectionViewItems.append(item)
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> NSView {
        
        // Create LectureHeaderView
        let header = collectionView.makeSupplementaryView(ofKind: NSCollectionElementKindSectionHeader, withIdentifier: "LectureHeaderView", for: indexPath) as! LectureHeaderView
        
        // Initialize the LectureHeaderView
        let lecture = selectedCourse.lectures!.array[Int(indexPath[0].toIntMax())] as! Lecture
//        print("Lecture: \(lecture.number)")
//        print("    absent - \(lecture.absent)")
        header.label_lectureTitle.stringValue = "Lecture \(lecture.number)"
        header.label_lectureDate.stringValue = "\(lecture.monthInYear())/\(lecture.dayInMonth())/\(lecture.course!.semester!.year % 100)"
        if lecture.title != nil {
            header.label_customTitle.stringValue = lecture.title!
            if header.label_customTitle.stringValue == "" {
                header.label_titleDivider.alphaValue = 0.3
            } else {
                header.label_titleDivider.alphaValue = 1
            }
        } else {
            header.label_titleDivider.alphaValue = 0.3
        }
        header.button_style_underline.alphaValue = 0
        header.button_style_italicize.alphaValue = 0
        header.button_style_bold.alphaValue = 0
        header.button_style_left.alphaValue = 0
        header.button_style_center.alphaValue = 0
        header.button_style_right.alphaValue = 0
        NotificationCenter.default.addObserver(header, selector: #selector(LectureHeaderView.notifyCustomTitleEndEditing),
                                               name: .NSControlTextDidEndEditing, object: header.label_customTitle)
        NotificationCenter.default.addObserver(header, selector: #selector(LectureHeaderView.notifyCustomTitleChange),
                                               name: .NSControlTextDidChange, object: header.label_customTitle)
        header.owner = self
        
//        print("LectureHeaderView instanced. Index: \(Int(indexPath[0].toIntMax()))")
        if (collectionViewItems.count - 1) >= Int(indexPath[0].toIntMax()) {
//            print(" -- Setting vars")
            header.collectionViewItem = collectionViewItems[Int(indexPath[0].toIntMax())]
            collectionViewItems[Int(indexPath[0].toIntMax())].header = header
            
            NotificationCenter.default.addObserver(header, selector: #selector(LectureHeaderView.selectionChange),
                                                   name: .NSTextViewDidChangeSelection, object: collectionViewItems[Int(indexPath[0].toIntMax())].textView_lecture)
            NotificationCenter.default.addObserver(header, selector: #selector(LectureHeaderView.traitChange),
                                                   name: .NSTextViewDidChangeTypingAttributes, object: collectionViewItems[Int(indexPath[0].toIntMax())].textView_lecture)
        }
        
        headerViews.append(header)
        return header
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        
//        print("Size 1.")
        //CGFloat(indexPath[0].toIntMax() + 1) * 36
        if (collectionViewItems.count - 1) >= Int(indexPath[0].toIntMax()) {
            let h = collectionViewItems[Int(indexPath[0].toIntMax())].textHeight()
            return CGSize(width: collectionView.bounds.width, height: h)
        }
        
        return CGSize(width: collectionView.bounds.width, height: 41)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        
//        print("Size 2.")
        return NSSize(width: 560, height: 30)
    }
    
    // MARK: - ––– Find Replace Print Export –––
    
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
        for case let lecture as Lecture in selectedCourse.lectures! {
//            attribString
        }
        
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
