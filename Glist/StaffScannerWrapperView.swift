import SwiftUI

struct StaffScannerWrapperView: View {
    @EnvironmentObject var venueManager: VenueManager
    @StateObject private var staffManager = StaffModeManager()
    @State private var selectedVenueId: String?
    @State private var entranceId: String = "Main Entrance"
    @State private var syncMessage: String?
    
    // Optional: Allow passing specific venues (e.g. for Venue Manager)
    var availableVenues: [Venue]?
    
    var venuesToShow: [Venue] {
        availableVenues ?? venueManager.venues
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Picker("Venue", selection: Binding(
                    get: { selectedVenueId ?? venuesToShow.first?.id.uuidString ?? "" },
                    set: { selectedVenueId = $0 }
                )) {
                    ForEach(venuesToShow, id: \.id) { venue in
                        Text(venue.name).tag(venue.id.uuidString)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                
                TextField("Entrance", text: $entranceId)
                    .textInputAutocapitalization(.words)
                    .padding(8)
                    .background(Color.theme.surface.opacity(0.2))
                    .cornerRadius(8)
            }
            .padding(.horizontal)
            
            if let venueId = selectedVenueId ?? venuesToShow.first?.id.uuidString {
                StaffCheckInView(
                    manager: staffManager,
                    venueId: venueId,
                    entranceId: entranceId,
                    syncHandler: { events in
                        // Stubbed backend sync: pretend all processed
                        await MainActor.run {
                            syncMessage = "Synced \(events.count) scans"
                        }
                        return events.map(\.id)
                    }
                )
            } else {
                Text("No venues available")
                    .foregroundColor(.gray)
            }
            
            if let syncMessage {
                Text(syncMessage)
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundColor(Color.theme.textSecondary)
                    .padding(.bottom)
            }
        }
        .onAppear {
            if selectedVenueId == nil {
                selectedVenueId = venuesToShow.first?.id.uuidString
            }
        }
    }
}
