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

    // MARK: - View References
    // These 2 labels are displayed when no course is selected
    @IBOutlet weak var labelNoCourse: NSTextField!
    @IBOutlet weak var subLabelNoCourse: NSTextField!    
    @IBOutlet weak var dropdownView: NSView!
    @IBOutlet weak var dropdownTopConstraint: NSLayoutConstraint!
    
    // MARK: Object models
    let appDelegate = NSApplication.shared.delegate as! AppDelegate
    let sharedFontManager = NSFontManager.shared

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
                if selectedCourse.lectures!.count != 0 {
                    // Animate showing the lectures
                    NSAnimationContext.beginGrouping()
                    NSAnimationContext.current.duration = 0.25
                    collectionView.animator().alphaValue = 1
                    NSAnimationContext.current.duration = 0.4
                    NSAnimationContext.current.completionHandler = {
                        self.labelNoCourse.isHidden = true
                        self.subLabelNoCourse.isHidden = true
                    }
                    labelNoCourse.animator().alphaValue = 0
                    subLabelNoCourse.animator().alphaValue = 0
                    NSAnimationContext.endGrouping()
                } else {
                    
                    let hour = NSCalendar.current.component(.hour, from: Date())
                    let minute = NSCalendar.current.component(.minute, from: Date())
                    
                    let weekday = Int16(NSCalendar.current.component(.weekday, from: Date()))
                    let minuteOfDay = Int16(hour * 60 + minute)
                    
                    var nextTimeSlot: TimeSlot!
                    
                    var dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                    
                    // Iterate through days (plus extra one if case we need to check the same day again)
                    dayLoop: for d in 0..<8 {
                        let checkDay = (weekday + d) % 8 + Int(floor(Double((weekday + d) / 8)))
                        for case let timeSlot as TimeSlot in selectedCourse.timeSlots! {
                            let timeDay = timeSlot.weekday
                            let timeStop = timeSlot.stopMinute
                            if timeDay == weekday && d != 7 {
                                // If its today, then check the time of day
                                if timeStop > minuteOfDay {
                                    nextTimeSlot = timeSlot
                                    dayNames[Int(weekday)] = "today"
                                    break dayLoop
                                }
                            } else if timeDay == checkDay {
                                nextTimeSlot = timeSlot
                                if d == 7 {
                                    dayNames[Int(weekday)] = "next " + dayNames[Int(weekday)]
                                }
                                break dayLoop
                            }
                        }
                    }
                    let nextTimeSlotDay = Int(nextTimeSlot.weekday)
                    let nextTimeSlotStart = Int(nextTimeSlot.startMinute)
                    labelNoCourse.isHidden = false
                    subLabelNoCourse.isHidden = false
                    labelNoCourse.alphaValue = 1
                    subLabelNoCourse.alphaValue = 1
                    labelNoCourse.stringValue = "No Lectures for " + selectedCourse.title!
                    subLabelNoCourse.stringValue = "New lectures can only be added during a course's timeslot. Next lecture is \(dayNames[nextTimeSlotDay]) at \(HXTimeFormatter.formatTime(Int16(nextTimeSlotStart)))."
                }
            } else {
                labelNoCourse.isHidden = false
                subLabelNoCourse.isHidden = false
                labelNoCourse.stringValue = "No Course Selected"
                subLabelNoCourse.stringValue = "Courses are selectable to the left."
                // Animate hiding the lecture
                NSAnimationContext.beginGrouping()
                NSAnimationContext.current.completionHandler = {
                    if self.selectedCourse == nil {
                        self.collectionView.reloadData()
                    }
                }
                NSAnimationContext.current.duration = 0.25
                collectionView.animator().alphaValue = 0
                NSAnimationContext.current.duration = 0.4
                labelNoCourse.animator().alphaValue = 1
                subLabelNoCourse.animator().alphaValue = 1
                NSAnimationContext.endGrouping()
            }
        }
    }
    
    weak var lectureFocused: LectureCollectionViewItem! {
        didSet {
//            masterViewController.notifyLectureFocus(is: lectureFocused)
        }
    }
    
    // MARK: ___ Initialization ___
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.alphaValue = 0
        
        findViewController = HXFindViewController(nibName: NSNib.Name(rawValue: "HXFindView"), bundle: nil)
        self.addChildViewController(findViewController)
        exportViewController = HXExportViewController(nibName: NSNib.Name(rawValue: "HXExportView"), bundle: nil)
        self.addChildViewController(exportViewController)
        replaceViewController = HXFindReplaceViewController(nibName: NSNib.Name(rawValue: "HXFindReplaceView"), bundle: nil)
        self.addChildViewController(replaceViewController)
        
        self.view.wantsLayer = true
        
        configureCollectionView()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        NotificationCenter.default.addObserver(self, selector: #selector(notifyContextObjectsUpdate(notification:)),name: .NSManagedObjectContextObjectsDidChange, object: appDelegate.managedObjectContext)
    }
    
    /// Received from Notification Center on a managed object context change.
    @objc func notifyContextObjectsUpdate(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }

        if let inserts = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObject>, inserts.count > 0 {
            if inserts.filter({$0 is Lecture}).count > 0 {
                // New TimeSlot added
            }
        }
        if let updates = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObject>, updates.count > 0 {
            //updates.flatMap({ $0 as? TimeSlot })
            if updates.filter({ $0 is Lecture && $0.changedValues().keys.contains("content") }).count > 0 {
                // Timeslot changed
                for update in updates {
                    if update.changedValues().keys.contains(where: {$0 == "content"}) {
                        print("  Content update: \((update.changedValues()["content"] as! NSAttributedString).string)")
                    }
                    
                }
            }
        }
        // || $0.changedValues().keys.contans("stopTime")
