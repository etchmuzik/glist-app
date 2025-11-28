import Foundation

struct KYCSubmission: Identifiable, Codable, Sendable {
    let id: String
    let userId: String
    let fullName: String
    let documentType: String
    let documentNumber: String
    let documentFrontData: Data?
    let documentBackData: Data?
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
        documentFrontData: Data? = nil,
        documentBackData: Data? = nil,
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
        self.documentFrontData = documentFrontData
        self.documentBackData = documentBackData
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
