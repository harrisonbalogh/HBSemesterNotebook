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
    
    // Models
    private var earliestYear = 1993
    private var latestYear = 1992
    private var currentYear = 1993

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
    /// Receives NSScrollViewDidLiveScroll notifications
    func receiveActiveScrolling() {
        boundaryCheck()
    }
    /// Receives NSScrollViewDidEndLiveScroll notifications
    func receiveEndScrolling() {
        alignScrollToYear()
    }
    
    // MARK: Adding/Removing years from year stackView ..............................................................................
    /// Add earlier year
    private func prefixYear() {
        let newYearButton = HXYearButton(withYear: earliestYear - 1)
        newYearButton.target = self
        newYearButton.action = #selector(TimelineViewController.action_clickYear(sender:))
        earliestYear -= 1
        stackView_year.insertArrangedSubview(newYearButton, at: 0)
        clipView_year.bounds.origin.x += YEAR_BUTTON_WIDTH
    }
    /// Add later year
    private func suffixYear() {
        let newYearButton = HXYearButton(withYear: latestYear + 1)
        newYearButton.target = self
        newYearButton.action = #selector(TimelineViewController.action_clickYear(sender:))
        latestYear += 1
        stackView_year.addArrangedSubview(newYearButton)
    }
    /// Remove earlier year
    private func popPrefixYear() {
        if stackView_year.arrangedSubviews.count > 0 {
            earliestYear += 1
            stackView_year.arrangedSubviews[0].removeFromSuperview()
        }
        // Correct year scroller to remain in same place after inserting new year to front of stack
        clipView_year.bounds = NSRect(origin: CGPoint(x: clipView_year.bounds.origin.x - YEAR_BUTTON_WIDTH, y: clipView_year.bounds.origin.y), size: clipView_year.bounds.size)
    }
    /// Remove later year
    private func popSuffixYear() {
        if stackView_year.arrangedSubviews.count > 0 {
            latestYear -= 1
            stackView_year.arrangedSubviews[stackView_year.arrangedSubviews.count-1].removeFromSuperview()
        }
    }
    
    // MARK: Handling year scrollView resizing and scrolling .............................................................................
    override func viewDidLayout() {
        super.viewDidLayout()
        
        selectYear(currentYear)
    }
    override func viewDidAppear() {
        super.viewDidAppear()
        
        action_goToCurrentYear(self)
    }
    
    /// In one call, will populate or remove as many years as necessary to fit year stackView to new window width.
    private func handleYearResize() {
        let spaceDifference = scrollView_year.bounds.width - (stackView_year.bounds.width + YEAR_CLIP_LEADING)
        let buttonsToMake = Int(abs(spaceDifference / YEAR_BUTTON_WIDTH)) + 1
        
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
    /// allowing scrollView to scroll infinitely. Boundary check should be very efficient as it gets called
    /// very often when the user is scrolling (with trackpad) the timeline.
    private func boundaryCheck() {
        let scrollX = clipView_year.bounds.origin.x
        let maxScroll = stackView_year.bounds.width + YEAR_CLIP_LEADING - scrollView_year.bounds.width
        
        // Add years as scroll reveals year
        if scrollX < 5 {
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
    private func alignScrollToYear() {
        let centerPoint = clipView_year.bounds.origin.x + YEAR_BUTTON_WIDTH/2
            - (clipView_year.bounds.origin.x + scrollView_year.bounds.width/2 - YEAR_CLIP_LEADING).truncatingRemainder(dividingBy: YEAR_BUTTON_WIDTH)
        // Scroll to calculated point
        clipView_year.scroll(to: NSPoint(x: centerPoint, y: 0))
        boundaryCheck()
        // Below lines determine selection: what year button is in direct center of timeline view
        let newIndex = floor((clipView_year.bounds.origin.x + scrollView_year.bounds.width/2 - YEAR_CLIP_LEADING) / YEAR_BUTTON_WIDTH)
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
        for y in stackView_year.arrangedSubviews {
            y.removeFromSuperview()
        }
        clipView_year.scroll(to: NSPoint(x: 0, y: 0))
        stackView_year.setFrameSize(NSSize(width: 0, height: stackView_year.bounds.height))
        let buttonsLeft = Int(floor((scrollView_year.bounds.width/2 - YEAR_CLIP_LEADING) / YEAR_BUTTON_WIDTH + 0.5))
        earliestYear = year - buttonsLeft
        latestYear = earliestYear - 1
        handleYearResize() // then try other way, below this line \/
        clipView_year.scroll(to: NSPoint(x: YEAR_BUTTON_WIDTH/2, y: 0))
        receiveEndScrolling()
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
        if let masterViewController = self.parent! as? MasterViewController {
            masterViewController.selectYear(currentYear)
            masterViewController.selectSemester("fall")
            buttonFall.alphaValue = 1
            buttonSpring.alphaValue = 0.3
            imageSemesterToggle.image = #imageLiteral(resourceName: "art_tree_a")
        }
    }
    @IBAction func action_selectSpring(_ sender: Any) {
        if let masterViewController = self.parent! as? MasterViewController {
            masterViewController.selectYear(currentYear)
            masterViewController.selectSemester("spring")
            buttonSpring.alphaValue = 1
            buttonFall.alphaValue = 0.3
            imageSemesterToggle.image = #imageLiteral(resourceName: "art_tree_b")
        }
    }
}
