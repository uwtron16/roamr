//
//  SettingsPage.swift
//  roamr
//
//  Created by Anders Tai on 2025-11-05.
//

import Foundation
import SwiftUI
import CoreMotion

// Global variables for IMU data and Wasm export
let motionManager = CMMotionManager()
let imuLock = NSLock()

struct IMUData {
    var timestamp: Double
    var acc_x: Float
    var acc_y: Float
    var acc_z: Float
    var gyro_x: Float
    var gyro_y: Float
    var gyro_z: Float
    var mag_x: Float
    var mag_y: Float
    var mag_z: Float
}

var currentIMUData = IMUData(timestamp: 0, acc_x: 0, acc_y: 0, acc_z: 0, gyro_x: 0, gyro_y: 0, gyro_z: 0, mag_x: 0, mag_y: 0, mag_z: 0)

// Global WAMR State
var isWAMRInitialized = false
var globalNativeSymbolPtr: UnsafeMutablePointer<NativeSymbol>?
var globalModuleNamePtr: UnsafeMutablePointer<CChar>?

@_cdecl("read_imu_impl")
func read_imu_impl(exec_env: wasm_exec_env_t?, ptr: UnsafeMutableRawPointer?) {
    guard let ptr = ptr else { return }
    
    // Bind memory to IMUData struct
    let imuDataPtr = ptr.bindMemory(to: IMUData.self, capacity: 1)
    
    imuLock.lock()
    let data = currentIMUData
    imuLock.unlock()
    
    imuDataPtr.pointee = data
}

struct SettingsPage: View {
	@EnvironmentObject var lidarManager: LiDARManager

	private var appVersion: String {
		Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
	}

	var body: some View {
		VStack(spacing: 30) {
			Spacer()
			// App name
			Text("roamr")
				.font(.largeTitle)
				.fontWeight(.bold)

			// App version
			Text("Version \(appVersion)")
				.font(.subheadline)
				.foregroundColor(.secondary)

			// Description
			Text("Really Open-Source Autonomous Robot")
				.font(.caption)
				.multilineTextAlignment(.center)
				.padding(.horizontal, 30)

			Button("Test WASM") {
//				try? self.test()
				runTest(operand1: Int32(6), operand2: Int32(7))
			}
			.padding()
			.background(Color.AppColor.accent.color)
			.foregroundColor(.white)
			.cornerRadius(20)

			Spacer()
		}
		.padding()
	}

	let defaultStackSize: UInt32 = 512 * 1024       // 512 KB
	let heapSize: UInt32 = 16 * 1024 * 1024         // 16 MB

	func runTest(operand1: Int32, operand2: Int32) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Start sensors
            if motionManager.isAccelerometerAvailable {
                motionManager.accelerometerUpdateInterval = 0.1
                motionManager.startAccelerometerUpdates(to: .main) { (data, error) in
                    if let data = data {
                        imuLock.lock()
                        currentIMUData.timestamp = data.timestamp
                        currentIMUData.acc_x = Float(data.acceleration.x)
                        currentIMUData.acc_y = Float(data.acceleration.y)
                        currentIMUData.acc_z = Float(data.acceleration.z)
                        imuLock.unlock()
                    }
                }
            }
            if motionManager.isGyroAvailable {
                motionManager.gyroUpdateInterval = 0.1
                motionManager.startGyroUpdates(to: .main) { (data, error) in
                    if let data = data {
                        imuLock.lock()
                        // Use latest timestamp from any sensor? Or keep separate?
                        // For now, let's update timestamp on accel only or any?
                        // Usually we want synchronized, but for this simple test, updating fields is fine.
                        currentIMUData.gyro_x = Float(data.rotationRate.x)
                        currentIMUData.gyro_y = Float(data.rotationRate.y)
                        currentIMUData.gyro_z = Float(data.rotationRate.z)
                        imuLock.unlock()
                    }
                }
            }
            if motionManager.isMagnetometerAvailable {
                motionManager.magnetometerUpdateInterval = 0.1
                motionManager.startMagnetometerUpdates(to: .main) { (data, error) in
                    if let data = data {
                        imuLock.lock()
                        currentIMUData.mag_x = Float(data.magneticField.x)
                        currentIMUData.mag_y = Float(data.magneticField.y)
                        currentIMUData.mag_z = Float(data.magneticField.z)
                        imuLock.unlock()
                    }
                }
            }
            
            var wasmModule: wasm_module_t?
            var moduleInstance: wasm_module_inst_t?
            var execEnv: wasm_exec_env_t?
            
