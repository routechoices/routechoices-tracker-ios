//
//  ContentView.swift
//  Routechoices-ios-tracker
//
//  Created by Raphael Stefanini on 1.6.2021.
//

import SwiftUI

struct ContentView: View {
    init(_ appIn: Routechoices_ios_trackerApp) {
      app = appIn
      started = app.started
      print("Z")
    }
    var app: Routechoices_ios_trackerApp
    @State public var started: Bool
    var body: some View {
        let devIdText = app.deviceId
        Image("ic_launcher")
        Text("Device ID")
        Text(devIdText).padding()
        if (app.deviceId != "") {
            Button("Copy", action: {() -> Void in
                UIPasteboard.general.string = app.deviceId
            })
            Text(" ").padding()
            
            if(!started){
                Button("Start live gps", action: {() -> Void in
                    started.toggle()
                    app.start()
                })
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            } else {
                Button("Stop live gps", action: {() -> Void in
                    started.toggle()
                    app.stop()
                })
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
        }
    }
}

