//
//  appModel.swift
//  NOTIQ
//
//  Created by Maila Pham on 3/27/25.
//

import Foundation
import UIKit
import SwiftUICore
import SwiftData
import MapKit

// class for reminder functionalities
@Model
final class remindModel {
    var id = UUID()
    var title: String
    var course: String
    var descriptionText: String
    var dueDate: Date
    var location: String?
    var address: String?
    var isFlagged: Bool
    var isCompleted: Bool

    init(title: String, course: String, description: String, dueDate: Date, location: String? = nil, address: String? = nil, isFlagged: Bool = false, isCompleted: Bool = false) {
        self.id = UUID()
        self.title = title
        self.course = course
        self.descriptionText = description
        self.dueDate = dueDate
        self.location = location
        self.address = address
        self.isFlagged = isFlagged
        self.isCompleted = isCompleted
    }
}

// class for event functionalities
@Model
final class eventModel {
    var id = UUID()
    var title: String
    var descriptionText: String
    var date: Date
    var location: String?
    var address: String?
    var isFlagged: Bool
    var isAllDay: Bool
    var startDate: Date?
    var endDate: Date?
    
    init(title: String, description: String, date: Date, location: String? = nil, address: String? = nil, isFlagged: Bool = false, isAllDay: Bool = false, startDate: Date? = nil, endDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.descriptionText = description
        self.date = date
        self.location = location
        self.address = address
        self.isFlagged = isFlagged
        self.isAllDay = isAllDay
        self.startDate = startDate
        self.endDate = endDate
    }
}

// class for study places - user input
@Model
final class studyModel {
    var id: UUID
    var name: String
    var type: String
    var state: String
    var country: String
    var latitude: Double
    var longitude: Double
    
    init(name: String, type: String, state: String, country: String, latitude: Double, longitude: Double) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.state = state
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }
}

struct geonameStudyModel: Codable {
    let geonameId: Int
    let name: String
    let type: String
    let state: String
    let country: String
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
        case geonameId
        case name
        case type = "fcodeName"
        case state = "adminCode1"
        case country = "countryName"
        case latitude = "lat"
        case longitude = "lng"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.geonameId = try container.decode(Int.self, forKey: .geonameId)
        self.name = try container.decode(String.self, forKey: .name)
        self.type = try container.decode(String.self, forKey: .type)
        self.state = try container.decode(String.self, forKey: .state)
        self.country = try container.decode(String.self, forKey: .country)
        
        // string to double
        let latString = try container.decode(String.self, forKey: .latitude)
        let lngString = try container.decode(String.self, forKey: .longitude)
        
        self.latitude = Double(latString) ?? 0.0
        self.longitude = Double(lngString) ?? 0.0
    }
}

struct geonameResponse: Codable {
    let geonames: [geonameStudyModel]
}

// make MKMapItem hashable/identifiable
extension MKMapItem: Identifiable {
    public var id: String {
        "\(name ?? "")-\(placemark.coordinate.latitude)-\(placemark.coordinate.longitude)"
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
