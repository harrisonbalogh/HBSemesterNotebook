//
//  HXStickyHeaderView.swift
//  HXNotes
//
//  Created by Harrison Balogh on 8/3/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Cocoa

class HXStickyHeaderView: NSScrollView {

    // USE contentView (NSClipView)
    // USE documentView (NSView)
    
    private var headerViews = [NSView]()
    private var contentViews = [NSView]()
    
    private var bottomBufferView: NSView!
    private var bottomBufferViewTopConstraint: NSLayoutConstraint!
    private var bottomBufferViewHeightConstraint: NSLayoutConstraint!
    
    var headerHeight: CGFloat = 10
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        bottomBufferView = NSView()
        bottomBufferView.leadingAnchor.constraint(equalTo: documentView!.leadingAnchor).isActive = true
        bottomBufferView.trailingAnchor.constraint(equalTo: documentView!.trailingAnchor).isActive = true
        bottomBufferView.bottomAnchor.constraint(equalTo: documentView!.bottomAnchor).isActive = true
        
        bottomBufferViewHeightConstraint = bottomBufferView.heightAnchor.constraint(equalToConstant: 100)
        bottomBufferViewHeightConstraint.isActive = true
        
        bottomBufferViewTopConstraint = bottomBufferView.topAnchor.constraint(equalTo: documentView!.topAnchor)
        bottomBufferViewTopConstraint.isActive = true
        
    }
    
    // MARK: - Populate View
    
    /// Adds a view to the bottom of the stacked views along with the corresponding
    /// custom header view that stays atop the content.
    func append(view content: NSView, with header: NSView) {
        
        header.translatesAutoresizingMaskIntoConstraints = false
        content.translatesAutoresizingMaskIntoConstraints = false
        
        bottomBufferViewTopConstraint.isActive = false
        
        documentView!.addSubview(header)
        documentView!.addSubview(content)
        
        if contentViews.count == 0 {
            header.topAnchor.constraint(equalTo: documentView!.topAnchor).isActive = true
        } else {
            header.topAnchor.constraint(equalTo: contentViews.last!.bottomAnchor).isActive = true
        }
        
        header.leadingAnchor.constraint(equalTo: documentView!.leadingAnchor).isActive = true
        header.trailingAnchor.constraint(equalTo: documentView!.trailingAnchor).isActive = true
        header.heightAnchor.constraint(equalToConstant: headerHeight).isActive = true
        
        content.leadingAnchor.constraint(equalTo: documentView!.leadingAnchor).isActive = true
        content.trailingAnchor.constraint(equalTo: documentView!.trailingAnchor).isActive = true
        content.topAnchor.constraint(equalTo: header.bottomAnchor).isActive = true
        
        bottomBufferViewTopConstraint = bottomBufferView.topAnchor.constraint(equalTo: content.bottomAnchor)
        bottomBufferViewTopConstraint.isActive = true
        
        contentViews.append(content)
        headerViews.append(header)
        
    }
    
    // MARK: - Handling Scrolling
    
    
    
}
