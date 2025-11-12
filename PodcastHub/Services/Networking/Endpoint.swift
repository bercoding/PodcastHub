import Foundation

enum Endpoint {
    case trending(page: Int, pageSize: Int)
    case search(query: String, page: Int, pageSize: Int)
    case showDetail(id: String)
    case rssFeed(url: URL)

    private var baseURL: URL {
        // Listen Notes API base
        URL(string: "https://listen-api.listennotes.com/api/v2")!
    }

    private var path: String {
        switch self {
        case .trending:
            "/best_podcasts"
        case .search:
            "/search"
        case let .showDetail(id):
            "/podcasts/\(id)"
        case .rssFeed:
            ""
        }
    }

    private var method: String {
        "GET"
    }

    private var headers: [String: String] {
        var headers = [
            "Content-Type": "application/json"
        ]
        if let apiKey = Secrets.listenNotesAPIKey, !apiKey.isEmpty {
            headers["X-ListenAPI-Key"] = apiKey
        }
        return headers
    }

    private var queryItems: [URLQueryItem] {
        switch self {
        case let .trending(page, pageSize):
            [
                .init(name: "page", value: String(page)),
                .init(name: "page_size", value: String(pageSize)),
                .init(name: "region", value: "us")
            ]
        case let .search(query, page, pageSize):
            [
                .init(name: "q", value: query),
                .init(name: "type", value: "podcast"),
                .init(name: "offset", value: String(max((page - 1) * pageSize, 0))),
                .init(name: "len_min", value: "5"),
                .init(name: "len_max", value: "300")
            ]
        case .showDetail:
            [
                .init(name: "sort", value: "recent_first")
            ]
        case .rssFeed:
            []
        }
    }

    var urlRequest: URLRequest {
        switch self {
        case let .rssFeed(url):
            return URLRequest(url: url)
        default:
            var components = URLComponents(
                url: baseURL.appendingPathComponent(path),
                resolvingAgainstBaseURL: false
            )
            components?.queryItems = queryItems
            guard let url = components?.url else {
                preconditionFailure("Không tạo được URL cho endpoint \(self)")
            }
            var request = URLRequest(url: url)
            request.httpMethod = method
            headers.forEach { request.addValue($1, forHTTPHeaderField: $0) }
            return request
        }
    }
}
