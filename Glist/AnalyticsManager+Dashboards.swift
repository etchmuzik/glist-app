import Foundation

extension AnalyticsManager {
    func buildConversionStats(venueId: String, venueName: String, periodLabel: String, sessions: Int, selections: Int, holds: Int, confirmed: Int, cancellations: Int, noShows: Int) -> ConversionStats {
        ConversionStats(
            venueId: venueId,
            venueName: venueName,
            dateRangeLabel: periodLabel,
            sessions: sessions,
            selections: selections,
            holds: holds,
            confirmed: confirmed,
            cancellations: cancellations,
            noShows: noShows
        )
    }
    
    func buildOccupancySnapshot(venueId: String, venueName: String, date: Date, timeBandLabel: String, capacity: Int, booked: Int, waitlisted: Int, holdPending: Int) -> OccupancySnapshot {
        OccupancySnapshot(
            venueId: venueId,
            venueName: venueName,
            date: date,
            timeBandLabel: timeBandLabel,
            capacity: capacity,
            booked: booked,
            waitlisted: waitlisted,
            holdPending: holdPending
        )
    }
    
    func buildCancellationStats(venueId: String, venueName: String, periodLabel: String, cancellations: Int, lateCancellations: Int, noShows: Int, feesRecovered: Double) -> CancellationStats {
        CancellationStats(
            venueId: venueId,
            venueName: venueName,
            periodLabel: periodLabel,
            cancellations: cancellations,
            lateCancellations: lateCancellations,
            noShows: noShows,
            feesRecovered: feesRecovered
        )
    }
    
    func buildPromoterPerformanceRows(promoters: [Promoter], commissions: [Commission]) -> [PromoterPerformanceRow] {
        promoters.map { promoter in
            let earnings = commissions.filter { $0.promoterId == promoter.id }
            let revenue = earnings.reduce(0) { $0 + $1.amount }
            let payoutPaid = earnings.filter { $0.status == .paid }.reduce(0) { $0 + $1.amount }
            return PromoterPerformanceRow(
                id: promoter.id,
                promoterName: promoter.name,
                venueName: nil,
                covers: promoter.activeGuestLists,
                revenue: revenue,
                payoutAccrued: revenue,
                payoutPaid: payoutPaid
            )
        }
    }
    
    func buildCampaignPerformanceRows(attributions: [PromoterAttribution], bookings: [Booking], revenueLookup: [UUID: Double] = [:], discountsLookup: [UUID: Double] = [:], payoutLookup: [UUID: Double] = [:]) -> [CampaignPerformanceRow] {
        var grouped: [String: CampaignPerformanceRow] = [:]
        
        for attribution in attributions {
            let key = attribution.campaign ?? attribution.code
            let bookingId = attribution.bookingId
            let revenue = bookingId.flatMap { revenueLookup[$0] } ?? 0
            let discounts = bookingId.flatMap { discountsLookup[$0] } ?? 0
            let payout = bookingId.flatMap { payoutLookup[$0] } ?? 0
            let covers = bookingId.flatMap { _ in 1 } ?? 0
            
            if let existing = grouped[key] {
                grouped[key] = CampaignPerformanceRow(
                    id: existing.id,
                    campaign: existing.campaign,
                    source: existing.source ?? attribution.source,
                    medium: existing.medium ?? attribution.medium,
                    covers: existing.covers + covers,
                    revenue: existing.revenue + revenue,
                    discounts: existing.discounts + discounts,
                    payout: existing.payout + payout
                )
            } else {
                grouped[key] = CampaignPerformanceRow(
                    id: key,
                    campaign: key,
                    source: attribution.source,
                    medium: attribution.medium,
                    covers: covers,
                    revenue: revenue,
                    discounts: discounts,
                    payout: payout
                )
            }
        }
        
        return Array(grouped.values).sorted { $0.revenue > $1.revenue }
    }
}
