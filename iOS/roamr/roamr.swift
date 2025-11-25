//
//  roamrApp.swift
//  roamr
//
//  Created by Anders Tai on 2025-11-04.
//

import SwiftUI

@main
struct roamr: App {
	@StateObject private var lidarManager = LiDARManager()
	@StateObject private var webSocketManager = WebSocketServerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
				.environmentObject(lidarManager)
				.environmentObject(webSocketManager)
				.onAppear {
					// Wire up the WebSocket manager with LiDAR manager for video streaming
					lidarManager.webSocketManager = webSocketManager
				}
        }
    }
}
