//
//  TimelineViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 4/30/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class TimelineViewController: NSViewController {
    
    @IBOutlet weak var button_toCurrentYear: NSButton!
    // The stackView,scrollView/clipView keep as low of an overhead as
    // possible. The stackView will remove arranged button views as the
    // clipView moves within the scrollView to only retain visible buttons.
    @IBOutlet weak var stackView_year: NSStackView!
    @IBOutlet weak var scrollView_year: NSScrollView!
    @IBOutlet weak var clipView_year: NSClipView!
    @IBOutlet weak var buttonFall: NSButton!
    @IBOutlet weak var buttonSpring: NSButton!
    @IBOutlet weak var imageSemesterToggle: NSImageView!
    @IBOutlet weak var labelSemester: NSTextField!
    
    private let YEAR_BUTTON_WIDTH: CGFloat = 68
    
    // Models
    private var currentYear = 1993
    private var earliestYear = 1993
    private var latestYear = 1992
    let appDelegate = NSApplication.shared().delegate as! AppDelegate
    private var semesterSelected: Semester! {
        didSet {
            if oldValue != semesterSelected {
                if let masterViewController = self.parent! as? MasterViewController {
                    masterViewController.notifySemesterSelection(semester: semesterSelected)
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for s in stackView_year.subviews {
            s.removeFromSuperview()
        }
        
        // Setup observers for timeline scrolling - start/active/end scrolling years
        NotificationCenter.default.addObserver(self, selector: #selector(TimelineViewController.receiveStartScrolling),
                                               name: .NSScrollViewWillStartLiveScroll, object: scrollView_year)
        NotificationCenter.default.addObserver(self, selector: #selector(TimelineViewController.receiveBoundsChange),
                                               name: .NSViewBoundsDidChange, object: clipView_year)
        NotificationCenter.default.addObserver(self, selector: #selector(TimelineViewController.receiveEndScrolling),
                                               name: .NSScrollViewDidEndLiveScroll, object: scrollView_year)
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        handleYearResize()
        // Default to current year
        action_goToCurrentYear(self)
        // Default to current semester (based on month range assumption)
        let month = NSCalendar.current.component(.month, from: NSDate() as Date)
        if month >= 7 && month <= 12 {
            action_selectFall(sender: self)
        } else {
            action_selectSpring(sender: self)
        }
    }
    
    // MARK: Observer notications from year scrollView .............................................................................
    /// Receives NSScrollViewWillStartLiveScroll notifications
    func receiveStartScrolling() {
        // Visually deselect years
        for case let button as HXYearButton in stackView_year.arrangedSubviews {
            button.deselect()
        }
        // Disable toCurentYear button and semester buttons
        button_toCurrentYear.isHidden = false
        button_toCurrentYear.isEnabled = true
        buttonFall.isEnabled = false
        buttonSpring.isEnabled = false
        buttonFall.alphaValue = 0.3
        buttonSpring.alphaValue = 0.3
        // Reset visual for semester toggle
        imageSemesterToggle.image = #imageLiteral(resourceName: "art_tree")
    }
    /// Receives NSVoewBoundsDidChange notifications
    func receiveBoundsChange() {
//        boundaryCheck()
    }
    /// Receives NSScrollViewDidEndLiveScroll notifications
    func receiveEndScrolling() {
        alignScrollToYear()
    }
    
    // MARK: Adding/Removing years from year stackView ..............................................................................
    /// Add earlier year
    private func prefixYear() {
        print("Prefix a year.")
        let newYearButton = HXYearButton(withYear: earliestYear - 1)
        newYearButton.target = self
        newYearButton.action = #selector(TimelineViewController.action_clickYear(sender:))
        earliestYear -= 1
        stackView_year.insertArrangedSubview(newYearButton, at: 0)
        clipView_year.bounds.origin.x += YEAR_BUTTON_WIDTH
    }
    /// Add later year
    private func suffixYear() {
        print("Suffix a year.")
        let newYearButton = HXYearButton(withYear: latestYear + 1)
        newYearButton.target = self
        newYearButton.action = #selector(TimelineViewController.action_clickYear(sender:))
        latestYear += 1
        stackView_year.addArrangedSubview(newYearButton)
    }
    /// Remove earlier year
    private func popPrefixYear() {
        print("Pop prefix year.")
        if stackView_year.arrangedSubviews.count > 0 {
            earliestYear += 1
            stackView_year.arrangedSubviews[0].removeFromSuperview()
        }
        // Correct year scroller to remain in same place after inserting new year to front of stack
        let newSize = NSSize(width: CGFloat(stackView_year.arrangedSubviews.count) * YEAR_BUTTON_WIDTH, height: clipView_year.bounds.height)
        clipView_year.bounds = NSRect(origin: CGPoint(x: clipView_year.bounds.origin.x - YEAR_BUTTON_WIDTH, y: clipView_year.bounds.origin.y), size: newSize)
    }
    /// Remove later year
    private func popSuffixYear() {
        print("Pop suffix year.")
        if stackView_year.arrangedSubviews.count > 0 {
            latestYear -= 1
            stackView_year.arrangedSubviews[stackView_year.arrangedSubviews.count-1].removeFromSuperview()
        }
    }
    
    // MARK: Handling year scrollView resizing and scrolling .............................................................................
    override func viewDidLayout() {
        super.viewDidLayout()
        
        handleYearResize()
    }
    
    /// In one call, will populate or remove as many years as necessary to fit year stackView to new window width.
    private func handleYearResize() {
        // Shift clipView to center on a year
        let centerPoint = clipView_year.bounds.origin.x + YEAR_BUTTON_WIDTH/2
            - (clipView_year.bounds.origin.x + scrollView_year.bounds.width/2).truncatingRemainder(dividingBy: YEAR_BUTTON_WIDTH)
        
        // Make sure the scroller is not moving
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 0.01
        clipView_year.setFrameOrigin(NSPoint(x: centerPoint, y: 0))
        NSAnimationContext.endGrouping()

        let stackViewWidth = CGFloat(stackView_year.arrangedSubviews.count) * YEAR_BUTTON_WIDTH
        let spaceDifference = scrollView_year.bounds.width - stackViewWidth
        let buttonsToMake = Int(floor(abs(spaceDifference / YEAR_BUTTON_WIDTH)) + 1)
        print("Handling a year resize.")
        print("    Width of stackview theoretically: \(stackViewWidth)")
        print("    Width of scrollView is: \(scrollView_year.bounds.width)")
        print("    Difference in widths is: \(spaceDifference)")
        print("    Buttons to Make: \(buttonsToMake)")
        if spaceDifference < 0 {
            print("Removing buttons")
            for _ in 0..<Int(floor(Double(buttonsToMake)/2)) {
                popPrefixYear()
            }
            for _ in 0..<Int(ceil(Double(buttonsToMake)/2)) {
                popSuffixYear()
            }
        } else if spaceDifference > 0 {
            print("Adding buttons")
            for _ in 0..<Int(floor(Double(buttonsToMake+1)/2)) {
                prefixYear()
            }
            for _ in 0..<Int(ceil(Double(buttonsToMake+1)/2)) {
                suffixYear()
            }
        }
//        alignScrollToYear()
    }
    
    /// Should be called when clipView changes. Will add or remove years as user scrolls towards or away from years
    /// allowing scrollView to scroll infinitely. Boundary check should be very efficient as it gets called
    /// very often when the user is scrolling (with trackpad) the timeline.
    private func boundaryCheck() {
        let scrollX = clipView_year.bounds.origin.x
        let maxScroll = stackView_year.bounds.width - scrollView_year.bounds.width
        
        // Add years as scroll reveals year
        if scrollX < 5 {
            prefixYear()
        } else if scrollX > maxScroll {
            suffixYear()
        }
        // Remove years as scroller hides years
        if (scrollView_year.bounds.width + scrollX) < (CGFloat(stackView_year.arrangedSubviews.count-1) * YEAR_BUTTON_WIDTH) {
            popSuffixYear()
        } else if scrollX > YEAR_BUTTON_WIDTH {
            popPrefixYear()
        }
    }
    
    /// Centers the scroll view on a year in the year stack
    private func alignScrollToYear() {
        // The follow calculation procudes a number always between 0 and YEAR_BUTTON_WIDTH/2
        let centerPoint = clipView_year.bounds.origin.x + YEAR_BUTTON_WIDTH/2
            - (clipView_year.bounds.origin.x + scrollView_year.bounds.width/2).truncatingRemainder(dividingBy: YEAR_BUTTON_WIDTH)
        // Scroll to calculated point
        clipView_year.scroll(to: NSPoint(x: centerPoint, y: 0))
        boundaryCheck()
        // Below lines determine selection: what year button is in direct center of timeline view
        let newIndex = floor((clipView_year.bounds.origin.x + scrollView_year.bounds.width/2) / YEAR_BUTTON_WIDTH)
        if let buttonSelected = stackView_year.arrangedSubviews[Int(newIndex)] as? HXYearButton {
            buttonSelected.select()
            currentYear = buttonSelected.tag
            buttonFall.isEnabled = true
            buttonSpring.isEnabled = true
            let yr = NSCalendar.current.component(.year, from: NSDate() as Date)
            if yr != buttonSelected.tag {
                button_toCurrentYear.isHidden = false
                button_toCurrentYear.isEnabled = true
            } else {
                button_toCurrentYear.isHidden = true
                button_toCurrentYear.isEnabled = false
            }
        }
    }
    
    func selectYear(_ year: Int) {
        receiveStartScrolling()
//        for y in stackView_year.arrangedSubviews {
//            y.removeFromSuperview()
//        }
//        clipView_year.scroll(to: NSPoint(x: 0, y: 0))
//        stackView_year.setFrameSize(NSSize(width: 0, height: stackView_year.bounds.height))
        
        // Animate scrolling timeline
        NSAnimationContext.beginGrouping()
        NSAnimationContext.current().duration = 1
        NSAnimationContext.current().completionHandler = {self.receiveEndScrolling()}
        clipView_year.setFrameOrigin(NSPoint(x: clipView_year.frame.origin.x + YEAR_BUTTON_WIDTH, y: 0))
        NSAnimationContext.endGrouping()
        
        
//        let buttonsLeft = Int(floor((scrollView_year.bounds.width/2) / YEAR_BUTTON_WIDTH + 0.5))
//        earliestYear = year - buttonsLeft
//        latestYear = earliestYear - 1
//        handleYearResize() // then try other way, below this line \/
//        clipView_year.scroll(to: NSPoint(x: YEAR_BUTTON_WIDTH/2, y: 0))
//        receiveEndScrolling()
    }
    func action_clickYear(sender: HXYearButton) {
        selectYear(sender.tag)
    }
    @IBAction func action_goToCurrentYear(_ sender: Any) {
        let yr = NSCalendar.current.component(.year, from: NSDate() as Date)
        selectYear(yr)
    }
    
    // MARK: Semester selection ........................................................................
    @IBAction func action_selectFall(_ sender: Any) {
        semesterSelected = produceSemester(titled: "fall", in: produceYear(currentYear))
        buttonFall.alphaValue = 1
        buttonSpring.alphaValue = 0.3
        imageSemesterToggle.image = #imageLiteral(resourceName: "art_tree_a")
    }
    @IBAction func action_selectSpring(_ sender: Any) {
        semesterSelected = produceSemester(titled: "spring", in: produceYear(currentYear))
        buttonSpring.alphaValue = 1
        buttonFall.alphaValue = 0.3
        imageSemesterToggle.image = #imageLiteral(resourceName: "art_tree_b")
    }
    /// Will return a year that either has been newly created, or
    /// already exists with the given year number.
    private func produceYear(_ year: Int) -> Year{
        // Try fetching this year in persistent store
        let yearFetch = NSFetchRequest<Year>(entityName: "Year")
        do {
            let years = try appDelegate.managedObjectContext.fetch(yearFetch) as [Year]
            if let foundYear = years.filter({$0.year == Int16(year)}).first {
                // This year already present in store so load
                return foundYear
            } else {
                // Create year since it wasn't found
                let newYear = NSEntityDescription.insertNewObject(forEntityName: "Year", into: appDelegate.managedObjectContext) as! Year
                newYear.year = Int16(year)
                return newYear
            }
        } catch { fatalError("Failed to fetch years: \(error)") }
    }
    /// Will return a semester that either has been newly created, or
    /// already exists the given year and title.
    func produceSemester(titled: String, in year: Year) -> Semester {
        // Try finding this semester in year selected
        for case let foundSemester as Semester in year.semesters! {
            if foundSemester.title! == titled {
                return foundSemester
            }
        }
        // Create semester since it wasn't found
        let newSemester = NSEntityDescription.insertNewObject(forEntityName: "Semester", into: appDelegate.managedObjectContext) as! Semester
        newSemester.title = titled
        newSemester.year = year
        return newSemester
    }
}
