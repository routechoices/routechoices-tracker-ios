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
    var supportedLang = ["en", "es", "fi", "fr", "nl", "sv"]
    var lang = "en"
    var texts: [String: String] = [:]
    var translations = [
        "en": [
            "dev-id": "Device ID",
            "fetching": "Fetching...",
            "copy": "Copy",
            "start-gps": "Start live GPS",
            "stop-gps": "Stop live GPS",
            "register": "Register to an event",
        ],
        "es": [
            "dev-id": "Dispositivo ID",
            "fetching": "Atrayendo",
            "copy": "Copiar",
            "start-gps": "Iniciar GPS en vivo",
            "stop-gps": "Parar GPS en vivo",
            "register": "Registrarse en el evento",
        ],
        "fr": [
            "dev-id": "Identifiant de l'appareil",
            "fetching": "Chargement...",
            "copy": "Copier",
            "start-gps": "Démarrer le GPS",
            "stop-gps": "Arrêter le GPS",
            "register": "Inscription à un événement",
        ],
        "fi": [
            "dev-id": "Laitetunnus",
            "fetching": "Haetaan...",
            "copy": "Kopio",
            "start-gps": "Aloita live-gps",
            "stop-gps": "Lopeta live-gps",
            "register": "Ilmoittaudu tapahtumaan",
        ],
        "nl": [
            "dev-id": "Toestel ID",
            "fetching": "Ophalen...",
            "copy": "Kopiëren",
            "start-gps": "Start live GPS",
            "stop-gps": "Stop live GPS",
            "register": "Registreer voor event",
        ],
        "pl": [
            "dev-id": "Identyfikator urządzenia",
            "fetching": "Pobieranie...",
            "copy": "Kopiuj",
            "start-gps": "Start śledzenia GPS",
            "stop-gps": "Koniec śledzenia GPS",
            "register": "Zarejestruj na zawody",
        ],
        "sv": [
            "dev-id": "Enhets-ID",
            "fetching": "Hämtar data",
            "copy": "Kopiera",
            "start-gps": "Starta live GPS",
            "stop-gps": "Stoppa live GPS",
            "register": "Registrera till ett evenemang",
        ],
    ]
    
    init() {
        let userDefaults = UserDefaults.standard
        content.deviceId = userDefaults.string(forKey: "device_id_preference") ?? ""
        let localLang = String(Locale.preferredLanguages[0].prefix(2))
        if (supportedLang.contains(localLang)){
            lang = localLang
        }
        texts = translations[lang] ?? [:]
        if (content.deviceId == "") {
            self.requestDeviceId()
        } else {
            self.renewDeviceIdIfNeeded(currentDeviceId: content.deviceId)
        }
    }
    
    func getTimeSinceLastFixColor() -> Color {
        if (!positionProvider.started || positionProvider.lastTimeSinceFix > 10){ return Color.red }
        return Color.green
    }
    
    
    var body: some View {
        Image("ic_launcher")
        Text(texts["dev-id"] ?? "")
        if (content.deviceId == "") {
            Text(texts["fetching"] ?? "").padding()
        } else {
            Text(content.deviceId).padding().foregroundColor(getTimeSinceLastFixColor())
                        
            Button(texts["copy"] ?? "", action: {() -> Void in
                UIPasteboard.general.string = content.deviceId
            })
            Text(" ").padding()
            
            if(!positionProvider.started){
                Button(texts["start-gps"] ?? "", action: {() -> Void in
                    start()
                })
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button(texts["stop-gps"] ?? "", action: {() -> Void in
                    stop()
                })
                .padding()
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            Text(" ").padding()
            Button(texts["register"] ?? "", action: {() -> Void in
                if let requestUrl = NSURL(string: "https://registration.routechoices.com/#device_id="+content.deviceId) {
                    UIApplication.shared.open(requestUrl as URL)
                }
            })
        }
    }
    private func renewDeviceIdIfNeeded(currentDeviceId: String) {
        let isNew = currentDeviceId.range(of: #"[^0-9]"#, options: .regularExpression) == nil
        let session = URLSession.shared
        var request = URLRequest(url: URL(string: "https://api.routechoices.com/device/" + currentDeviceId + "/registrations" )!)
        request.httpMethod = "GET"

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            print("check DevID")
            if  let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 404 {
                    self.requestDeviceId()
                    return
                } else if isNew {
                    return
                }
            }
            guard let data = data else {
                return
            }
            if (error == nil) {
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        let regCount = json["count"] as? Int ?? 0
                        if (regCount == 0) {
                            self.requestDeviceId()
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
    private func requestDeviceId() {
        let session = URLSession.shared
        var request = URLRequest(url: URL(string: "https://api.routechoices.com/device/")!)
        request.httpMethod = "POST"

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")

        let secret = Bundle.main.infoDictionary?["POST_LOCATION_SECRET"] as! String
        request.addValue("Bearer " + secret, forHTTPHeaderField: "Authorization")

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

