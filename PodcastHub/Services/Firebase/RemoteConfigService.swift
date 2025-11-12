import FirebaseRemoteConfig
import Foundation

protocol RemoteConfigServiceType {
    func fetchAndActivate() async throws
    func getString(for key: String) -> String
    func getInt(for key: String) -> Int
    func getBool(for key: String) -> Bool
}

final class RemoteConfigService: RemoteConfigServiceType {
    private let remoteConfig = RemoteConfig.remoteConfig()

    init() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 3600 // 1 hour
        remoteConfig.configSettings = settings

        // Default values
        remoteConfig.setDefaults([
            "max_trending_shows": 20 as NSNumber,
            "enable_downloads": true as NSNumber,
            "app_version": "1.0.0" as NSString
        ])
    }

    func fetchAndActivate() async throws {
        let status = try await remoteConfig.fetchAndActivate()
        print("✅ Remote Config fetched: \(status)")
    }

    func getString(for key: String) -> String {
        remoteConfig.configValue(forKey: key).stringValue ?? ""
    }

    func getInt(for key: String) -> Int {
        let value = remoteConfig.configValue(forKey: key)
        // numberValue returns NSNumber (non-optional)
        return value.numberValue.intValue
    }

    func getBool(for key: String) -> Bool {
        remoteConfig.configValue(forKey: key).boolValue
    }
}