//        if let
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
        // To keep dynamic item widths, need to recalculate them when resizing collection view.
        collectionView.collectionViewLayout?.invalidateLayout()
    }
    
    // MARK: - ––– LectureStackView Visuals –––
    
    /// Comes from the LectureLedger stack, scrolls to supplied lecture number. Lecture guaranteed to exist.
    private func scrollToLecture(_ lecture: String) {
        
//        var scrollY: CGFloat = 0
//        var responder: NSResponder!
        
//        for collectionViewItem in collectionViewItems {
//            if "Lecture \(collectionViewItem.lecture.number)" == lecture {
//                responder = collectionViewItem.textView_lecture
//                scrollY = collectionViewItem.view.frame.origin.y
//                break
//            }
//        }
        
//        for headerItem in headerViews {
//            if headerItem.label_lectureTitle.stringValue == lecture {
//                
//                NSAnimationContext.beginGrouping()
//                NSAnimationContext.current().duration = 0.25
//                NSAnimationContext.current().completionHandler = {NSApp.keyWindow?.makeFirstResponder(responder)}
//                collectionClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: scrollY - headerItem.frame.height))
//                NSAnimationContext.endGrouping()
//                break
//            }
//        }
    }
    
    /// Auto scrolling whenever user types.
    /// Smoothly scroll clipper until text typing location is centered.
    internal func checkScrollLevel(from sender: LectureCollectionViewItem) {
//        // Only do smooth auto scrolling if the preference value is set to true
//        if !autoScroll {
//            return
//        }
//        return
//        let scrollY = sender.lastSelectionHeightCheck
//        
//        if scrollY < collectionClipView.bounds.origin.y + sender.header.frame.height || scrollY > collectionClipView.bounds.origin.y + collectionView.enclosingScrollView!.frame.height * CGFloat(autoScrollPosition)/100 {
//            NSAnimationContext.beginGrouping()
//            NSAnimationContext.current().duration = 0.25
//            collectionClipView.animator().setBoundsOrigin(NSPoint(x: 0, y: scrollY - collectionView.enclosingScrollView!.frame.height * CGFloat(autoScrollPosition)/100))
//            NSAnimationContext.endGrouping()
//            
//            collectionView.enclosingScrollView?.flashScrollers()
//        }
    }
    
    override func mouseDown(with event: NSEvent) {
//        print("Mouse down.")
    }
    
    // MARK: - ––– Notifiers –––
    
    func notifyLectureAddition(lecture: Lecture) {
//        selectedCourse = masterViewController.selectedCourse
//        // This reloads data but also checks if need to reveal the collection view
//        
//        scrollToLecture("Lecture \(lecture.number)")
    }
    func notifyLectureSelection(lecture: String) {
//        scrollToLecture(lecture)
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
    
    fileprivate func configureCollectionView() {
        
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 50, height: 50)
        flowLayout.sectionInset = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.sectionHeadersPinToVisibleBounds = true
        collectionView.collectionViewLayout = flowLayout
        collectionView.allowsEmptySelection = true
    }
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        if selectedCourse == nil || selectedCourse.lectures == nil {
            return 0
        }
        return selectedCourse.lectures!.count
        