            // 1. Initialize the WAMR Runtime (Singleton)
            if !isWAMRInitialized {
                print("Initializing WAMR runtime...")
                guard wasm_runtime_init() else {
                    print("Fatal Error: WAMR runtime initialization failed.")
                    return
                }
                
                // Prepare Native Symbols
                let symbolName = "read_imu"
                let signature = "(*)" // pointer argument
                
                let symbolPtr = symbolName.withCString { strdup($0) }
                let signaturePtr = signature.withCString { strdup($0) }
                
                let cFunction: @convention(c) (wasm_exec_env_t?, UnsafeMutableRawPointer?) -> Void = read_imu_impl
                
                // Allocate NativeSymbol array on the heap to ensure it persists
                let nativeSymbolPtr = UnsafeMutablePointer<NativeSymbol>.allocate(capacity: 1)
                nativeSymbolPtr.initialize(to: NativeSymbol(
                    symbol: UnsafePointer(symbolPtr),
                    func_ptr: unsafeBitCast(cFunction, to: UnsafeMutableRawPointer.self),
                    signature: UnsafePointer(signaturePtr),
                    attachment: nil
                ))
                
                let moduleName = "host"
                let moduleNamePtr = moduleName.withCString { strdup($0) }
                
                // Save globals to prevent leak/GC issues (though we leak them intentionally for the app life)
                globalNativeSymbolPtr = nativeSymbolPtr
                globalModuleNamePtr = UnsafeMutablePointer(mutating: moduleNamePtr)
                
                // Register Natives
                guard wasm_runtime_register_natives(moduleNamePtr, nativeSymbolPtr, 1) else {
                    print("Error: Failed to register native symbols")
                    return
                }
                
                isWAMRInitialized = true
            }
            
            // Defer block ensures cleanup runs when the function exits.
            defer {
                if let env = execEnv {
                    wasm_runtime_destroy_exec_env(env)
                }
                if let inst = moduleInstance {
                    wasm_runtime_deinstantiate(inst)
                }
                if let mod = wasmModule {
                    wasm_runtime_unload(mod)
                }
                // DO NOT destroy runtime, as it cannot be easily re-initialized
                // wasm_runtime_destroy()
                
                // Stop sensors
                motionManager.stopAccelerometerUpdates()
                motionManager.stopGyroUpdates()
                motionManager.stopMagnetometerUpdates()
                
                print("WAMR module unloaded.")
            }
            
            // 2. Read WASM file
            guard let wasmURL = Bundle.main.url(forResource: "slam_main", withExtension: "wasm") else {
                print("Error: main.wasm file not found in bundle.")
                return
            }
            
            do {
                var wasmFileBuffer = try Data(contentsOf: wasmURL)
                
                var errorBuffer = [CChar](repeating: 0, count: 128)
                let wasmFileSize = UInt32(wasmFileBuffer.count)
                
                wasmFileBuffer.withUnsafeMutableBytes { wasmFilePtr in
                    guard let wasmFileCArray = wasmFilePtr.baseAddress?.assumingMemoryBound(to: UInt8.self) else { return }
                    
                    // 3. Load the WASM module
                    print("Loading module")
                    wasmModule = wasm_runtime_load(wasmFileCArray, wasmFileSize, &errorBuffer, UInt32(errorBuffer.count))
                    
                    guard let module = wasmModule else {
                        let errorMsg = String(cString: errorBuffer)
                        print("Error: WAMR failed to load module: \(errorMsg)")
                        return
                    }
                    
                    var instArgs = InstantiationArgs()
                    instArgs.default_stack_size = UInt32(64 * 1024)        // 64 KB stack
                    instArgs.host_managed_heap_size = UInt32(2 * 1024 * 1024) // 2 MB host-managed heap (bytes)
                    instArgs.max_memory_pages = UInt32(256) // 256 pages * 64KiB/page = 16 MB max
                    
                    guard let instance = wasm_runtime_instantiate_ex(module, &instArgs, &errorBuffer, UInt32(errorBuffer.count)) else {
                        let msg = String(cString: errorBuffer)
                        print("Instantiation failed: \(msg)")
                        return
                    }
                    
                    // 5. Create an execution environment (ExecEnv)
                    execEnv = wasm_runtime_create_exec_env(instance, self.defaultStackSize)
                    
                    guard let env = execEnv else {
                        print("Error: WAMR failed to create execution environment.")
                        return
                    }
                    
                    // 6. Look up the exported "main" function
                    let funcName = "_start"
                    let funcInst = wasm_runtime_lookup_function(instance, funcName)
                    
                    guard let function = funcInst else {
                        print("Error: WAMR failed to find function '\(funcName)'.")
                        return
                    }
                    
                    // 7. Prepare arguments and call the function
                    print("Calling exported function '\(funcName)()'...")
                    
                    // Signature: () -> i32. Array: [Result: i32]
                    var argv: [UInt32] = [0]
                    let argc = UInt32(argv.count)
                    
                    // NOTE: Arguments are removed because C/C++ main() takes no arguments (or takes argc/argv, which is a different signature handled specially).
                    
                    let success = argv.withUnsafeMutableBufferPointer { argvPtr in
                        let argvCArray = argvPtr.baseAddress
                        return wasm_runtime_call_wasm(env, function, argc, argvCArray)
                    }
                    
                    guard success else {
                        let exception = wasm_runtime_get_exception(instance)
                        let exceptionString = exception != nil ? String(cString: exception!) : "Unknown error"
                        print("Error: WASM function call failed: \(exceptionString)")
                        return
                    }
                    
                    // 8. Retrieve the result (the exit code stored in argv[0])
                    let result = Int32(argv[0])
                    print("Success! WASM execution complete. Exit code: \(result)")
                    // If main() prints output, it will appear in the console.
                }
            } catch {
                // self.wasmResult = "Error: \(error.localizedDescription)" // Assuming self.wasmResult is defined elsewhere
                print("Error: \(error.localizedDescription)")
            }
        }
	}
}
