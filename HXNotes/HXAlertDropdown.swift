//
//  HXAlertDropdown.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/25/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXAlertDropdown: NSViewController {

    @IBOutlet weak var label_time: NSTextField!
    @IBOutlet weak var label_course: NSTextField!
    @IBOutlet weak var label_content: NSTextField!
    @IBOutlet weak var label_accept: NSTextField!
    @IBOutlet weak var label_ignore: NSTextField!
    
    @IBOutlet weak var button_accept: NSButton!
    @IBOutlet weak var button_ignore: NSButton!
    
    @IBOutlet weak var image_underline: NSImageView!
    
    var topConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let view = self.view as? VisualEffectView {
            view.state = .active
            view.blendingMode = .behindWindow
            view.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
            view.material = .appearanceBased
        }
    }
}
