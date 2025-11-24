import Foundation

struct KYCSubmission: Identifiable, Codable {
    let id: String
    let userId: String
    let fullName: String
    let documentType: String
    let documentNumber: String
    let documentFrontURL: String?
    let documentBackURL: String?
    let selfieURL: String?
    let addressProofURL: String?
    var status: KYCStatus
    var notes: String?
    let submittedAt: Date
    var reviewedBy: String?
    var reviewedAt: Date?
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        fullName: String,
        documentType: String,
        documentNumber: String,
        documentFrontURL: String? = nil,
        documentBackURL: String? = nil,
        selfieURL: String? = nil,
        addressProofURL: String? = nil,
        status: KYCStatus = .pending,
        notes: String? = nil,
        submittedAt: Date = Date(),
        reviewedBy: String? = nil,
        reviewedAt: Date? = nil
    ) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.documentType = documentType
        self.documentNumber = documentNumber
        self.documentFrontURL = documentFrontURL
        self.documentBackURL = documentBackURL
        self.selfieURL = selfieURL
        self.addressProofURL = addressProofURL
        self.status = status
        self.notes = notes
        self.submittedAt = submittedAt
        self.reviewedBy = reviewedBy
        self.reviewedAt = reviewedAt
    }
}