//        var nonAbsences = 0
//        if selectedCourse != nil {
//            for case let lecture as Lecture in selectedCourse.lectures! {
//                if !lecture.absent {
//                    nonAbsences += 1
//                }
//            }
//            print("Numbering: (\(nonAbsences))")
//            return nonAbsences
//        }
//        
//        print("Numbering: 0")
//        return 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ itemForRepresentedObjectAtcollectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        // Create LectureCollectionViewItem
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LectureCollectionViewItem"), for: indexPath) as! LectureCollectionViewItem
        
        if item.lecture == nil {
            print("   Lecture field is nil. Cool")
        } else {
            print("   .. LECTURE FIELD NOT NIL!?!?")
        }
        
        // Initialize the LectureCollectionViewItem
        let lecture = selectedCourse.lectures!.object(at: Int(Int64(indexPath[0]))) as! Lecture
        print("    Printing all lecture content...")
        for case let lecture2 as Lecture in selectedCourse.lectures! {
            if lecture2.content == nil {
                continue
            }
            print("      con: \(lecture2.content!.string)")
        }
        print("    • lecture number: \(lecture.number)")
        item.lecture = lecture
        if lecture.content != nil {
            print("      ==> content: \(lecture.content!.string)")
            item.textView_lecture.textStorage?.setAttributedString(lecture.content!)
        }
        item.owner = self
