//
//  Routechoices_ios_trackerApp.swift
//  Routechoices-ios-tracker
//
//  Created by Raphael Stefanini on 1.6.2021.
//

import SwiftUI

@main
struct Routechoices_ios_trackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(self)
        }
    }
    public var deviceId: String
    public var started: Bool
    var positionProvider: PositionProvider

    init() {
        positionProvider = PositionProvider()
        let userDefaults = UserDefaults.standard
        deviceId = userDefaults.string(forKey: "device_id_preference") ?? ""
        started = false
        if (deviceId == "") {
            self.requestDeviceId()
            while(true) {
                deviceId = userDefaults.string(forKey: "device_id_preference") ?? ""
                if (deviceId != "") {
                    break
                }
                sleep(1)
            }
        }
        started = positionProvider.started
    }
    
    public func start() {
        positionProvider.startUpdates()
        let userDefaults = UserDefaults.standard
        userDefaults.set(true, forKey: "streaming_ongoing_state")
    }
    public func stop() {
        positionProvider.stopUpdates()
        let userDefaults = UserDefaults.standard
        userDefaults.set(false, forKey: "streaming_ongoing_state")
    }
    
    private func requestDeviceId() {
        let session = URLSession.shared
        var request = URLRequest(url: URL(string: "https://www.routechoices.com/api/device_id/")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            print("DevID")
            guard let data = data else {
                self.requestDeviceId()
                return
            }
            if (error == nil) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let userDefaults = UserDefaults.standard
                        userDefaults.set(json["device_id"], forKey: "device_id_preference")
                        return
                    }
                } catch _ {
                }
            }
            self.requestDeviceId()
        })
        task.resume()
    }
}
