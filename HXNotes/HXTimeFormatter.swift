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
    /// Change 13 to 1 but keep 12 as 12.
    public static  func formatTime(_ time: Int) -> Int {
        let t_24 = Double(time)
        let t_12 = t_24 - (ceil(Double(t_24/12)) - 1) * 12
        return Int(t_12)
    }

    private static var DAYS_IN_JAN = 31
    private static var DAYS_IN_FEB = 28 // Remember leap years
    private static var DAYS_IN_MAR = 31
    private static var DAYS_IN_APR = 30
    private static var DAYS_IN_MAY = 31
    private static var DAYS_IN_JUN = 31
    private static var DAYS_IN_JUL = 31
    private static var DAYS_IN_AUG = 31
    private static var DAYS_IN_SEP = 30
    private static var DAYS_IN_OCT = 31
    private static var DAYS_IN_NOV = 30
    private static var DAYS_IN_DEC = 31
    
    public static func hey() {
        
    }
    
}
