import UIKit
import CoreLocation

class PositionProvider: NSObject, CLLocationManagerDelegate {
 
    var locationManager: CLLocationManager
    public var lastLocation: CLLocation?
    var locBuffer: [Position]
    var deviceId: String
    var timer: Timer
    public var started: Bool
    var pendingStart = false
    
    override init() {
        let userDefaults = UserDefaults.standard
        deviceId = userDefaults.string(forKey: "device_id_preference") ?? ""
        locBuffer = []
        locationManager = CLLocationManager()
        timer = Timer()
        
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        started = false
        super.init()

        locationManager.delegate = self
    }
    
    @objc func flushBuffer() {
        let session = URLSession.shared

        var request = URLRequest(url: URL(string: "https://api.routechoices.com/locations")!)
        request.httpMethod = "POST"
        var lats = ""
        var lons = ""
        var times = ""
        for loc in self.locBuffer {
            lats += String(describing: loc.latitude) + ","
            lons += String(describing: loc.longitude) + ","
            times += String(describing: loc.time.timeIntervalSince1970) + ","
        }
        if (times.count == 0) {
            return
        }
        if (self.deviceId == "") {
            let userDefaults = UserDefaults.standard
            self.deviceId = userDefaults.string(forKey: "device_id_preference") ?? ""
        }
        let params = ["latitudes": lats, "longitudes": lons, "timestamps": times, "device_id": self.deviceId]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: params)
        } catch _ {
            return
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            if (data != nil && error == nil) {
                self.locBuffer.removeAll()
                print("Positions sent")
            }
        })
        task.resume()
    }

    func startUpdates() {
        let manager = CLLocationManager()

        switch manager.authorizationStatus {
        case .authorizedAlways:
            locationManager.startUpdatingLocation()
            timer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(flushBuffer), userInfo: nil, repeats: true)
        default:
            pendingStart = true
            locationManager.requestAlwaysAuthorization()
        }
        started = true
    }
    
    func stopUpdates() {
        locationManager.stopUpdatingLocation()
        timer.invalidate()
        self.flushBuffer()
        started = false
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            if pendingStart {
                pendingStart = false
                locationManager.startUpdatingLocation()
            }
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            if (lastLocation == nil
                || location.timestamp.timeIntervalSince(lastLocation!.timestamp) >= 1 
                ) && location.horizontalAccuracy <= 50 {
                let position = Position(location)
                lastLocation = location
                locBuffer.append(position)
                print("TS: " + String(describing: position.time))
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    }

}
