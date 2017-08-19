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
        
        var hourStop = "\(Int(minuteOfDay / 60))"
        var minuteStop = "\(Int(minuteOfDay % 60))"
        if Int(minuteOfDay % 60) < 10 {
            minuteStop = "0" + minuteStop
            
        }
        if Int(minuteOfDay / 60) > 12 {
            hourStop = "\(Int(minuteOfDay / 60) - 12)"
            minuteStop = minuteStop + "PM"
        } else if Int(minuteOfDay / 60) == 12 {
            minuteStop = minuteStop + "PM"
        } else {
            minuteStop = minuteStop + "AM"
        }
        return hourStop + ":" + minuteStop
    }
    /// Change 13 to 1 but keep 12 as 12.
    public static  func formatHour(_ time: Int) -> Int {
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
