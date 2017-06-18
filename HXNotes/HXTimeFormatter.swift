//
//  HXTimeFormatter.swift
//  HXNotes
//
//  Created by Harrison Balogh on 6/17/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Foundation

class HXTimeFormatter {
    
    /// Change 13 to 1 but keep 12 as 12. Also append AM or PM
    public static  func formatTime(_ time: Int16) -> String {
        let t_24 = Double(time)
        let t_12 = t_24 - (ceil(Double(t_24/12)) - 1) * 12
        var formattedTime = "\(Int(t_12)):00"
        if floor(Double(t_24/12)) == 0 {
            formattedTime += "AM"
        } else {
            formattedTime += "PM"
        }
        return formattedTime
    }
    
}
