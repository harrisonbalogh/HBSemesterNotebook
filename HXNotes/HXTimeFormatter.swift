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
    public static  func formatTime(_ minuteOfDay: Int16) -> String {
        
        var hour = "\(Int(minuteOfDay / 60))"
        var minute = "\(Int(minuteOfDay % 60))"
        if Int(minuteOfDay % 60) < 10 {
            minute = "0" + minute
        }
        if Int(minuteOfDay / 60) > 12 {
            hour = "\(Int(minuteOfDay / 60) - 12)"
            minute += "PM"
        } else if Int(minuteOfDay / 60) == 12 {
            minute += "PM"
        } else {
            minute += "AM"
            if Int(minuteOfDay / 60) == 0 {
                hour = "12"
            }
        }
        return hour + ":" + minute
    }
    /// Change 13 to 1 but keep 12 as 12.
    public static  func formatHour(_ time: Int) -> Int {
        if time == 0 {
            return 12
        }
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
}
