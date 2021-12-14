//
//  HXTextView.swift
//  HXNotes
//
//  Created by Harrison Balogh on 5/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXTextView: NSTextView {

    weak var parentController: LectureEditorViewController!
    var textFinder: NSTextFinder!
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        parentController.notifyContentFocus(is: true)
        return true
    }
    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        parentController.notifyContentFocus(is: false)
        return true
    }

    override func performTextFinderAction(_ sender: Any?) {
        Swift.print("HXTextView - performTextFinderAction")

        // Extract tag from sender.
        var tag = -1
        switch sender {
        case let sender as NSButton:
            tag = sender.tag
            break
        case let sender as NSMenuItem:
            tag = sender.tag
            break
        default:
            break
        }
        
        // 
        if let action = NSTextFinder.Action(rawValue: tag) {
            if !parentController.isFinding {
                parentController.isFinding = true
            }
            textFinder.performAction(action)
        }
    }
    
    override func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        Swift.print("HXTextView - validateUserInterfaceItem")
        if item.action == #selector(performTextFinderAction(_:)) {
            if let action = NSTextFinder.Action(rawValue: item.tag) {
                return textFinder.validateAction(action)
            }
        }
        return false
    }
}
