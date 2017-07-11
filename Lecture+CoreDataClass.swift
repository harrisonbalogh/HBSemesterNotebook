//
//  Lecture+CoreDataClass.swift
//  HXNotes
//
//  Created by Harrison Balogh on 7/8/17.
//  Copyright © 2017 Harxer. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

@objc(Lecture)
public class Lecture: NSManagedObject {
    
    /// This attempts to deduce the month from the given weekOfYear of the lecture
    /// but does not take into account the year, since months start on different days
    /// each year, may not be accurate. Returning 0 means an error occurred.
    func monthInYear() -> Int {
        let daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        let daysInYear = self.weekOfYear * 7
        var dayTotals = 0
        for d in 0..<daysInMonth.count {
            dayTotals += daysInMonth[d]
            if daysInYear < Int16(dayTotals) {
                return (d+1)
            }
        }
        return 0
    }
    
    /// This attempts to deduce the day from the given weekOfYear of the lecture
    /// but does not take into account the year, since months start on different days
    /// each year, may not be accurate. Returning 0 means an error occurred.
    func dayInMonth() -> Int {
        let daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        let daysInYear = self.weekOfYear * 7
        var dayTotals = 0
        for d in 0..<daysInMonth.count {
            dayTotals += daysInMonth[d]
            if daysInYear < Int16(dayTotals) {
                return dayTotals - Int(daysInYear)
            }
        }
        return 0
    }

}
