//
//  BluetoothPage.swift
//  roamr
//
//  Created by Anders Tai on 2025-11-22.
//

import SwiftUI
import CoreBluetooth

struct BluetoothView: View {
    @StateObject private var bluetoothManager = BluetoothManager()
    @State private var messageToSend = ""

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("Bluetooth Devices")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)

            // Status
            VStack(spacing: 8) {
                Text(bluetoothManager.connectionStatus)
                    .font(.headline)
                    .foregroundColor(bluetoothManager.isConnected ? .green : .orange)

                if !bluetoothManager.lastMessage.isEmpty {
                    Text(bluetoothManager.lastMessage)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            // Scan Button
            if !bluetoothManager.isConnected {
                Button(action: {
                    if bluetoothManager.isScanning {
                        bluetoothManager.stopScanning()
                    } else {
                        bluetoothManager.startScanning()
                    }
                }) {
                    HStack {
                        Image(systemName: bluetoothManager.isScanning ? "stop.circle.fill" : "antenna.radiowaves.left.and.right")
                        Text(bluetoothManager.isScanning ? "Stop Scanning" : "Start Scanning")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(bluetoothManager.isScanning ? Color.red : Color.blue)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
            }

            // Device List
            if !bluetoothManager.isConnected {
                List {
                    ForEach(bluetoothManager.discoveredDevices, id: \.identifier) { device in
                        Button(action: {
                            bluetoothManager.connect(to: device)
                        }) {
                            HStack {
                                Image(systemName: "antenna.radiowaves.left.and.right")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(device.name ?? "Unknown Device")
                                        .font(.headline)
                                    Text(device.identifier.uuidString)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            } else {
                // Connected View - Message Sending
                VStack(spacing: 20) {
                    // Connected Device Info
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                        Text("Connected to")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(bluetoothManager.connectedDevice?.name ?? "Unknown Device")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    .padding()

                    // Message Input
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Send Message")
                            .font(.headline)

                        TextField("Enter message", text: $messageToSend)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal)

                        Button(action: {
                            bluetoothManager.sendMessage(messageToSend)
                            messageToSend = ""
                        }) {
                            HStack {
                                Image(systemName: "paperplane.fill")
                                Text("Send Message")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(messageToSend.isEmpty ? Color.gray : Color.blue)
                            .cornerRadius(10)
                        }
                        .disabled(messageToSend.isEmpty)
                        .padding(.horizontal)
                    }
                    .padding()

                    Spacer()

                    // Disconnect Button
                    Button(action: {
                        bluetoothManager.disconnect()
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Disconnect")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
    }
}
