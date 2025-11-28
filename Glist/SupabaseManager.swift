import Foundation
import Supabase

final class SupabaseManager: Sendable {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: "https://jhrzeovxdjhorwyadtec.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Impocnplb3Z4ZGpob3J3eWFkdGVjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQwODQ3NDIsImV4cCI6MjA3OTY2MDc0Mn0.KBCBGDoF38pzt_BoaUeMnU2hVZTmIlJngKPkM3TCpgI"
        self.client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey,
            options: SupabaseClientOptions(
                auth: SupabaseClientOptions.AuthOptions(
                    emitLocalSessionAsInitialSession: true
                )
            )
        )
    }
    
    func uploadImage(data: Data, bucket: String, path: String) async throws -> URL {
        let options = FileOptions(cacheControl: "3600", contentType: "image/jpeg", upsert: false)
        _ = try await client.storage.from(bucket).upload(path: path, file: data, options: options)
        let url = try client.storage.from(bucket).getPublicURL(path: path)
        return url
    }
}

// Helper for heterogeneous dictionaries

