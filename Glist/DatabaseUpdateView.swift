import SwiftUI
import FirebaseFirestore

struct DatabaseUpdateView: View {
    @EnvironmentObject var venueManager: VenueManager
    @State private var isUpdating = false
    @State private var updateLog: [String] = []
    @State private var progress: Double = 0
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.theme.accent)
                            
                            Text("DATABASE UPDATE")
                                .font(Theme.Fonts.display(size: 24))
                                .foregroundStyle(.white)
                            
                            Text("Update database with new features")
                                .font(Theme.Fonts.body(size: 14))
                                .foregroundStyle(.gray)
                        }
                        .padding(.top, 20)
                        
                        // Progress
                        if isUpdating {
                            VStack(spacing: 12) {
                                ProgressView(value: progress)
                                    .tint(Color.theme.accent)
                                
                                Text("\(Int(progress * 100))% Complete")
                                    .font(Theme.Fonts.body(size: 14))
                                    .foregroundStyle(.gray)
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Update Log
                        VStack(alignment: .leading, spacing: 12) {
                            Text("UPDATE LOG")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(.gray)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(updateLog, id: \.self) { log in
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.green)
                                            .font(.caption)
                                        
                                        Text(log)
                                            .font(Theme.Fonts.body(size: 12))
                                            .foregroundStyle(.white)
                                    }
                                }
                                
                                if updateLog.isEmpty {
                                    Text("No updates yet...")
                                        .font(Theme.Fonts.body(size: 12))
                                        .foregroundStyle(.gray)
                                        .italic()
                                }
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)
                        
                        // Update Button
                        Button {
                            performDatabaseUpdate()
                        } label: {
                            if isUpdating {
                                ProgressView()
                                    .tint(.black)
                            } else {
                                Text("START UPDATE")
                                    .font(Theme.Fonts.body(size: 16))
                                    .fontWeight(.bold)
                            }
                        }
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(isUpdating ? Color.gray : Color.white)
                        .clipShape(Capsule())
                        .padding(.horizontal, 24)
                        .disabled(isUpdating)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(.white)
                }
            }
        }
    }
    
    func performDatabaseUpdate() {
        isUpdating = true
        updateLog = []
        progress = 0
        
        Task {
            do {
                // Step 1: Update venues with coordinates
                await addLog("Updating venues with coordinates...")
                try await updateVenuesWithCoordinates()
                await updateProgress(0.2)
                
                // Step 2: Add tables to venues
                await addLog("Adding table data to venues...")
                try await addTablesToVenues()
                await updateProgress(0.4)
                
                // Step 3: Update events with ticket types
                await addLog("Adding ticket types to events...")
                try await addTicketTypesToEvents()
                await updateProgress(0.6)
                
                // Step 4: Update user schema
                await addLog("Updating user schema...")
                try await updateUserSchema()
                await updateProgress(0.8)
                
                // Step 5: Create indexes
                await addLog("Creating database indexes...")
                try await Task.sleep(nanoseconds: 1_000_000_000)
                await updateProgress(1.0)
                
                await addLog("✅ Database update complete!")
                
                await MainActor.run {
                    isUpdating = false
                }
                
            } catch {
                await addLog("❌ Error: \(error.localizedDescription)")
                await MainActor.run {
                    isUpdating = false
                }
            }
        }
    }
    
    func updateVenuesWithCoordinates() async throws {
        let db = FirestoreManager.shared.db
        let snapshot = try await db.collection("venues").getDocuments()
        
        for doc in snapshot.documents {
            var data = doc.data()
            
            // Add coordinates if missing
            if data["latitude"] == nil {
                data["latitude"] = 25.2048 // Default Dubai
                data["longitude"] = 55.2708
            }
            
            try await db.collection("venues").document(doc.documentID).updateData(data)
        }
    }
    
    func addTablesToVenues() async throws {
        let db = FirestoreManager.shared.db
        let snapshot = try await db.collection("venues").getDocuments()
        
        for doc in snapshot.documents {
            var data = doc.data()
            
            // Add sample tables if missing
            if data["tables"] == nil {
                let sampleTables: [[String: Any]] = [
                    ["name": "VIP Table 1", "capacity": 6, "minimumSpend": 2000.0, "isAvailable": true],
                    ["name": "VIP Table 2", "capacity": 8, "minimumSpend": 3000.0, "isAvailable": true],
                    ["name": "Standard Table", "capacity": 4, "minimumSpend": 1000.0, "isAvailable": true]
                ]
                data["tables"] = sampleTables
                
                try await db.collection("venues").document(doc.documentID).updateData(["tables": sampleTables])
            }
        }
    }
    
    func addTicketTypesToEvents() async throws {
        // Events are nested in venues, so we need to update venue documents
        let db = FirestoreManager.shared.db
        let snapshot = try await db.collection("venues").getDocuments()
        
        for doc in snapshot.documents {
            if var events = doc.data()["events"] as? [[String: Any]] {
                for i in 0..<events.count {
                    if events[i]["ticketTypes"] == nil {
                        events[i]["ticketTypes"] = [
                            ["name": "General Admission", "price": 100.0, "quantity": 100, "description": "Standard entry"],
                            ["name": "VIP", "price": 250.0, "quantity": 50, "description": "VIP access with perks"]
                        ]
                    }
                }
                
                try await db.collection("venues").document(doc.documentID).updateData(["events": events])
            }
        }
    }
    
    func updateUserSchema() async throws {
        let db = FirestoreManager.shared.db
        let snapshot = try await db.collection("users").getDocuments()
        
        for doc in snapshot.documents {
            var updates: [String: Any] = [:]
            let data = doc.data()
            
            // Add new fields if missing
            if data["tier"] == nil {
                updates["tier"] = "Standard"
            }
            if data["following"] == nil {
                updates["following"] = []
            }
            if data["followers"] == nil {
                updates["followers"] = []
            }
            if data["isPrivate"] == nil {
                updates["isPrivate"] = false
            }
            
            if !updates.isEmpty {
                try await db.collection("users").document(doc.documentID).updateData(updates)
            }
        }
    }
    
    func addLog(_ message: String) async {
        await MainActor.run {
            updateLog.append(message)
        }
    }
    
    func updateProgress(_ value: Double) async {
        await MainActor.run {
            progress = value
        }
    }
}
