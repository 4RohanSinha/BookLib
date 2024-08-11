//
//  BookReadingStatus.swift
//  BookReview
//
//  Created by Rohan Sinha on 8/9/21.
//

import Foundation


enum BookReadingStatus: Int32 {
    case notStarted
    case currentlyReading
    case finished
    case paused
    case error
    
    var stringValue: String {
        switch self {
        case .notStarted:
            return "not started"
        case .currentlyReading:
            return "currently reading"
        case .finished:
            return "finished"
        case .paused:
            return "paused"
        case .error:
            return "unavailable"
        }
    }
    
    var allowedControls: [BookReadingStatusControls] {
        switch self {
        case .notStarted:
            return [.start]
            
        case .currentlyReading:
            return [.pause, .restore]
        
        case .finished: //MARK:- .finished will be set automatically when progress is updated...user can't click "Finish"
            return [.restore]
        
        case .paused:
            return [.resume, .restore]
            
        case .error:
            return []
        }
    }
    
}


enum BookReadingStatusControls: Int32 {
    case start
    case pause
    case resume
    case restore
    
    var endpoint: BookReadingStatus {
        switch self {
        case .start, .resume:
            return .currentlyReading
        case .pause:
            return .paused
        case .restore:
            return .notStarted
        }
    }
}
