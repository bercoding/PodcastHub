import Foundation

protocol APIClientType {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func request<T: Decodable>(_ request: URLRequest) async throws -> T
    func data(for url: URL) async throws -> Data
}

final class APIClient: APIClientType {
    private let urlSession: URLSession
    private let decoder: JSONDecoder

    init(
        urlSession: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.urlSession = urlSession
        self.decoder = decoder
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder.dateDecodingStrategy = .iso8601
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let urlRequest = endpoint.urlRequest
        return try await request(urlRequest)
    }

    func request<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(code: httpResponse.statusCode, data: data)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decoding(error)
        }
    }

    func data(for url: URL) async throws -> Data {
        let (data, response) = try await urlSession.data(from: url)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(code: httpResponse.statusCode, data: data)
        }
        return data
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case httpError(code: Int, data: Data)
    case decoding(Error)

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            "URL không hợp lệ."
        case .invalidResponse:
            "Phản hồi không hợp lệ."
        case let .httpError(code, _):
            "Máy chủ trả về lỗi HTTP \(code)."
        case let .decoding(error):
            "Không parse được JSON: \(error.localizedDescription)"
        }
    }
}
