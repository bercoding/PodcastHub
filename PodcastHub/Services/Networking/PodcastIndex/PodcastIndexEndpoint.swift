import Foundation

enum PodcastIndexEndpoint {
    case trending(max: Int)
    case search(query: String, max: Int)
    case feed(id: Int)
    case episodes(feedId: Int, max: Int)

    private var path: String {
        switch self {
        case .trending:
            "/podcasts/trending"
        case .search:
            "/search/byterm"
        case .feed:
            "/podcasts/byfeedid"
        case .episodes:
            "/episodes/byfeedid"
        }
    }

    private var queryItems: [URLQueryItem] {
        switch self {
        case let .trending(max):
            [
                URLQueryItem(name: "max", value: String(max))
            ]
        case let .search(query, max):
            [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "clean", value: "1"),
                URLQueryItem(name: "max", value: String(max))
            ]
        case let .feed(id):
            [
                URLQueryItem(name: "id", value: String(id))
            ]
        case let .episodes(feedId, max):
            [
                URLQueryItem(name: "id", value: String(feedId)),
                URLQueryItem(name: "max", value: String(max))
            ]
        }
    }

    func makeRequest(credentials: PodcastIndexCredentials) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.podcastindex.org"
        components.path = "/api/1.0\(path)"
        components.queryItems = queryItems

        guard let url = components.url else {
            preconditionFailure("Không tạo được URL cho PodcastIndex endpoint \(self)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        PodcastIndexAuthProvider.signedHeaders(for: credentials).forEach {
            request.setValue($1, forHTTPHeaderField: $0)
        }

        return request
    }
}
