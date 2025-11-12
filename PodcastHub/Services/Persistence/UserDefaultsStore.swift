import Foundation

protocol UserDefaultsStoreType {
    func value<T>(for key: UserDefaultsKey<T>) -> T
    func set<T>(_ value: T, for key: UserDefaultsKey<T>)
    func removeValue(for key: String)
}

struct UserDefaultsKey<T> {
    let rawValue: String
    let defaultValue: T

    init(_ rawValue: String, defaultValue: T) {
        self.rawValue = rawValue
        self.defaultValue = defaultValue
    }
}

final class UserDefaultsStore: UserDefaultsStoreType {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func value<T>(for key: UserDefaultsKey<T>) -> T {
        userDefaults.object(forKey: key.rawValue) as? T ?? key.defaultValue
    }

    func set<T>(_ value: T, for key: UserDefaultsKey<T>) {
        userDefaults.set(value, forKey: key.rawValue)
    }

    func removeValue(for key: String) {
        userDefaults.removeObject(forKey: key)
    }
}

extension UserDefaultsKey where T == Double {
    static let lastPlaybackSpeed = UserDefaultsKey("lastPlaybackSpeed", defaultValue: 1.0)
}
