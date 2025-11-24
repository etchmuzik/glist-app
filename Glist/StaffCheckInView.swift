import SwiftUI
import Network

struct StaffCheckInView: View {
    @ObservedObject var manager: StaffModeManager
    let venueId: String
    let entranceId: String
    let syncHandler: (([ScanEvent]) async throws -> [UUID])?
    
    @State private var scannedCode: String?
    @State private var manualCode: String = ""
    @State private var isPresentingScanner = false
    @State private var isOnline = true
    @State private var isSyncing = false
    @State private var errorMessage: String?
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "staff-checkin-network")
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Label(isOnline ? "Online" : "Offline", systemImage: isOnline ? "wifi" : "wifi.slash")
                    .foregroundColor(isOnline ? .green : .orange)
                Spacer()
                Text("Entrance: \(entranceId)")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(.theme.textSecondary)
            }
            
            Button {
                isPresentingScanner = true
            } label: {
                HStack {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scan QR")
                        .font(Theme.Fonts.bodyBold())
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.theme.accent.opacity(0.1))
                .cornerRadius(12)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Manual check-in")
                    .font(Theme.Fonts.bodyBold())
                HStack {
                    TextField("Enter code", text: $manualCode)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding(10)
                        .background(Color.theme.surface.opacity(0.6))
                        .cornerRadius(8)
                    Button("Check in") {
                        recordScan(code: manualCode, manual: true)
                    }
                    .disabled(manualCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(Theme.Fonts.caption())
            }
            
            HStack {
                Text("Last scans")
                    .font(Theme.Fonts.bodyBold())
                Spacer()
                if isSyncing {
                    ProgressView()
                } else {
                    Button("Sync offline") {
                        Task { await syncOffline() }
                    }
                }
            }
            
            List(manager.lastScans.prefix(20)) { event in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(event.code)
                            .font(Theme.Fonts.bodyBold())
                        Spacer()
                        Text(event.result.rawValue)
                            .font(Theme.Fonts.caption())
                            .foregroundColor(event.result == .offlineQueued ? .orange : .green)
                    }
                    Text(event.scannedAt.formatted(date: .omitted, time: .shortened))
                        .font(Theme.Fonts.caption())
                        .foregroundColor(.theme.textSecondary)
                }
            }
        }
        .padding()
        .sheet(isPresented: $isPresentingScanner) {
            QRScannerView(scannedCode: $scannedCode) { code in
                recordScan(code: code, manual: false)
            }
        }
        .onAppear {
            startNetworkMonitor()
        }
        .onDisappear {
            monitor.cancel()
        }
    }
    
    private func recordScan(code: String?, manual: Bool) {
        guard let code = code?.trimmingCharacters(in: .whitespacesAndNewlines), !code.isEmpty else { return }
        errorMessage = nil
        let status: ScanResultStatus = isOnline ? .success : .offlineQueued
        manager.recordScan(
            code: code,
            venueId: venueId,
            entranceId: entranceId,
            guestName: nil,
            partySize: nil,
            result: status
        )
        manualCode = ""
    }
    
    private func syncOffline() async {
        guard let syncHandler else { return }
        isSyncing = true
        await manager.flushOffline { pending in
            try await syncHandler(pending)
        }
        isSyncing = false
    }
    
    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: monitorQueue)
    }
}
