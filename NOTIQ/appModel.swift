//
//  appModel.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import Foundation
import UIKit
import SwiftUICore
// import Firebase
import MapKit

// struct for reminder functionalities
struct remindModel: Identifiable, Comparable {
    let id = UUID()
    var title: String
    var course: String
    var description: String
    var dueDate: Date
    var location: String?
    var isFlagged: Bool
    var isCompleted: Bool

    // sorting logic - flagged tasks first, then by due date
    static func < (lhs: remindModel, rhs: remindModel) -> Bool {
        if lhs.isFlagged != rhs.isFlagged {
            return lhs.isFlagged
        }
        return lhs.dueDate < rhs.dueDate
    }
}

// struct for event functionalities
struct eventModel: Identifiable, Comparable {
    var id = UUID()
    var title: String
    var description: String
    var date: Date
    var location: String?
    var isFlagged: Bool
    var isAllDay: Bool
    var startDate: Date? 
    var endDate: Date?
    
    // sorting logic - flagged tasks first, then by due date
    static func < (lhs: eventModel, rhs: eventModel) -> Bool {
        if lhs.isFlagged != rhs.isFlagged {
            return lhs.isFlagged
        }
        return lhs.date < rhs.date
    }
}

// allows for custom colors - specifically just for UI in ContentView
extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        let a: CGFloat = hexSanitized.count == 8 ? CGFloat((rgb >> 24) & 0xFF) / 255.0 : 1.0
        
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

// allows for custom colors
extension Color {
    init(hex: String) {
        let hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
