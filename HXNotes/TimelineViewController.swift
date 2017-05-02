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
    private let YEAR_CLIP_LEADING: CGFloat = 20
    
    var masterViewController: MasterViewController!
    
    // Models
    private var selectedYearIndex: Int! {
        didSet {
            // Clear previous selection on var set
            if oldValue != nil {
                if (stackView_year.arrangedSubviews.count-1) > oldValue! {
                    if let buttonSelected = stackView_year.arrangedSubviews[oldValue] as? HXYearButton {
                        buttonSelected.deselect()
                        masterViewController.closeCalendar()
                        button_toCurrentYear.isHidden = false
                        button_toCurrentYear.isEnabled = true
                    }
                }
            }
            if selectedYearIndex != nil {
                if (stackView_year.arrangedSubviews.count-1) > selectedYearIndex! {
                    if let buttonSelected = stackView_year.arrangedSubviews[selectedYearIndex!] as? HXYearButton {
                        buttonSelected.select()
                        // Notify masterViewController that user landed on a time
                        masterViewController.selectedYear(years[selectedYearIndex].year)
                        let yr = NSCalendar.current.component(.year, from: NSDate() as Date)
                        if yr != years[selectedYearIndex].year {
                            button_toCurrentYear.isHidden = false
                            button_toCurrentYear.isEnabled = true
                        } else {
                            button_toCurrentYear.isHidden = true
                            button_toCurrentYear.isEnabled = false
                        }
                    }
                }
            }
        }
    }
    private var years = [Year]()
    private var earliestYear = 1993
    private var latestYear = 1992

    override func viewDidLoad() {
        super.viewDidLoad()
        
        for s in stackView_year.subviews {
            s.removeFromSuperview()
        }
        stackView_year.setFrameSize(NSSize(width: 0, height: stackView_year.bounds.height))
        
        // Setup observers for timeline scrolling - start/active/end scrolling years
        NotificationCenter.default.addObserver(self, selector: #selector(TimelineViewController.receiveStartScrolling),
                                               name: .NSScrollViewWillStartLiveScroll, object: scrollView_year)
        NotificationCenter.default.addObserver(self, selector: #selector(TimelineViewController.receiveActiveScrolling),
                                               name: .NSScrollViewDidLiveScroll, object: scrollView_year)
        NotificationCenter.default.addObserver(self, selector: #selector(TimelineViewController.receiveEndScrolling),
                                               name: .NSScrollViewDidEndLiveScroll, object: scrollView_year)
    }
    
    // MARK: Observer notications from year scrollView .............................................................................
    /// Receives NSScrollViewWillStartLiveScroll notifications
    func receiveStartScrolling() {
        selectedYearIndex = nil
    }
    /// Receives NSScrollViewDidLiveScroll notifications
    func receiveActiveScrolling() {
        boundryCheck()
        print("\(earliestYear) - \(latestYear)")
    }
    /// Receives NSScrollViewDidEndLiveScroll notifications
    func receiveEndScrolling() {
        // Below line determines selection: what year button is in direct center of timeline view
        let newIndex = floor((clipView_year.bounds.origin.x + scrollView_year.bounds.width/2 - YEAR_CLIP_LEADING) / YEAR_BUTTON_WIDTH)
        selectedYearIndex = Int(newIndex)
        
        alignScrollToYear()
    }
    
    // MARK: Adding/Removing years from year stackView ..............................................................................
    /// Add earlier year
    func prefixYear() {
        let newYearButton = HXYearButton(withYear: earliestYear - 1)
        newYearButton.target = self
        newYearButton.action = #selector(TimelineViewController.action_clickYear(sender:))
        years.insert(Year(earliestYear - 1), at: 0)
        earliestYear -= 1
        stackView_year.insertArrangedSubview(newYearButton, at: 0)
        clipView_year.bounds.origin.x += YEAR_BUTTON_WIDTH
    }
    /// Add later year
    func suffixYear() {
        let newYearButton = HXYearButton(withYear: latestYear + 1)
        newYearButton.target = self
        newYearButton.action = #selector(TimelineViewController.action_clickYear(sender:))
        years.append(Year(latestYear + 1))
        latestYear += 1
        stackView_year.addArrangedSubview(newYearButton)
    }
    /// Remove earlier year
    func popPrefixYear() {
        years.remove(at: 0)
        earliestYear += 1
        stackView_year.arrangedSubviews[0].removeFromSuperview()
        
        clipView_year.bounds = NSRect(origin: CGPoint(x: clipView_year.bounds.origin.x - YEAR_BUTTON_WIDTH, y: clipView_year.bounds.origin.y), size: clipView_year.bounds.size)
    }
    /// Remove later year
    func popSuffixYear() {
        if years.count > 0 {
            years.removeLast()
            latestYear -= 1
            if stackView_year.arrangedSubviews.count > 0 {
                stackView_year.arrangedSubviews[stackView_year.arrangedSubviews.count-1].removeFromSuperview()
            }
        }
    }
    
    // MARK: Handling year scrollView resizing and scrolling .............................................................................
    override func viewDidLayout() {
        super.viewDidLayout()
        
        handleYearResize()
        alignScrollToYear()
    }
    
    /// In one call, will populate or remove as many years as necessary to fit year stackView to new window width.
    func handleYearResize() {
        let spaceDifference = scrollView_year.bounds.width - (stackView_year.bounds.width + YEAR_CLIP_LEADING)
        let buttonsToMake = Int(abs(spaceDifference / YEAR_BUTTON_WIDTH))
        
        if spaceDifference < 0 {
            for _ in 0..<buttonsToMake {
                popSuffixYear()
            }
        } else if spaceDifference > 0 {
            for _ in 0..<(buttonsToMake + 1) {
                suffixYear()
            }
        }
    }
    
    /// Should be called when scrolling. Will add or remove years as user scrolls towards or away from years
    /// allowing scrollView to scroll infinitely.
    func boundryCheck() {
        let scrollX = clipView_year.bounds.origin.x
        let maxScroll = stackView_year.bounds.width + YEAR_CLIP_LEADING - scrollView_year.bounds.width
        
        if scrollX < 0 {
            prefixYear()
        } else if scrollX > maxScroll {
            suffixYear()
        }
        // Remove years as scroller hides years
        if (scrollView_year.bounds.width + scrollX) < (stackView_year.bounds.width - YEAR_BUTTON_WIDTH) {
            popSuffixYear()
        } else if scrollX > YEAR_BUTTON_WIDTH {
            popPrefixYear()
        }
    }
    
    /// Centers the scroll view on a year in the year stack
    func alignScrollToYear() {
        // Calculate the point centered on nearest year button
        let centerPoint = clipView_year.bounds.origin.x + YEAR_BUTTON_WIDTH/2
            - (clipView_year.bounds.origin.x + scrollView_year.bounds.width/2 - YEAR_CLIP_LEADING).truncatingRemainder(dividingBy: YEAR_BUTTON_WIDTH)
        // Scroll to calculated point
        clipView_year.scroll(to: NSPoint(x: centerPoint, y: 0))
    }
    
    func selectYear(_ year: Int) {
        for y in stackView_year.arrangedSubviews {
            y.removeFromSuperview()
        }
        years.removeAll()
        clipView_year.scroll(to: NSPoint(x: 0, y: 0))
        stackView_year.setFrameSize(NSSize(width: 0, height: stackView_year.bounds.height))
        let buttonsLeft = Int(floor(scrollView_year.bounds.width/2 / YEAR_BUTTON_WIDTH))
        earliestYear = year - buttonsLeft
        latestYear = earliestYear - 1
        handleYearResize()
        receiveEndScrolling()
    }
    func action_clickYear(sender: HXYearButton) {
        if years[selectedYearIndex].year != sender.tag {
            selectYear(sender.tag)
        }
    }
    @IBAction func action_goToCurrentYear(_ sender: Any) {
        let yr = NSCalendar.current.component(.year, from: NSDate() as Date)
        selectYear(yr)
    }
    
    // MARK: Semester selection
    
//    private func semesterEditChange(to semester: String) {
//        masterViewController.editSemester(semester)
//        self.view.removeFromSuperview()
//    }
    @IBAction func action_selectFall(_ sender: Any) {
        masterViewController.editSemester("fall")
        buttonFall.alphaValue = 1
        buttonSpring.alphaValue = 0.3
        imageSemesterToggle.image = #imageLiteral(resourceName: "art_tree_a")
    }
    @IBAction func action_selectSpring(_ sender: Any) {
        masterViewController.editSemester("spring")
        buttonSpring.alphaValue = 1
        buttonFall.alphaValue = 0.3
        imageSemesterToggle.image = #imageLiteral(resourceName: "art_tree_b")
    }
}
