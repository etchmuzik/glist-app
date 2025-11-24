import Foundation

enum ReportingManager {
    static func csv(from rows: [FinanceReportRow], dateFormatter: DateFormatter = ReportingManager.defaultDateFormatter()) -> String {
        guard !rows.isEmpty else {
            return "InvoiceNumber,InvoiceDate,CustomerName,CustomerEmail,VenueLegalEntity,NetAmount,VATRate,VATAmount,Total,Currency,BookingId,PromoterCode,Campaign,PaymentMethod\n"
        }
        
        let header = "InvoiceNumber,InvoiceDate,CustomerName,CustomerEmail,VenueLegalEntity,NetAmount,VATRate,VATAmount,Total,Currency,BookingId,PromoterCode,Campaign,PaymentMethod"
        let body = rows.map { row in
            [
                row.invoiceNumber,
                dateFormatter.string(from: row.invoiceDate),
                row.customerName,
                row.customerEmail,
                row.venueLegalEntity,
                row.netAmount,
                row.vatRate,
                row.vatAmount,
                row.total,
                row.currency,
                row.bookingId,
                row.promoterCode ?? "",
                row.campaign ?? "",
                row.paymentMethod ?? ""
            ].map { csvEscape($0) }
                .joined(separator: ",")
        }.joined(separator: "\n")
        
        return "\(header)\n\(body)\n"
    }
    
    static func defaultDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }
    
    private static func csvEscape(_ value: Any) -> String {
        switch value {
        case let string as String:
            if string.contains(",") || string.contains("\"") || string.contains("\n") {
                let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(escaped)\""
            } else {
                return string
            }
        case let double as Double:
            return String(format: "%.2f", double)
        default:
            return "\(value)"
        }
    }
}
