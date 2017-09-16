//
//  HXFindViewController.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/4/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXFindReplaceViewController: NSViewController {
    
    var selectionDelegate: SelectionDelegate?
    
    static var lastFindUsed: String = ""
    
    @IBOutlet weak var label_lectureSelection: NSTextField!
    @IBOutlet weak var label_result: NSTextField!
    @IBOutlet weak var textField_find: NSTextField!
    @IBOutlet weak var textField_replace: NSTextField!
    
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
        NotificationCenter.default.addObserver(self, selector: #selector(HXFindViewController.textField_textChange),
                                               name: .NSControlTextDidChange, object: textField_replace)
        
        selectionDelegate?.isReplacing(with: self)
    }
    /// Should reset all variables when changing text
    func textField_textChange() {
        label_result.stringValue = ""
    }
    @IBAction func action_close(_ sender: NSButton) {
        if let parent = self.parent as? LectureEditorViewController {
            parent.isReplacing = false
        } else if let parent = self.parent as? EditorViewController {
            parent.isReplacing = false
        }
    }
    @IBAction func action_confirm(_ sender: Any) {
        
        label_result.stringValue = "Not yet implemented."
//        return
//        if textField_find.stringValue == "" || textField_replace.stringValue == ""  || textField_find.stringValue == textField_replace.stringValue {
//            return
//        }
//        // If owned by a LectureVC
//        if let parent = self.parent as? LectureCollectionViewItem {
//            var searchThroughText = parent.textView_lecture.string!
//            var replaced = 0
//            var index = 0
//            var loc = searchThroughText.lowercased().range(of: textField_find.stringValue)
//            while loc != nil {
//                print("Remove")
//                print("  Location is \(loc)")
//                index += searchThroughText.distance(from: searchThroughText.startIndex, to: loc!.lowerBound)
//                print("  Delete at \(index) with length \(textField_find.stringValue.characters.count)")
//                parent.textView_lecture.textStorage?.deleteCharacters(in: NSRange(location: index, length: textField_find.stringValue.characters.count))
//                print("  Insert at \(index)")
//                parent.textView_lecture.textStorage?.insert(NSAttributedString(string: textField_replace.stringValue), at: index)
//                replaced += 1
//                let removeToHere = parent.textView_lecture.string?.lowercased().range(of: textField_replace.stringValue)
//                print("  Remove to \(removeToHere)")
//                searchThroughText = searchThroughText.substring(from: (removeToHere?.upperBound)!)
//                index += textField_replace.stringValue.characters.count - 1
//                loc = searchThroughText.lowercased().range(of: textField_find.stringValue)
//            }
//            if replaced == 0 {
//                label_result.stringValue = "None Found"
//            } else {
//                label_result.stringValue = "\(replaced) Replaced"
//            }
//            // If owned by a TopbarVC
//        } else if self.parent is EditorViewController {
////            var replaced = 0
////            for case let lectureVC as LectureViewController in parent.childViewControllers {
////                var loc = lectureVC.textView_lecture.string!.lowercased().range(of: textField_find.stringValue)
////                while loc != nil {
////                    let index = lectureVC.textView_lecture.string!.lowercased().distance(from: (lectureVC.textView_lecture.string?.startIndex)!, to: loc!.lowerBound)
////                    lectureVC.textView_lecture.string?.removeSubrange(loc!)
////                    lectureVC.textView_lecture.textStorage?.insert(NSAttributedString(string: textField_replace.stringValue), at: index)
////                    replaced += 1
////                    loc = lectureVC.textView_lecture.string!.lowercased().range(of: textField_find.stringValue)
////                }
////            }
//            if replaced == 0 {
//                label_result.stringValue = "None Found"
//            } else {
//                label_result.stringValue = "\(replaced) Replaced"
//            }
//        }
    }
    @IBAction func action_select(_ sender: NSButton) {
        if let parent = self.parent as? LectureCollectionViewItem {
            HXFindViewController.lastFindUsed = textField_find.stringValue
            parent.isReplacing = false
            parent.owner.isReplacing = true
        } else if let parent = self.parent as? EditorViewController {
            parent.isReplacing = false
            if parent.lectureFocused != nil {
                parent.lectureFocused.isReplacing = true
            }
        }
    }
    
    @IBAction func action_findField(_ sender: Any) {
        NSApp.keyWindow?.makeFirstResponder(textField_replace)
    }
    @IBAction func action_replaceField(_ sender: Any) {
            action_confirm(sender)
    }
}
