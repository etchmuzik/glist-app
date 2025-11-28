import SwiftUI

struct TableBookingView: View {
    let venue: Venue
    @Environment(\.locale) private var locale
    @State private var selectedDate = Date()
    @State private var selectedTable: Table?
    @State private var showCheckout = false
    @State private var adjustedMinimumSpend: Double?
    @State private var isPricingLoading = false
    
    var body: some View {
        ZStack {
            Color.theme.background.ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("BOOK A TABLE")
                                .font(Theme.Fonts.body(size: 12))
                                .fontWeight(.bold)
                                .foregroundStyle(Color.theme.accent)
                            
                            Text(venue.name.uppercased())
                                .font(Theme.Fonts.display(size: 32))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Date Picker
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("SELECT DATE")
                                        .font(Theme.Fonts.body(size: 12))
                                        .fontWeight(.bold)
                                        .foregroundStyle(.gray)
                                    Text(selectedDate.formatted(date: .complete, time: .omitted))
                                        .font(Theme.Fonts.body(size: 12))
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                Spacer()
                                Image(systemName: "calendar")
                                    .foregroundStyle(Color.theme.accent)
                            }
                            .padding(.horizontal, 20)
                            
                            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .colorScheme(.dark)
                                .padding(16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.04), Color.black.opacity(0.4)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                                )
                                .padding(.horizontal, 20)
                                .onChange(of: selectedDate) { _, _ in
                                    withAnimation {
                                        proxy.scrollTo("tablesSection", anchor: .top)
                                    }
                                    if let table = selectedTable {
                                        recalculatePricing(for: table)
                                    }
                                }
                        }
                        
                        // Tables List
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("AVAILABLE TABLES")
                                    .font(Theme.Fonts.body(size: 12))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray)
                                
                                Spacer()
                                
                                if selectedTable == nil {
                                    Text("Select a table to continue")
                                        .font(Theme.Fonts.caption())
                                        .foregroundStyle(Color.theme.accent)
                                        .transition(.opacity)
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            if venue.tables.isEmpty {
                                Text("No tables available for this venue.")
                                    .font(Theme.Fonts.body(size: 14))
                                    .foregroundStyle(.gray)
                                    .padding(.horizontal, 20)
                            } else {
                                ForEach(venue.tables) { table in
                                    TableCard(table: table, isSelected: selectedTable?.id == table.id) {
                                        withAnimation {
                                            selectedTable = table
                                        }
                                        recalculatePricing(for: table)
                                    }
                                }
                            }
                        }
                        .id("tablesSection") // Added ID for scrolling
                    }
                    .padding(.bottom, 100)
                }
            }
            
            // Bottom Bar
            if let table = selectedTable {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        // Policies
                        let rules = BookingRulesProvider.forVenue(venue)
                        PolicyDisclosureRow(
                            rules: rules,
                            contextText: "By booking, you agree to: ID • Dress Code • Deposit"
                        )
                        
                        HStack(alignment: .center) {
                            VStack(alignment: .leading) {
                                Text("DEPOSIT REQUIRED")
                                    .font(Theme.Fonts.body(size: 10))
                                    .foregroundStyle(.gray)
                                
                                let effectiveMinimum = adjustedMinimumSpend ?? table.minimumSpend
                                Text(CurrencyFormatter.aed(effectiveMinimum * 0.20, locale: locale))
                                    .font(Theme.Fonts.display(size: 24))
                                    .foregroundStyle(.white)
                                
                                if adjustedMinimumSpend != nil {
                                    Text("F1 weekend pricing applied")
                                        .font(Theme.Fonts.caption())
                                        .foregroundStyle(Color.theme.accent)
                                }
                                
                                if isPricingLoading {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                }
                            }
                            
                            Spacer()
                            
                            Button {
                                showCheckout = true
                            } label: {
                                Text("CONTINUE")
                                    .font(Theme.Fonts.body(size: 14))
                                    .fontWeight(.bold)
                                    .foregroundStyle(.black)
                                    .padding(.horizontal, 32)
                                    .padding(.vertical, 16)
                                    .background(
                                        LinearGradient(
                                            colors: [Color.white, Color.white.opacity(0.85)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .clipShape(Capsule())
                                    .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 8)
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        LinearGradient(
                            colors: [Color.black.opacity(0.8), Color.theme.surface.opacity(0.9)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: -10)
                    .transition(.move(edge: .bottom))
                }
                .ignoresSafeArea()
            }
        }
        .sheet(isPresented: $showCheckout) {
            if let table = selectedTable {
                CheckoutView(venue: venue, table: table, date: selectedDate)
            }
        }
    }
}

// MARK: - Helpers

extension TableBookingView {
    private func recalculatePricing(for table: Table) {
        isPricingLoading = true
        Task {
            let adjusted = await PaymentsManager.shared.adjustedPriceForF1(basePrice: table.minimumSpend, date: selectedDate)
            await MainActor.run {
                adjustedMinimumSpend = adjusted != table.minimumSpend ? adjusted : nil
                isPricingLoading = false
            }
        }
    }
}

struct TableCard: View {
    let table: Table
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.locale) private var locale
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white : Color.theme.surface)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "table.furniture")
                        .foregroundStyle(isSelected ? .black : .white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(table.name.uppercased())
                        .font(Theme.Fonts.display(size: 16))
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 12) {
                        Label("\(table.capacity) Guests", systemImage: "person.2.fill")
                        Label("Min. \(CurrencyFormatter.aed(table.minimumSpend, locale: locale))", systemImage: "dollarsign.circle.fill")
                    }
                    .font(Theme.Fonts.body(size: 12))
                    .foregroundStyle(.gray)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
            }
            .padding(16)
            .background(isSelected ? Color.theme.surface : Color.theme.surface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.white.opacity(0.05), lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }
}
