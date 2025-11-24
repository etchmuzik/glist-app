import Foundation

enum PassServiceError: LocalizedError {
    case invalidBaseURL
    case badResponse(Int)
    case invalidContentType
    
    var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            return "Pass service URL is not configured."
        case .badResponse(let code):
            return "Pass service returned status \(code)."
        case .invalidContentType:
            return "Pass response is not a valid pkpass file."
        }
    }
}

final class PassService {
    static let shared = PassService()
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Fetches a signed .pkpass for a ticket ID from the backend.
    /// Configure Info.plist with key `PassServiceBaseURL` (e.g., https://api.example.com/passes).
    func fetchPass(ticketId: UUID) async throws -> Data? {
        guard let base = Bundle.main.object(forInfoDictionaryKey: "PassServiceBaseURL") as? String,
              let baseURL = URL(string: base) else {
            return nil
        }
        
        let url = baseURL.appendingPathComponent("\(ticketId.uuidString).pkpass")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/vnd.apple.pkpass", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PassServiceError.badResponse(-1)
        }
        guard 200..<300 ~= http.statusCode else {
            throw PassServiceError.badResponse(http.statusCode)
        }
        
        let mime = http.value(forHTTPHeaderField: "Content-Type") ?? ""
        guard mime.contains("application/vnd.apple.pkpass") else {
            throw PassServiceError.invalidContentType
        }
        
        return data
    }
}
