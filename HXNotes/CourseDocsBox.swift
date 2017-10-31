//
//  CourseDocsBox.swift
//  HXNotes
//
//  Created by Harrison Balogh on 10/8/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class CourseDocsBox: NSBox {
    
    /// Return a new instance of a HXLectureLedger based on the nib template.
    static func instance(with path: URL) -> CourseDocsBox! {
        var theObjects: NSArray = []
        Bundle.main.loadNibNamed("CourseDocsBox", owner: nil, topLevelObjects: &theObjects)
        // Get NSView from top level objects returned from nib load
        if let newBox = theObjects.filter({$0 is CourseDocsBox}).first as? CourseDocsBox {
            newBox.initialize(with: path)
            return newBox
        }
        return nil
    }

    @IBOutlet weak var labelFileName: NSTextField!
    @IBOutlet weak var labelDate: NSTextField!
    @IBOutlet weak var imageSelect: NSImageView!
    
    private var pointingFile: URL!
    
    private func initialize(with path: URL) {
        pointingFile = path
        let url = URL(fileURLWithPath: path.absoluteString)
        labelFileName.stringValue = url.lastPathComponent.removingPercentEncoding!
        do {
            let attrs = try FileManager.default.attributesOfItem(atPath: path.relativePath) as NSDictionary
            let creationDate = attrs.fileCreationDate()!
            let cal = Calendar.current
            labelDate.stringValue = "\(cal.component(.month, from: creationDate))/\(cal.component(.day, from: creationDate))/\(cal.component(.year, from: creationDate))"
        } catch {
            Swift.print("CourseDocsBox failed: \(path.relativePath)")
        }
    }
    
    @IBAction func action_select(_ sender: NSButton) {
        NSWorkspace.shared().open(pointingFile.deletingLastPathComponent())
    }
}
