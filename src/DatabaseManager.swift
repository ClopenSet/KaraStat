import Foundation // Still need Foundation for URL, FileManager, etc.

enum KeyStatsError: Error {
    case databaseInitializationFailed(String)
    case queryFailed(String)
}

class DatabaseManager {
    static let shared = DatabaseManager()

    private var db: Connection! // Connection type is from SQLite.swift
    private let keyCounts = Table("key_counts") // Table type is from SQLite.swift
    private let key = Expression<String>("key") // Expression type is from SQLite.swift
    private let count = Expression<Int>("count")

    private init() {
        do {
            let fileManager = FileManager.default
            // Get Application Support directory for sandbox-friendly data storage
            let appSupportUrl = try fileManager.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            // Create a dedicated subdirectory for KaraStat's data
            let appDataUrl = appSupportUrl.appendingPathComponent("KaraStat")
            try fileManager.createDirectory(at: appDataUrl, withIntermediateDirectories: true, attributes: nil)

            let dbPath = appDataUrl.appendingPathComponent("key_stats.sqlite").path
            print("KaraStat: Database path: \(dbPath)")

            // Initialize SQLite.swift Connection
            db = try Connection(dbPath)
            try setupTable()
            print("KaraStat: Database initialized successfully.")
        } catch {
            print("ERROR: KaraStat: Database initialization failed: \(error)")
            // It's crucial to handle this. If db is nil, subsequent operations will crash.
            fatalError("KaraStat: Failed to initialize database: \(error)")
        }
    }

    private func setupTable() throws {
        // Create table if it doesn't exist
        try db.run(keyCounts.create(ifNotExists: true) { t in
            t.column(key, primaryKey: true) // 'key' is the primary key (e.g., "return", "a")
            t.column(count, defaultValue: 0) // 'count' stores the number of presses
        })
    }

    func incrementKeyCount(keyName: String) {
        do {
            // Attempt to insert the key with count 0. If it already exists (primary key conflict), ignore.
            let insert = keyCounts.insert(or: .ignore, key <- keyName, count <- 0)
            try db.run(insert)

            // Now, update the count for the given key.
            let keyToUpdate = keyCounts.filter(key == keyName)
            let update = keyToUpdate.update(count += 1)
            try db.run(update)
            // Uncomment below for verbose logging of each key press increment
            // print("KaraStat: Incremented count for '\(keyName)'.")

        } catch {
            print("ERROR: KaraStat: Failed to increment count for '\(keyName)': \(error)")
        }
    }

    func getTopKeys(limit: Int = 10) -> [(String, Int)] {
        var results: [(String, Int)] = []
        do {
            // Order by count descending and limit the results
            for row in try db.prepare(keyCounts.order(count.desc).limit(limit)) {
                results.append((row[key], row[count]))
            }
        } catch {
            print("ERROR: KaraStat: Failed to fetch top keys: \(error)")
        }
        return results
    }

    func close() {
        // For SQLite.swift, the Connection object manages its lifecycle reasonably well.
        // Explicit `close()` is not usually needed unless you want to force resource release.
        // For a daemon-like app, the connection usually stays open until process termination.
        print("KaraStat: DatabaseManager: No explicit close needed for SQLite.swift Connection.")
    }

    deinit {
        // Final cleanup for the database manager
        print("KaraStat: DatabaseManager deinitialized.")
    }
}
