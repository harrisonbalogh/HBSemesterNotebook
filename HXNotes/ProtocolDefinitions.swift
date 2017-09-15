//
//  ProtocolDefinitions.swift
//  HXNotes
//
//  Created by Harrison Balogh on 9/7/17.
//  Copyright © 2017 Harxer. All rights reserved.
//

import Foundation
import Cocoa

// MARK: - Delegation

protocol SelectionDelegate {
    func courseWasSelected(_ course: Course?)
    func workWasSelected(_ work: Work)
    func testWasSelected(_ test: Test)
    
    func isEditing(lecture: Lecture?)
    func isEditing(workBox: CourseWorkBox?)
    func isEditing(testBox: CourseTestBox?)
}

protocol SchedulingDelegate {
    
    func schedulingDidFinish()
    func schedulingDidStart()
    
    func schedulingNeedsValidation(_ schedulerPVC: SchedulerPageViewController)
    
    func schedulingAddCourse(_ schedulerPVC: SchedulerPageViewController)
    func schedulingAddLecture()
    func schedulingAddWork()
    func schedulingAddTest()
    
    func schedulingRemove(course: Course)
    func schedulingRemove(timeSlot: TimeSlot)
    func schedulingRemove(workBox: CourseWorkBox)
    func schedulingRemove(testBox: CourseTestBox)
    
    func schedulingUpdatedTimeSlot()
    func schedulingUpdatedWork()
    func schedulingUpdateTest()
    
    func schedulingRenameCourse()
}

protocol SidebarDelegate {
    func sidebarSchedulingNeedsPopulating(_ schedulerPVC: SchedulerPageViewController)
    func sidebarSemesterNeedsPopulating(_ semesterPVC: SemesterPageViewController)
    func sidebarCourseNeedsPopulating(_ coursePVC: CoursePageViewController)
    func sidebarCoursePopulateCompletedWork(_ coursePVC: CoursePageViewController)
    func sidebarCoursePopulateCompletedTests(_ coursePVC: CoursePageViewController)
}
