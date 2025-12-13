import Foundation
import CoreLocation

// MARK: - Models

struct LuckRequest: Codable {
    let uid: String
    let name: String
    let dob: String         // "YYYY-MM-DD"
    let birth_time: String  // "HH:mm"
    let birth_place_name: String
    let birth_lat: Double?
    let birth_lon: Double?
    let current_lat: Double?
    let current_lon: Double?
}

struct LuckResponse: Codable {
    let luck_score: Int
    let explanation: String
    let caption: String?
    let summary: String?
}

struct BirthInfoRequest: Codable {
    let dob: String
    let time: String
    let lat: Double
    let lon: Double
    let timezone: String
}

struct NatalChartResponse: Codable {
    let sun_sign: String
    let moon_sign: String
    let ascendant: String
    let strength_score: Int
    let planets: [String: PlanetData]
}

struct PlanetData: Codable {
    let sign: String
    let longitude: Double
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct LoginResponse: Codable {
    let success: Bool
    let uid: String
    let email: String
    let idToken: String
    let profile: BackendProfile // Backend format
    let warning: String?
}

// Backend profile format (from API)
struct BackendProfile: Codable {
    let name: String?
    let dob: String?
    let birth_place: String?
    // Add other fields as needed, handling potential missing keys
}

struct SignupRequest: Codable {
    let username: String
    let firstName: String
    let middleName: String
    let lastName: String
    let email: String
    let password: String
    let dob: String  // "YYYY-MM-DD"
}

struct SignupResponse: Codable {
    let success: Bool
    let uid: String
    let email: String
    let idToken: String
    let message: String
}

// MARK: - Network Service

class NetworkService {
    static let shared = NetworkService()
    private let geocoder = CLGeocoder()
    
    // NOTE: Change this to your local server IP for physical device!
    // Simulator uses localhost:8000
    private let baseURL = "https://omniluck-backend.onrender.com"
    
    // Helper: Geocode Address
    private func getCoordinates(for place: String) async -> (Double, Double)? {
        guard !place.isEmpty else { return nil }
        // Use swift async wrapper or simple check
        do {
            let placemarks = try await geocoder.geocodeAddressString(place)
            if let loc = placemarks.first?.location {
                return (loc.coordinate.latitude, loc.coordinate.longitude)
            }
        } catch {
            print("Geocoding error for \(place): \(error)")
        }
        return nil
    }
    
    // Helper: Formatters
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f.string(from: date)
    }
    private func formatTime(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "HH:mm"; return f.string(from: date)
    }
    
    // 0. Auth: Login
    func login(email: String, password: String) async throws -> LoginResponse {
         let payload = LoginRequest(email: email, password: password)
         return try await performRequest(endpoint: "/api/auth/login", body: payload)
    }
    
    // 0b. Auth: Signup
    func signup(username: String, firstName: String, middleName: String, lastName: String, email: String, password: String, dob: String) async throws -> SignupResponse {
        let payload = SignupRequest(username: username, firstName: firstName, middleName: middleName, lastName: lastName, email: email, password: password, dob: dob)
        return try await performRequest(endpoint: "/api/auth/signup", body: payload)
    }
    
    // 1. Fetch Daily Luck
    func fetchLuck(name: String, dob: Date, birthTime: Date, birthPlace: String, timeIsNA: Bool = false) async throws -> LuckResponse {
        // Geocode
        let coords = await getCoordinates(for: birthPlace)
        let lat = coords?.0 ?? 0.0
        let lon = coords?.1 ?? 0.0
        
        let payload = LuckRequest(
            uid: "ios-user",
            name: name,
            dob: formatDate(dob),
            birth_time: timeIsNA ? "" : formatTime(birthTime), // Send empty string if time is not known
            birth_place_name: birthPlace,
            birth_lat: lat,
            birth_lon: lon,
            current_lat: lat, // Assume user is at birth place or close for now
            current_lon: lon
        )
        
        return try await performRequest(endpoint: "/api/luck/calculate", body: payload)
    }
    
    // 2. Fetch Natal Chart
    func fetchNatalChart(dob: Date, birthTime: Date, birthPlace: String) async throws -> NatalChartResponse {
        // Geocode (Redundant if cached, but safer)
        let coords = await getCoordinates(for: birthPlace)
        let lat = coords?.0 ?? 0.0
        let lon = coords?.1 ?? 0.0
        
        let payload = BirthInfoRequest(
            dob: formatDate(dob),
            time: formatTime(birthTime),
            lat: lat,
            lon: lon,
            timezone: "UTC"
        )
        
        return try await performRequest(endpoint: "/api/astrology/natal-chart", body: payload)
    }
    
    // Generic Request
    private func performRequest<T: Codable, U: Codable>(endpoint: String, body: U) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(endpoint)") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            // Try to parse error message from backend
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            if let errJson = try? JSONDecoder().decode([String: String].self, from: data), let msg = errJson["detail"] {
                 throw NSError(domain: "", code: statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
            }
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}