//        item.textView_lecture.parentController = item
        
        NotificationCenter.default.removeObserver(item, name: NSText.didChangeNotification, object: item.textView_lecture)
        NotificationCenter.default.addObserver(item, selector: #selector(LectureCollectionViewItem.notifyTextChange),
                                               name: NSText.didChangeNotification, object: item.textView_lecture)
        
        print("          -> lecture.content!.string: \(lecture.content!.string)")
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind, at indexPath: IndexPath) -> NSView {
        
        // Create LectureHeaderView
        let header = collectionView.makeSupplementaryView(ofKind: NSCollectionView.SupplementaryElementKind.sectionHeader, withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "LectureHeaderView"), for: indexPath) as! LectureHeaderView
        
        // Initialize the LectureHeaderView
        let lecture = selectedCourse.lectures!.array[Int(Int64(indexPath[0]))] as! Lecture
        header.label_lectureTitle.stringValue = "Lecture \(lecture.number)"
        let timeMonth = lecture.month
        let timeDay = lecture.day
        let timeYear = lecture.course!.semester!.year
        header.label_lectureDate.stringValue = "\(timeMonth)/\(timeDay)/\(timeYear % 100)"
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
        header.button_style_font.alphaValue = 0
        header.button_style_color.alphaValue = 0
        header.box_style_color.alphaValue = 0
        header.label_style_font.alphaValue = 0
        NotificationCenter.default.removeObserver(header, name: NSControl.textDidEndEditingNotification, object: header.label_customTitle)
        NotificationCenter.default.removeObserver(header, name: NSControl.textDidChangeNotification, object: header.label_customTitle)
        NotificationCenter.default.addObserver(header, selector: #selector(LectureHeaderView.notifyCustomTitleEndEditing),
                                               name: NSControl.textDidEndEditingNotification, object: header.label_customTitle)
        NotificationCenter.default.addObserver(header, selector: #selector(LectureHeaderView.notifyCustomTitleChange),
                                               name: NSControl.textDidChangeNotification, object: header.label_customTitle)
        header.owner = self
        
        if let cvi = collectionView.item(at: indexPath) as? LectureCollectionViewItem {
            cvi.header = header
            header.collectionViewItem = cvi
            
            NotificationCenter.default.removeObserver(header, name: NSTextView.didChangeSelectionNotification, object: cvi.textView_lecture)
            NotificationCenter.default.removeObserver(header, name: NSTextView.didChangeTypingAttributesNotification, object: cvi.textView_lecture)
            NotificationCenter.default.addObserver(header, selector: #selector(LectureHeaderView.selectionChange),
                                                   name: NSTextView.didChangeSelectionNotification, object: cvi.textView_lecture)
            NotificationCenter.default.addObserver(header, selector: #selector(LectureHeaderView.traitChange),
                                                   name: NSTextView.didChangeTypingAttributesNotification, object: cvi.textView_lecture)
        }
        return header
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        
        guard let lecture = selectedCourse.lectures!.object(at: Int(Int64(indexPath[0]))) as? Lecture
            else { return NSSize(width: collectionView.bounds.width, height: 40) }
        
        let h = calculateCollectionViewItemHeight(from: lecture)
        
        var hBuffer: CGFloat = 0
        // If this is the last CVI, then add bottom buffer space as specified in preferences...
        if Int(Int64(indexPath[0])) == (collectionView.numberOfSections - 1) {
            // Last object...
            hBuffer = (collectionClipView.enclosingScrollView!.frame.height - 30) * (CGFloat(AppPreference.bottomBufferSpace) / 100)
        }
        
        return NSSize(width: collectionView.bounds.width, height: h + hBuffer)
    }
    
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
        
        return NSSize(width: collectionView.bounds.width, height: 30)
    }
    
    func calculateCollectionViewItemHeight(from lecture: Lecture) -> CGFloat {
        var txtStorage: NSTextStorage!
        if lecture.content == nil {
            txtStorage = NSTextStorage(string: "")
        } else {
            txtStorage = NSTextStorage(attributedString: lecture.content!)
        }
        let txtContainer = NSTextContainer(containerSize: NSSize(width: collectionView.bounds.width, height: 100000))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(txtContainer)
        txtStorage.addLayoutManager(layoutManager)
        txtContainer.lineFragmentPadding = 0
        layoutManager.ensureLayout(for: txtContainer)
        layoutManager.glyphRange(for: txtContainer)
        return layoutManager.usedRect(for: txtContainer).size.height + 18
    }

    // MARK: - ––– Find Replace Print Export –––
    
    /// Reveal or hide the top bar container.
    func topBarShown(_ visible: Bool) {
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        NSAnimationContext.current.duration = 0.25
        if visible {
            NSAnimationContext.current.completionHandler = {
                // If showing top bar and isFind or isReplace, then set firstResponders
                if self.isReplacing {
                    NSApp.keyWindow?.makeFirstResponder(self.replaceViewController.textField_find)
                } else if self.isFinding {
                    NSApp.keyWindow?.makeFirstResponder(self.findViewController.textField_find)
                }
            }
            dropdownTopConstraint.animator().constant = 0
        } else {
            NSAnimationContext.current.completionHandler = {
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
            let data = try attribString.fileWrapper(from: fullRange, documentAttributes: [NSAttributedString.DocumentAttributeKey.documentType: NSAttributedString.DocumentType.rtfd])
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
                NSAnimationContext.current.duration = 0.5
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
}
