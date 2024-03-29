import Foundation
import CoreData
import CoreLocation

public class Position: NSObject {
    public var time: NSDate
    public var latitude: NSNumber
    public var longitude: NSNumber
    public var accuracy: NSNumber
    
    init(_ location: CLLocation) {
        time = location.timestamp as NSDate
        latitude = location.coordinate.latitude as NSNumber
        longitude = location.coordinate.longitude as NSNumber
        accuracy = location.horizontalAccuracy as NSNumber
    }
}
