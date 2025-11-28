import SwiftUI
import UIKit
#if canImport(PhotosUI)
import PhotosUI
#endif

struct VenueEditorView: View {
    @Environment(\.dismiss) var dismiss
    @State private var venue: Venue
    let onSave: (Venue) -> Void
    
    @State private var newTableName = ""
    @State private var newTableCapacity = "4"
    @State private var newTableMinSpend = "1000"
    @State private var newEventName = ""
    @State private var newEventDate = Date()
    @State private var newEventDescription = ""
    @State private var newScheduleDay = "Friday"
    @State private var newScheduleDesc = ""
    
#if canImport(PhotosUI)
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var previewImage: Image?
    @State private var isUploading = false
    @State private var uploadError: String?
#endif
    
    private let types = ["Nightclub", "Beach Club", "Lounge", "Rooftop Bar"]
    private let prices = ["$", "$$", "$$$", "$$$$"]
    
    init(venue: Venue, onSave: @escaping (Venue) -> Void) {
        self._venue = State(initialValue: venue)
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.theme.background.ignoresSafeArea()
                
                Form {
                    Section("BASIC INFO") {
                        TextField("Venue Name", text: $venue.name)
                        Picker("Type", selection: $venue.type) {
                            ForEach(types, id: \.self) { type in
                                Text(type).tag(type)
                            }
                        }
                        Picker("District", selection: $venue.district) {
                            ForEach(DubaiDistrict.allCases, id: \.self) { district in
                                Text(district.rawValue).tag(district)
                            }
                        }
                        TextField("Address / Location", text: $venue.location)
                        TextField("Description", text: $venue.description, axis: .vertical)
                            .lineLimit(3...6)
                    }
                    
                    Section("DETAILS") {
                        Picker("Price Range", selection: $venue.price) {
                            ForEach(prices, id: \.self) { price in
                                Text(price).tag(price)
                            }
                        }
                        TextField("Dress Code", text: $venue.dressCode)
                        Toggle("Verified", isOn: $venue.isVerified)
                    }
                    
                    Section("FEATURED PLACEMENT") {
                        Toggle("Featured", isOn: $venue.isFeatured)
                        if venue.isFeatured {
                            DatePicker("End Date", selection: Binding(get: {
                                venue.featureEndDate ?? Date().addingTimeInterval(7 * 86400)
                            }, set: { newValue in
                                venue.featureEndDate = newValue
                            }), displayedComponents: .date)
                            TextField("Purchase Amount (AED)", value: Binding(get: {
                                venue.featurePurchaseAmount ?? 0
                            }, set: { newValue in
                                venue.featurePurchaseAmount = newValue
                            }), formatter: NumberFormatter())
                            .keyboardType(.decimalPad)
                        }
                    }
                    
                    Section("IMAGES & TAGS") {
                        TextField("Image URL", text: Binding(get: {
                            venue.imageURL ?? ""
                        }, set: { venue.imageURL = $0.isEmpty ? nil : $0 }))
                        TextField("Tags (comma separated)", text: Binding(get: {
                            venue.tags.joined(separator: ", ")
                        }, set: { venue.tags = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) } }))
#if canImport(PhotosUI)
                        if let previewImage {
                            previewImage
                                .resizable()
                                .scaledToFill()
                                .frame(height: 140)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        if isUploading {
                            ProgressView("Uploading...")
                                .tint(.white)
                        }
                        if let uploadError {
                            Text(uploadError)
                                .font(Theme.Fonts.body(size: 12))
                                .foregroundStyle(.red)
                        }
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Select Photo", systemImage: "photo")
                        }
                        .onChange(of: selectedPhoto) { _, newValue in
                            Task {
                                if let data = try? await newValue?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    previewImage = Image(uiImage: uiImage)
                                    uploadError = nil
                                    isUploading = true
                                    if let url = await uploadVenueImage(data: data) {
                                        venue.imageURL = url.absoluteString
                                    } else {
                                        uploadError = "Upload failed."
                                    }
                                    isUploading = false
                                }
                            }
                        }
#endif
                    }
                    
                    Section("TABLES") {
                        ForEach(venue.tables.indices, id: \.self) { idx in
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Table Name", text: Binding(
                                    get: { venue.tables[idx].name },
                                    set: { venue.tables[idx].name = $0 }
                                ))
                                HStack {
                                    TextField("Capacity", text: Binding(
                                        get: { "\(venue.tables[idx].capacity)" },
                                        set: { venue.tables[idx].capacity = Int($0) ?? venue.tables[idx].capacity }
                                    ))
                                    .keyboardType(.numberPad)
                                    
                                    TextField("Min Spend", text: Binding(
                                        get: { String(format: "%.0f", venue.tables[idx].minimumSpend) },
                                        set: { venue.tables[idx].minimumSpend = Double($0) ?? venue.tables[idx].minimumSpend }
                                    ))
                                    .keyboardType(.decimalPad)
                                }
                            }
                        }
                        .onDelete { offsets in
                            venue.tables.remove(atOffsets: offsets)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Add Table")
                                .font(Theme.Fonts.body(size: 12))
                                .foregroundStyle(.gray)
                            TextField("Name", text: $newTableName)
                            HStack {
                                TextField("Capacity", text: $newTableCapacity)
                                    .keyboardType(.numberPad)
                                TextField("Min Spend", text: $newTableMinSpend)
                                    .keyboardType(.decimalPad)
                            }
                            Button("Add") {
                                guard !newTableName.isEmpty,
                                      let cap = Int(newTableCapacity),
                                      let spend = Double(newTableMinSpend) else { return }
                                venue.tables.append(Table(name: newTableName, capacity: cap, minimumSpend: spend))
                                newTableName = ""
                                newTableCapacity = "4"
                                newTableMinSpend = "1000"
                            }
                            .font(Theme.Fonts.body(size: 12))
                        }
                    }

                    Section("EVENTS") {
                        ForEach(venue.events.indices, id: \.self) { idx in
                            VStack(alignment: .leading, spacing: 6) {
                                TextField("Event Name", text: Binding(
                                    get: { venue.events[idx].name },
                                    set: { venue.events[idx].name = $0 }
                                ))
                                DatePicker("Date", selection: Binding(
                                    get: { venue.events[idx].date },
                                    set: { venue.events[idx].date = $0 }
                                ), displayedComponents: .date)
                                TextField("Description", text: Binding(
                                    get: { venue.events[idx].description ?? "" },
                                    set: { venue.events[idx].description = $0 }
                                ), axis: .vertical)
                            }
                        }
                        .onDelete { offsets in
                            venue.events.remove(atOffsets: offsets)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Add Event")
                                .font(Theme.Fonts.body(size: 12))
                                .foregroundStyle(.gray)
                            TextField("Name", text: $newEventName)
                            DatePicker("Date", selection: $newEventDate, displayedComponents: .date)
                            TextField("Description", text: $newEventDescription, axis: .vertical)
                            Button("Add") {
                                guard !newEventName.isEmpty else { return }
                                venue.events.append(Event(name: newEventName, date: newEventDate, imageUrl: nil, description: newEventDescription))
                                newEventName = ""
                                newEventDescription = ""
                                newEventDate = Date()
                            }
                            .font(Theme.Fonts.body(size: 12))
                        }
                    }

                    Section("WEEKLY SCHEDULE") {
                        ForEach(venue.weeklySchedule.keys.sorted(), id: \.self) { day in
                            HStack {
                                Text(day)
                                Spacer()
                                TextField("Detail", text: Binding(
                                    get: { venue.weeklySchedule[day] ?? "" },
                                    set: { venue.weeklySchedule[day] = $0 }
                                ))
                            }
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Add Schedule")
                                .font(Theme.Fonts.body(size: 12))
                                .foregroundStyle(.gray)
                            TextField("Day (e.g. Friday)", text: $newScheduleDay)
                            TextField("Description", text: $newScheduleDesc)
                            Button("Add") {
                                guard !newScheduleDay.isEmpty else { return }
                                venue.weeklySchedule[newScheduleDay] = newScheduleDesc
                                newScheduleDay = "Friday"
                                newScheduleDesc = ""
                            }
                            .font(Theme.Fonts.body(size: 12))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Venue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(venue)
                        dismiss()
                    }
                    .disabled(venue.name.isEmpty || venue.location.isEmpty)
                }
            }
        }
    }
}

#if canImport(PhotosUI)
extension VenueEditorView {
    fileprivate func uploadVenueImage(data: Data) async -> URL? {
        let filename = "\(UUID().uuidString)-\(Int(Date().timeIntervalSince1970)).jpg"
        let path = "venue-images/\(filename)"
        
        do {
            let url = try await SupabaseManager.shared.uploadImage(data: data, bucket: "venue-images", path: path)
            return url
        } catch {
            print("Upload error: \(error)")
            return nil
        }
    }
}
#endif

#Preview {
    VenueEditorView(venue: Venue(name: "Test", type: "Nightclub", location: "DXB", description: "", rating: 4.0, price: "$$", dressCode: "Smart", imageName: "", imageURL: nil, tags: [], latitude: 0, longitude: 0)) { _ in }
}
