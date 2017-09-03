//
//  LectureHeaderView.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/3/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

@IBDesignable class LectureHeaderView: NSView {
    
    weak var owner: EditorViewController!
    
    weak var collectionViewItem: LectureCollectionViewItem!

    func action_customTitle(_ sender: NSTextField) {
        NSApp.keyWindow?.makeFirstResponder(self)
    }
    
    @IBOutlet weak var label_lectureTitle: NSTextField!
    @IBOutlet weak var label_lectureDate: NSTextField!
    @IBOutlet weak var label_customTitle: NSTextField!
    @IBOutlet weak var label_titleDivider: NSTextField!
    @IBOutlet weak var customTitleTrailingConstraint: NSLayoutConstraint!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        NSColor(calibratedWhite: 1, alpha: 0.9).set()
        NSRectFillUsingOperation(dirtyRect, .sourceOver)
    }
    
    // MARK: - ––– Notifiers –––
    
    ///
    func notifyCustomTitleChange() {
        if label_customTitle.stringValue == "" {
            label_titleDivider.alphaValue = 0.3
        } else {
            label_titleDivider.alphaValue = 1
        }
    }
    
    ///
    func notifyCustomTitleEndEditing() {
        label_customTitle.stringValue = label_customTitle.stringValue.trimmingCharacters(in: .whitespaces)
        // Check if it has content
        if label_customTitle.stringValue == "" {
            label_titleDivider.alphaValue = 0.3
        } else {
            label_titleDivider.alphaValue = 1
        }
        // Save to model
        collectionViewItem.lecture.title = label_customTitle.stringValue
    }
    
    /// Received from HXTextView (from LectureCollectionViewItem). Will reveal or hide styling buttons and
    /// update customTitle textField constraints.
    func notifyTextViewFocus(_ focus: Bool) {
        // Remove constraint before updating and reinstating
        
        customTitleTrailingConstraint.isActive = false
        if focus {
            // Animate revealing the styling buttons
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 1
            button_style_underline.animator().alphaValue = 1
            button_style_italicize.animator().alphaValue = 1
            button_style_bold.animator().alphaValue = 1
            button_style_left.animator().alphaValue = 1
            button_style_center.animator().alphaValue = 1
            button_style_right.animator().alphaValue = 1
            button_style_font.animator().alphaValue = 1
            button_style_color.animator().alphaValue = 1
            label_style_font.animator().alphaValue = 1
            box_style_color.animator().alphaValue = 1
            NSAnimationContext.endGrouping()
            // Have to shift the customTitle textField to truncate at the closest style button
            customTitleTrailingConstraint = label_customTitle.trailingAnchor.constraint(equalTo: button_style_font.leadingAnchor)
        } else {

            // Animate hiding the styling buttons
            NSAnimationContext.beginGrouping()
            NSAnimationContext.current().duration = 0.25
            button_style_underline.animator().alphaValue = 0
            button_style_italicize.animator().alphaValue = 0
            button_style_bold.animator().alphaValue = 0
            button_style_left.animator().alphaValue = 0
            button_style_center.animator().alphaValue = 0
            button_style_right.animator().alphaValue = 0
            button_style_font.animator().alphaValue = 0
            button_style_color.animator().alphaValue = 0
            label_style_font.animator().alphaValue = 0
            box_style_color.animator().alphaValue = 0
            NSAnimationContext.endGrouping()
            // Have to shift the customTitle textField to extend to the date label
            customTitleTrailingConstraint = label_customTitle.trailingAnchor.constraint(equalTo: label_lectureDate.leadingAnchor)
        }
        // Reinstate constraint
        customTitleTrailingConstraint.isActive = true
    }
    
    // MARK: - ––– Styling Functionality –––

    @IBOutlet weak var box_style_color: NSBox!
    @IBOutlet weak var label_style_font: NSTextField!
    @IBOutlet weak var button_style_color: NSButton!
    @IBOutlet weak var button_style_font: NSButton!
    @IBOutlet weak var button_style_underline: NSButton!
    @IBOutlet weak var button_style_italicize: NSButton!
    @IBOutlet weak var button_style_bold: NSButton!
    @IBOutlet weak var button_style_left: NSButton!
    @IBOutlet weak var button_style_center: NSButton!
    @IBOutlet weak var button_style_right: NSButton!
    
    let sharedFontManager = NSFontManager.shared()
    
    ///
    @IBAction func action_styleUnderline(_ sender: NSButton) {
        
        collectionViewItem.styleUnderline(sender)
    }
    
    @IBAction func action_styleItalicize(_ sender: NSButton) {
        sharedFontManager.addFontTrait(sender)
    }
    @IBAction func action_styleBold(_ sender: NSButton) {
        sharedFontManager.addFontTrait(sender)
    }
    
    ///
    @IBAction func action_styleLeft(_ sender: NSButton) {
        
        collectionViewItem.styleLeft(sender)
    }
    ///
    @IBAction func action_styleCenter(_ sender: NSButton) {
        
        collectionViewItem.styleCenter(sender)
    }
    ///
    @IBAction func action_styleRight(_ sender: NSButton) {
        
        collectionViewItem.styleRight(sender)
    }
    ///
    @IBAction func action_styleFont(_ sender: NSButton) {
        sharedFontManager.orderFrontFontPanel(self)
    }
    ///
    @IBAction func action_styleColor(_ sender: NSButton) {
        NSApp.orderFrontColorPanel(self)
    }
    
    
    func selectionChange() {
        if sharedFontManager.selectedFont == nil || collectionViewItem.textView_lecture.attributedString().length == 0 {
            return
        }
        
        let traits = sharedFontManager.traits(of: sharedFontManager.selectedFont!)
        var positionOfSelection = collectionViewItem.textView_lecture.selectedRanges.first!.rangeValue.location
        if positionOfSelection == collectionViewItem.textView_lecture.attributedString().length {
            positionOfSelection = collectionViewItem.textView_lecture.attributedString().length - 1
        }

        if collectionViewItem.textView_lecture.attributedString().attribute(NSUnderlineStyleAttributeName, at: positionOfSelection, effectiveRange: nil) != nil {
            button_style_underline.state = NSOnState
        } else {
            button_style_underline.state = NSOffState
        }
        
        if let color = collectionViewItem.textView_lecture.attributedString().attribute(NSForegroundColorAttributeName, at: positionOfSelection, effectiveRange: nil) as? NSColor {
            box_style_color.fillColor = color
        } else if positionOfSelection != 0 {
            if let color = collectionViewItem.textView_lecture.attributedString().attribute(NSForegroundColorAttributeName, at: positionOfSelection - 1, effectiveRange: nil) as? NSColor {
                box_style_color.fillColor = color
            } else {
                box_style_color.fillColor = NSColor.black
            }
        } else {
            box_style_color.fillColor = NSColor.black
        }
        
        if let font = collectionViewItem.textView_lecture.attributedString().attribute(NSFontAttributeName, at: positionOfSelection, effectiveRange: nil) as? NSFont {
            if let name = font.familyName {
                label_style_font.stringValue = name
            } else {
                label_style_font.stringValue = font.fontName
            }
        }
        
        if let parStyle = collectionViewItem.textView_lecture.attributedString().attribute("NSParagraphStyle", at: positionOfSelection, effectiveRange: nil) as? NSParagraphStyle {
            
            button_style_left.state = NSOffState
            button_style_center.state = NSOffState
            button_style_right.state = NSOffState
            
            if parStyle.alignment.rawValue == 0 {
                button_style_left.state = NSOnState
                button_style_center.state = NSOffState
                button_style_right.state = NSOffState
            } else if parStyle.alignment.rawValue == 1 {
                button_style_right.state = NSOnState
                button_style_left.state = NSOffState
                button_style_center.state = NSOffState
            } else if parStyle.alignment.rawValue == 2 {
                button_style_center.state = NSOnState
                button_style_left.state = NSOffState
                button_style_right.state = NSOffState
            }
        }
        
        if traits.contains(.boldFontMask) {
            button_style_bold.state = NSOnState
            button_style_bold.tag = Int(NSFontTraitMask.unboldFontMask.rawValue)
        } else {
            button_style_bold.state = NSOffState
            button_style_bold.tag = Int(NSFontTraitMask.boldFontMask.rawValue)
        }
        
        if traits.contains(.italicFontMask) {
            button_style_italicize.state = NSOnState
            button_style_italicize.tag = Int(NSFontTraitMask.unitalicFontMask.rawValue)
        } else {
            button_style_italicize.state = NSOffState
            button_style_italicize.tag = Int(NSFontTraitMask.italicFontMask.rawValue)
        }
    }
    func traitChange() {
        selectionChange()
    }
    
}
