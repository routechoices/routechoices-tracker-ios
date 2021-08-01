//
//  ContentView.swift
//  Routechoices-ios-tracker
//
//  Created by Raphael Stefanini on 1.6.2021.
//

import SwiftUI
import Combine

class ContentViewModel: ObservableObject {
    @Published var deviceId: String = ""
}

struct ContentView: View {
    @ObservedObject var content = ContentViewModel()
    @StateObject var positionProvider = PositionProvider()

    init() {
        let userDefaults = UserDefaults.standard
        content.deviceId = userDefaults.string(forKey: "device_id_preference") ?? ""
        if (content.deviceId == "") {
            self.requestDeviceId()
        }
    }
    
    func getTimeSinceLastFixColor() -> Color {
        if (!positionProvider.started || positionProvider.lastTimeSinceFix > 10){ return Color.red }
        return Color.green
    }

    var body: some View {
        Image("ic_launcher")
        Text("Device ID")
        if (content.deviceId == "") {
            Text("Fetching...").padding()
        } else {
            Text(content.deviceId).padding().foregroundColor(getTimeSinceLastFixColor())
                        
            Button("Copy", action: {() -> Void in
                UIPasteboard.general.string = content.deviceId
            })
            Text(" ").padding()
            
            if(!positionProvider.started){
                Button("Start live gps", action: {() -> Void in
                    start()
                })
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button("Stop live gps", action: {() -> Void in
                    stop()
                })
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Text(" ").padding()
            Button("Register to an event", action: {() -> Void in
                if let requestUrl = NSURL(string: "https://registration.routechoices.com/#device_id="+content.deviceId) {
                    UIApplication.shared.open(requestUrl as URL)
                }
            })
        }
    }
    
    private func requestDeviceId() {
        let session = URLSession.shared
        var request = URLRequest(url: URL(string: "https://api.routechoices.com/device_id")!)
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
                        let deviceIdRaw = json["device_id"] as? String ?? ""
                        userDefaults.set(deviceIdRaw, forKey: "device_id_preference")
                        print(deviceIdRaw)
                        DispatchQueue.main.async {
                            self.content.deviceId = deviceIdRaw
                        }
                        return
                    }
                } catch _ {
                }
            }
            self.requestDeviceId()
        })
        task.resume()
    }
    
    private func start() {
        positionProvider.startUpdates()
    }

    private func stop() {
        positionProvider.stopUpdates()
    }
}

