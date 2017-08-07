//
//  HXFindViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/4/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXFindViewController: NSViewController {
    
    static var lastFindUsed: String = ""
    
    // For a single selected lecture...........................
    // Find count is the number of occurances of the given string
    var foundIndices = [Int]()
    // Find index is which occurence user is currently looking at
    var findIndex = -1
    // The string being searched for
    
    // For all lectures.........................................
    // First dimension is index of lectureVC and second dimension is number of found indices in that lectureVC
    var foundLecturesToFoundIndices = [[Int]]()
    // The first number is the index of the lectureVC currently looked at the second is the foundIndex currently looking at
    var lectureIndex = [0, -1]
    var totalFound = 0
    
    var findString = "" {
        didSet {
            if findString == "" {
                label_result.stringValue = ""
                return
            }
            // If owned by a LectureVC
            if let parent = self.parent as? LectureCollectionViewItem {
                var searchThroughText = parent.textView_lecture.string!
                foundIndices = [Int]()
                findIndex = -1
                var loc = searchThroughText.lowercased().range(of: findString)
                var indexFound = 0
                while loc != nil {
                    indexFound += searchThroughText.distance(from: searchThroughText.startIndex, to: loc!.lowerBound)
                    foundIndices.append(indexFound)
                    searchThroughText = searchThroughText.substring(from: loc!.upperBound)
                    indexFound += findString.characters.count
                    loc = searchThroughText.lowercased().range(of: findString)
                }
                label_result.stringValue = "\(foundIndices.count) Found"
            // If owned by a TopbarVC
            } else if let parent = self.parent as? EditorViewController {
                foundLecturesToFoundIndices = [[Int]]()
                lectureIndex = [0, -1]
                var controllerIndex = 0
//                for case let lectureVC as LectureViewController in parent.childViewControllers {
//                    foundLecturesToFoundIndices.append([Int]())
//                    var searchThroughText = lectureVC.textView_lecture.string!
//                    var loc = searchThroughText.lowercased().range(of: findString)
//                    var indexFound = 0
//                    while loc != nil {
//                        indexFound += searchThroughText.distance(from: searchThroughText.startIndex, to: loc!.lowerBound)
//                        foundLecturesToFoundIndices[controllerIndex].append(indexFound)
//                        totalFound += 1
//                        searchThroughText = searchThroughText.substring(from: loc!.upperBound)
//                        indexFound += findString.characters.count
//                        loc = searchThroughText.lowercased().range(of: findString)
//                    }
//                    controllerIndex += 1
//                }
                label_result.stringValue = "\(totalFound) Found"
            }
        }
    }
    
    @IBOutlet weak var label_lectureSelection: NSTextField!
    @IBOutlet weak var label_result: NSTextField!
    @IBOutlet weak var textField_find: NSTextField!
    @IBOutlet weak var button_right: NSButton!
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        // If owned by a LectureVC
        if self.parent is LectureCollectionViewItem {
            
            label_lectureSelection.stringValue = "selected lecture."
            textField_find.stringValue = HXFindViewController.lastFindUsed

        // If owned by a TopbarVC
        } else if self.parent is EditorViewController {
            
            label_lectureSelection.stringValue = "all lectures."
            textField_find.stringValue = HXFindViewController.lastFindUsed
            HXFindViewController.lastFindUsed = ""
            
        }
        
        label_result.stringValue = ""
        
        // Listen to textField changing to know when to reset counter
        NotificationCenter.default.addObserver(self, selector: #selector(HXFindViewController.textField_textChange),
                                               name: .NSControlTextDidChange, object: textField_find)
    }
    /// Should reset all variables when changing text
    func textField_textChange() {
        foundIndices = [Int]()
        totalFound = 0
        findString = ""
    }
    @IBAction func action_close(_ sender: NSButton) {
        if let parent = self.parent as? LectureCollectionViewItem {
            parent.isFinding = false
        } else if let parent = self.parent as? EditorViewController {
            parent.isFinding = false
        }
    }
    @IBAction func action_right(_ sender: NSButton) {
        if foundIndices.count != 0 && parent is LectureCollectionViewItem {
            
            // If owned by a LectureVC
            if let parent = self.parent as? LectureCollectionViewItem {
                if findIndex >= foundIndices.count - 1 {
                    findIndex = 0
                } else {
                    findIndex += 1
                }
                parent.textView_lecture.setSelectedRange(NSMakeRange(foundIndices[findIndex], findString.characters.count))
                checkScrollLevel(for: parent)
            }
        } else if totalFound != 0 && parent is EditorViewController {
            
            // Find first lecture that has occurrences
            while foundLecturesToFoundIndices[lectureIndex[0]].count == 0 {
                if lectureIndex[0] >= foundLecturesToFoundIndices.count - 1 {
                    lectureIndex[0] = 0
                } else {
                    lectureIndex[0] += 1
                }
            }
            
            // If owned by a TopbarVC
            if let parent = self.parent as? EditorViewController {
//                var lectureVC = parent.childViewControllers[lectureIndex[0]] as! LectureViewController
//                // Check if currently checking occurence is beyond number of occurences. Reset to zero.
//                if lectureIndex[1] >= foundLecturesToFoundIndices[lectureIndex[0]].count - 1 {
//                    lectureIndex[1] = 0
//                    // Reset occurrence count, so want to move to next lectureVC, find next one that has occurrences
//                    // Also reset selection of last lectureVC
//                    lectureVC.textView_lecture.setSelectedRange(NSMakeRange(0, 0))
//                    repeat {
//                        if lectureIndex[0] >= foundLecturesToFoundIndices.count - 1 {
//                            lectureIndex[0] = 0
//                        } else {
//                            lectureIndex[0] += 1
//                        }
//                    } while foundLecturesToFoundIndices[lectureIndex[0]].count == 0
//                    
//                } else {
//                    // Else increment to next occurrence
//                    lectureIndex[1] += 1
//                }
//                lectureVC = parent.childViewControllers[lectureIndex[0]] as! LectureViewController
//                lectureVC.textView_lecture.setSelectedRange(NSMakeRange(foundLecturesToFoundIndices[lectureIndex[0]][lectureIndex[1]], findString.characters.count))
//                checkScrollLevel(for: lectureVC)
            }
        } else if findString != textField_find.stringValue && textField_find.stringValue != "" {
            
            findString = textField_find.stringValue
            action_right(sender)
        }
    }
    @IBAction func action_left(_ sender: NSButton) {
        if foundIndices.count != 0 {
            
            // If owned by a LectureVC
            if let parent = self.parent as? LectureCollectionViewItem{
                if findIndex <= 0 {
                    findIndex = foundIndices.count - 1
                } else {
                    findIndex -= 1
                }
                parent.textView_lecture.setSelectedRange(NSMakeRange(foundIndices[findIndex], findString.characters.count))
                checkScrollLevel(for: parent)
            }
        } else if totalFound != 0 {
            // Find first lecture that has occurrences
            while foundLecturesToFoundIndices[lectureIndex[0]].count == 0 {
                if lectureIndex[0] <= 0 {
                    lectureIndex[0] = foundLecturesToFoundIndices.count - 1
                } else {
                    lectureIndex[0] -= 1
                }
            }
            
            // If owned by a TopbarVC
            if let parent = self.parent as? EditorViewController {
//                var lectureVC = parent.childViewControllers[lectureIndex[0]] as! LectureViewController
//                // Check if currently checking occurence is below 0. Reset to previous lecture's count.
//                if lectureIndex[1] <= 0 {
//                    // Reset occurrence count, so want to move to previous lectureVC, find previous one that has occurrences
//                    // Also reset selection of previous lectureVC
//                    lectureVC.textView_lecture.setSelectedRange(NSMakeRange(0, 0))
//                    repeat {
//                        if lectureIndex[0] <= 0 {
//                            lectureIndex[0] = foundLecturesToFoundIndices.count - 1
//                        } else {
//                            lectureIndex[0] -= 1
//                        }
//                    } while foundLecturesToFoundIndices[lectureIndex[0]].count == 0
//                    lectureIndex[1] = foundLecturesToFoundIndices[lectureIndex[0]].count - 1
//                } else {
//                    // Else decrement to previous occurrence
//                    lectureIndex[1] -= 1
//                }
//                lectureVC = parent.childViewControllers[lectureIndex[0]] as! LectureViewController
//                lectureVC.textView_lecture.setSelectedRange(NSMakeRange(foundLecturesToFoundIndices[lectureIndex[0]][lectureIndex[1]], findString.characters.count))
//                checkScrollLevel(for: lectureVC)
            }
        } else if findString != textField_find.stringValue && textField_find.stringValue != "" {
            
            findString = textField_find.stringValue
            action_left(sender)
        }
    }
    @IBAction func action_select(_ sender: NSButton) {
        if let parent = self.parent as? LectureCollectionViewItem {
            HXFindViewController.lastFindUsed = textField_find.stringValue
            parent.isFinding = false
            parent.owner.isFinding = true
        } else if let parent = self.parent as? EditorViewController {
            parent.isFinding = false
            if parent.lectureFocused != nil {
                parent.lectureFocused.isFinding = true
            }
        }
    }
    @IBAction func action_textField(_ sender: NSTextField) {
        if foundIndices.count != 0 || totalFound != 0 {
            action_right(button_right)
        } else if findString != sender.stringValue && sender.stringValue != "" {
            findString = sender.stringValue
            action_right(button_right)
        }
    }
    /// Revised version of LectureVC's textSelectionHeight() method
    private func textSelectionHeight(for lecVC: LectureCollectionViewItem) -> CGFloat {
        let positionOfSelection = lecVC.textView_lecture.selectedRanges.first!.rangeValue.location
        let rangeToSelection = NSRange(location: 0, length: positionOfSelection)
        let substring = lecVC.textView_lecture.attributedString().attributedSubstring(from: rangeToSelection)
        let txtStorage = NSTextStorage(attributedString: substring)
        let txtContainer = NSTextContainer(containerSize: NSSize(width: lecVC.textView_lecture.frame.width, height: 10000))
        let layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(txtContainer)
        txtStorage.addLayoutManager(layoutManager)
        txtStorage.addAttributes([NSFontAttributeName: lecVC.textView_lecture.font!], range: NSRange(location: 0, length: txtStorage.length))
        txtContainer.lineFragmentPadding = 0
        layoutManager.glyphRange(for: txtContainer)
        return lecVC.view.frame.origin.y + lecVC.view.frame.height - (layoutManager.usedRect(for: txtContainer).size.height + 39) // height from top of lecture view to top of text
    }
    /// Auto scrolling whenever user types. Smoothly scroll clipper until text typing location is centered.
    private func checkScrollLevel(for sender: LectureCollectionViewItem) {
//        let selectionY = textSelectionHeight(for: sender)
//        // Center current typing position to center of lecture scroller
//        let yPos = sender.owner.lectureStack.frame.height - selectionY // - lectureScroller.frame.height/2
//        // Don't auto-scroll if selection is already visible and above center line of window
//        if yPos < (sender.owner.lectureClipper.bounds.origin.y + sender.header.frame.height) || yPos > (sender.owner.lectureClipper.bounds.origin.y + sender.owner.lectureScroller.frame.height/2) {
//            NSAnimationContext.beginGrouping()
//            NSAnimationContext.current().duration = 0.2
//            // Get clipper to center selection in scroller
//            sender.owner.lectureClipper.animator().setBoundsOrigin(NSPoint(x: 0, y: yPos - sender.owner.lectureScroller.frame.height/2))
//            NSAnimationContext.endGrouping()
//        }
    }
}
