import Foundation

// ----------------------------------------
// C-style Callback function
// ----------------------------------------
// This function is called by libkrbn when a HID value (like a key press) arrives.
private func hidValueCallback(
    _ deviceId: UInt64,
    _ isKeyboard: Bool,
    _ isPointingDevice: Bool,
    _ isGamePad: Bool,
    _ usagePage: Int32,
    _ usage: Int32,
    _ logicalMax: Int64,
    _ logicalMin: Int64,
    _ integerValue: Int64
) {
    // Only process keyboard events where a key is pressed down (integerValue != 0)
    guard isKeyboard, integerValue != 0 else {
        return
    }

    // Filter for momentary switch events (actual key presses, not modifier keys held down etc.)
    guard libkrbn_is_momentary_switch_event_target(usagePage, usage) else {
        return
    }

    // Get a JSON string representation of the key event
    var buffer = [CChar](repeating: 0, count: 256)
    libkrbn_get_momentary_switch_event_json_string(&buffer, buffer.count, usagePage, usage)
    let jsonString = String(cString: buffer)

    // Parse the JSON to extract the 'key_code' (e.g., "return", "spacebar", "a")
    if let data = jsonString.data(using: .utf8) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let keyCode = json["key_code"] as? String {
                // Increment the count for this key in the database
                DatabaseManager.shared.incrementKeyCount(keyName: keyCode)
            }
        } catch {
            print("ERROR: KaraStat: Failed to parse JSON for key event: \(error)")
        }
    }
}


// ----------------------------------------
// Main application logic
// ----------------------------------------

// Initialize our database manager singleton. This ensures the database connection is established.
_ = DatabaseManager.shared

print("KaraStat: Starting up...")

// Initialize libkrbn, enable HID monitor, and register the callback
libkrbn_initialize()
print("KaraStat: libkrbn initialized.")

libkrbn_enable_hid_value_monitor()
print("KaraStat: HID value monitor enabled.")

libkrbn_register_hid_value_arrived_callback(hidValueCallback)
print("KaraStat: Callback registered. Waiting for key events... (Press Control+C to exit)")

// Set up signal handling for graceful shutdown (e.g., when Control+C is pressed)
let sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
sigintSource.setEventHandler {
    print("\nKaraStat: SIGINT received, shutting down gracefully.")

    // Print the top 10 most pressed keys before exiting
    print("\n--- Top 10 Most Pressed Keys ---")
    let topKeys = DatabaseManager.shared.getTopKeys(limit: 10)
    if topKeys.isEmpty {
        print("No key data collected yet.")
    } else {
        for (key, count) in topKeys {
            print("  \(key): \(count) times")
        }
    }
    print("------------------------------")

    // Perform cleanup: disable monitor, terminate libkrbn, close database
    libkrbn_disable_hid_value_monitor()
    libkrbn_terminate()
    DatabaseManager.shared.close()

    // Exit the program
    exit(0)
}
sigintSource.resume() // Start listening for SIGINT

// Keep the main run loop alive so the program continues to run and receive events
RunLoop.main.run()

// The code below is a fallback and will typically not be reached if the signal handler works correctly.
libkrbn_disable_hid_value_monitor()
libkrbn_terminate()
DatabaseManager.shared.close()
print("KaraStat: Application terminated.")
