import Foundation

final class OfflineScanCache {
    static let shared = OfflineScanCache()
    
    private let queue = DispatchQueue(label: "offline-scan-cache")
    private var events: [ScanEvent] = []
    private let maxEvents = 500
    private let storageURL: URL
    
    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        storageURL = caches.appendingPathComponent("offline_scans.json")
        loadFromDisk()
    }
    
    func record(_ event: ScanEvent) {
        queue.sync {
            events.append(event)
            if events.count > maxEvents {
                events.removeFirst(events.count - maxEvents)
            }
            saveToDisk()
        }
    }
    
    func pending() -> [ScanEvent] {
        queue.sync { events }
    }
    
    func clearAll() {
        queue.sync {
            events.removeAll()
            saveToDisk()
        }
    }
    
    func remove(ids: [UUID]) {
        queue.sync {
            let idSet = Set(ids)
            events.removeAll { idSet.contains($0.id) }
            saveToDisk()
        }
    }
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(events)
            try data.write(to: storageURL, options: .atomic)
        } catch {
            print("Failed to persist offline scans: \(error)")
        }
    }
    
    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            let decoded = try JSONDecoder().decode([ScanEvent].self, from: data)
            events = decoded
        } catch {
            print("Failed to load offline scans: \(error)")
            events = []
        }
    }
}
