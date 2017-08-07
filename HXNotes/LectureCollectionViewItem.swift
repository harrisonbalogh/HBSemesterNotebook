//
//  LectureCollectionViewItem.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/3/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class LectureCollectionViewItem: NSCollectionViewItem {
    
    weak var lecture: Lecture!
    
    weak var owner: EditorViewController!
    
    weak var header: LectureHeaderView!
    
    @IBOutlet weak var box_dropdown: NSBox!
    @IBOutlet weak var dropdownTopConstraint: NSLayoutConstraint!
    
    var textView_lecture: HXTextView!
    
    var image_corner1: NSImageView!
    var image_corner2: NSImageView!
    var image_corner3: NSImageView!
    var image_corner4: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        print("VIEW DID LOAD")
        
        findViewController = HXFindViewController(nibName: "HXFindView", bundle: nil)
        self.addChildViewController(findViewController)
        exportViewController = HXExportViewController(nibName: "HXExportView", bundle: nil)
        self.addChildViewController(exportViewController)
        replaceViewController = HXFindReplaceViewController(nibName: "HXFindReplaceView", bundle: nil)
        self.addChildViewController(replaceViewController)
        
        view.wantsLayer = true
        
        // Setup textview that isn't embedded in a ScrollView
        textView_lecture = HXTextView()
        textView_lecture.translatesAutoresizingMaskIntoConstraints = false
        textView_lecture.drawsBackground = false
        textView_lecture.importsGraphics = true
        
        NotificationCenter.default.addObserver(self, selector: #selector(LectureCollectionViewItem.notifyTextViewChange),
                                               name: .NSTextDidChange, object: textView_lecture)
        
        self.view.addSubview(textView_lecture)
        textView_lecture.topAnchor.constraint(equalTo: box_dropdown.bottomAnchor, constant: 9).isActive = true
        textView_lecture.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
        textView_lecture.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: -6).isActive = true
        textView_lecture.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        
        image_corner1 = NSImageView(image: #imageLiteral(resourceName: "image_corner_1"))
        image_corner2 = NSImageView(image: #imageLiteral(resourceName: "image_corner_2"))
        image_corner3 = NSImageView(image: #imageLiteral(resourceName: "image_corner_3"))
        image_corner4 = NSImageView(image: #imageLiteral(resourceName: "image_corner_4"))
        image_corner1.translatesAutoresizingMaskIntoConstraints = false
        image_corner2.translatesAutoresizingMaskIntoConstraints = false
        image_corner3.translatesAutoresizingMaskIntoConstraints = false
        image_corner4.translatesAutoresizingMaskIntoConstraints = false
        
        self.view.addSubview(image_corner1)
        self.view.addSubview(image_corner2)
        self.view.addSubview(image_corner3)
        self.view.addSubview(image_corner4)
        
        image_corner1.leadingAnchor.constraint(equalTo: textView_lecture.leadingAnchor, constant: 1).isActive = true
        image_corner1.topAnchor.constraint(equalTo: textView_lecture.topAnchor, constant: -3).isActive = true
        image_corner1.widthAnchor.constraint(equalToConstant: 21).isActive = true
        image_corner1.heightAnchor.constraint(equalToConstant: 21).isActive = true
        
        image_corner2.trailingAnchor.constraint(equalTo: textView_lecture.trailingAnchor, constant: -1).isActive = true
        image_corner2.topAnchor.constraint(equalTo: textView_lecture.topAnchor, constant: -3).isActive = true
        image_corner2.widthAnchor.constraint(equalToConstant: 21).isActive = true
        image_corner2.heightAnchor.constraint(equalToConstant: 21).isActive = true
        
        image_corner3.trailingAnchor.constraint(equalTo: textView_lecture.trailingAnchor, constant: -1).isActive = true
        image_corner3.bottomAnchor.constraint(equalTo: textView_lecture.bottomAnchor, constant: 1).isActive = true
        image_corner3.widthAnchor.constraint(equalToConstant: 21).isActive = true
        image_corner3.heightAnchor.constraint(equalToConstant: 21).isActive = true
        
        image_corner4.leadingAnchor.constraint(equalTo: textView_lecture.leadingAnchor, constant: 1).isActive = true
        image_corner4.bottomAnchor.constraint(equalTo: textView_lecture.bottomAnchor, constant: 1).isActive = true
        image_corner4.widthAnchor.constraint(equalToConstant: 21).isActive = true
        image_corner4.heightAnchor.constraint(equalToConstant: 21).isActive = true
        
        image_corner1.alphaValue = 0
        image_corner2.alphaValue = 0
        image_corner3.alphaValue = 0
        image_corner4.alphaValue = 0
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        owner.notifyHeightUpdate()
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
        
//        // Update height of view - Distinguish this from textHeight() method
//        // Important to calculate height when text container is given a very large height to work with (99999)
//        // when laying out. textHeight() should be faster (untested) as it creates far fewer temp objects
//        let txtStorage = NSTextStorage(attributedString: textView_lecture.attributedString())
//        let txtContainer = NSTextContainer(containerSize: NSSize(width: textView_lecture.frame.width, height: 99999))
//        let layoutManager = NSLayoutManager()
//        layoutManager.addTextContainer(txtContainer)
//        txtStorage.addLayoutManager(layoutManager)
//        txtStorage.addAttributes([NSFontAttributeName: textView_lecture.font!], range: NSRange(location: 0, length: txtStorage.length))
//        txtContainer.lineFragmentPadding = 0
//        layoutManager.glyphRange(for: txtContainer)
//        // 3 is arbitrary bottom buffer space added
//        let textHeight = layoutManager.usedRect(for: txtContainer).size.height + 3
//        
//        textHeightConstraint.constant = textHeight
    }
    
    // MARK: - ––– Auto Scroll and Resizing Helper Functions –––
    
    /// Return the height to the selected character in the textView
    internal func textSelectionHeight() -> CGFloat {
        //        if !self.isStyling {
        //            // If user is not actively editing this lecture's textView, then the request to get selection
        //            // height came from a clipView resize, not from the user changing the textView text.
        //            return 0
        //        }
        let positionOfSelection = textView_lecture.selectedRanges.first!.rangeValue.location
        let rangeToSelection = NSRange(location: 0, length: positionOfSelection)
        let substring = textView_lecture.attributedString().attributedSubstring(from: rangeToSelection)
        let txtStorage = NSTextStorage(attributedString: substring)
        let txtContainer = NSTextContainer(containerSize: NSSize(width: textView_lecture.frame.width, height: 10000))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(txtContainer)
        txtStorage.addLayoutManager(layoutManager)
        txtStorage.addAttributes([NSFontAttributeName: textView_lecture.font!], range: NSRange(location: 0, length: txtStorage.length))
        txtContainer.lineFragmentPadding = 0
        layoutManager.glyphRange(for: txtContainer)
        return view.frame.origin.y + textView_lecture.frame.origin.y + layoutManager.usedRect(for: txtContainer).size.height // height from top of lecture view to top of text
    }
    /// Return the height of all the text in the textView
    func textHeight() -> CGFloat {
        return textView_lecture.layoutManager!.usedRect(for: textView_lecture.textContainer!).size.height + 18
        // 3 is arbitrary bottom buffer space added
    }
    
    // MARK: - ––– Styling –––
    
    func styleUnderline(_ sender: NSButton) {
        textView_lecture.underline(self)
        textView_lecture.needsDisplay = true
    }
    ///
    func styleLeft(_ sender: NSButton) {
        textView_lecture.alignLeft(self)
    }
    ///
    func styleCenter(_ sender: NSButton) {
        textView_lecture.alignCenter(self)
    }
    ///
    func styleRight(_ sender: NSButton) {
        textView_lecture.alignRight(self)
    }
    
    // MARK: - ––– Notifiers –––
    
    /// Any time the textview text changes, this will resize the textView height and the owning EditorVC's
    /// stack height. Will also update the object model with the new attributed string.
    func notifyTextViewChange() {
        
        // Update height of view
        owner.collectionView.collectionViewLayout?.invalidateLayout()
        
//        print("notifyTextViewChange")
        
//        let newHeight = textHeight()
//        if newHeight != textHeightConstraint.constant {
//            textHeightConstraint.constant = newHeight
//            owner.notifyHeightUpdate()
//        }
        
        // Save to Model
        lecture.content = textView_lecture.attributedString()
        owner.checkScrollLevel(from: self)
        // Update styling buttons
//        header.selectionChange()
    }
    
    /// Displays styling button visuals when this function receives focus as true.
    func notifyTextViewFocus(_ focus: Bool) {
        if focus {
            owner.lectureFocused = self
            
            // Animate revealing corner images
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 1
            image_corner1.animator().alphaValue = 1
            image_corner2.animator().alphaValue = 1
            image_corner3.animator().alphaValue = 1
            image_corner4.animator().alphaValue = 1
            NSAnimationContext.endGrouping()
            
        } else {
            
            // Animate hiding corner images
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 1
            image_corner1.animator().alphaValue = 0
            image_corner2.animator().alphaValue = 0
            image_corner3.animator().alphaValue = 0
            image_corner4.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
            
            if owner.lectureFocused == self {
                owner.lectureFocused = nil
            }
        }
    }
    
    // MARK: - ––– Find Replace Print Export –––
    
    /// Produces a formatted RTFD file and places it at the provided URL.
    func export(to url: URL) {
        let attribString = NSMutableAttributedString()
        // Use currently focused lecture
        attribString.append(header.label_lectureTitle.attributedStringValue)
        if header.label_customTitle.stringValue != "" {
            attribString.append(NSAttributedString(string: "  -  " + header.label_customTitle.stringValue + "\n"))
        } else {
            attribString.append(NSAttributedString(string: "\n"))
        }
        attribString.append(NSAttributedString(string: header.label_lectureDate.stringValue + "\n\n"))
        attribString.append(textView_lecture.attributedString())
        
        let fullRange = NSRange(location: 0, length: attribString.length)
        do {
            let data = try attribString.fileWrapper(from: fullRange, documentAttributes: [NSDocumentTypeDocumentAttribute: NSRTFDTextDocumentType])
            try data.write(to: url, options: .atomic, originalContentsURL: nil) // this for rtfd
        } catch {
            print("Something went wrong.")
        }
    }
    
    var findViewController: HXFindViewController!
    var replaceViewController: HXFindReplaceViewController!
    var exportViewController: HXExportViewController!
    
    var isFinding = false {
        didSet {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            NSAnimationContext.current().duration = 0.25
            if isFinding && (isExporting || isReplacing) {
                if isExporting {
                    isExporting = false
                } else {
                    isReplacing = false
                }
            } else if isFinding {
                box_dropdown.addSubview(findViewController.view)
                findViewController.view.leadingAnchor.constraint(equalTo: box_dropdown.leadingAnchor).isActive = true
                findViewController.view.trailingAnchor.constraint(equalTo: box_dropdown.trailingAnchor).isActive = true
                findViewController.view.topAnchor.constraint(equalTo: box_dropdown.topAnchor).isActive = true
                findViewController.view.bottomAnchor.constraint(equalTo: box_dropdown.bottomAnchor).isActive = true
                
                NSAnimationContext.current().completionHandler = {
                    NSApp.keyWindow?.makeFirstResponder(self.findViewController.textField_find)
                }
                dropdownTopConstraint.animator().constant = box_dropdown.frame.height
                
                owner.notifyLectureSelection(lecture: header.label_lectureTitle.stringValue)
            } else {
                if NSApp.keyWindow?.firstResponder == findViewController.textField_find {
                    NSApp.keyWindow?.makeFirstResponder(self)
                }
                NSAnimationContext.current().completionHandler = {
                    self.findViewController.view.removeFromSuperview()
                    if self.isExporting {
                        self.isExporting = true
                    } else if self.isReplacing {
                        self.isReplacing = true
                    }
                }
                dropdownTopConstraint.animator().constant = 0
            }
            NSAnimationContext.endGrouping()
        }
    }
    var isReplacing = false {
        didSet {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            NSAnimationContext.current().duration = 0.25
            if isReplacing && (isExporting || isFinding) {
                if isExporting {
                    isExporting = false
                } else {
                    isFinding = false
                }
            } else if isReplacing {
                box_dropdown.addSubview(replaceViewController.view)
                replaceViewController.view.leadingAnchor.constraint(equalTo: box_dropdown.leadingAnchor).isActive = true
                replaceViewController.view.trailingAnchor.constraint(equalTo: box_dropdown.trailingAnchor).isActive = true
                replaceViewController.view.topAnchor.constraint(equalTo: box_dropdown.topAnchor).isActive = true
                replaceViewController.view.bottomAnchor.constraint(equalTo: box_dropdown.bottomAnchor).isActive = true
                
                NSAnimationContext.current().completionHandler = {
                    NSApp.keyWindow?.makeFirstResponder(self.replaceViewController.textField_find)
                }
                dropdownTopConstraint.animator().constant = box_dropdown.frame.height
                
                owner.notifyLectureSelection(lecture: header.label_lectureTitle.stringValue)
            } else {
                if NSApp.keyWindow?.firstResponder == findViewController.textField_find {
                    NSApp.keyWindow?.makeFirstResponder(self)
                }
                NSAnimationContext.current().completionHandler = {
                    self.replaceViewController.view.removeFromSuperview()
                    if self.isExporting {
                        self.isExporting = true
                    } else if self.isFinding {
                        self.isFinding = true
                    }
                }
                dropdownTopConstraint.animator().constant = 0
            }
            NSAnimationContext.endGrouping()
        }
    }
    var isExporting = false {
        didSet {
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
            NSAnimationContext.current().duration = 0.25
            if isExporting && isFinding {
                isFinding = false
            } else if isExporting {
                box_dropdown.addSubview(exportViewController.view)
                exportViewController.view.leadingAnchor.constraint(equalTo: box_dropdown.leadingAnchor).isActive = true
                exportViewController.view.trailingAnchor.constraint(equalTo: box_dropdown.trailingAnchor).isActive = true
                exportViewController.view.topAnchor.constraint(equalTo: box_dropdown.topAnchor).isActive = true
                exportViewController.view.bottomAnchor.constraint(equalTo: box_dropdown.bottomAnchor).isActive = true
                
                dropdownTopConstraint.animator().constant = box_dropdown.frame.height
                
                owner.notifyLectureSelection(lecture: header.label_lectureTitle.stringValue)
            } else {
                if NSApp.keyWindow?.firstResponder == exportViewController.textField_name {
                    NSApp.keyWindow?.makeFirstResponder(self)
                }
                NSAnimationContext.current().completionHandler = {
                    self.exportViewController.view.removeFromSuperview()
                    if self.isFinding {
                        self.isFinding = true
                    } else if self.isReplacing {
                        self.isReplacing = true
                    }
                }
                dropdownTopConstraint.animator().constant = 0
            }
            NSAnimationContext.endGrouping()
        }
    }
    
}
