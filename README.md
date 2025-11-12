## PodcastHub

Ứng dụng Podcast/Audio Player hybrid UIKit/SwiftUI theo kiến trúc MVVM + Repository.

### Roadmap Theo Sprint
- **Sprint 0** (1–2 ngày): setup project, lint/format, Firebase/GCP, tài liệu kiến trúc, pre-commit, quản lý secrets.
- **Sprint 1** (1 tuần): Networking + Models + Persistence stub + UI Home/Search/ShowDetail + Unit test cơ bản.
- **Sprint 2** (1 tuần): Player UIKit + AVPlayer background, Realm offline-first, download, queue.
- **Sprint 3** (1 tuần): Firebase Auth/Firestore sync, FCM push, Remote Config, Cloud Functions, polish + test + demo.

### Cấu Trúc Thư Mục (dự kiến)
```
PodcastHub/
 ├─ App/                 # AppDelegate, SceneDelegate, AppRouter, DI container
 ├─ Common/              # Constants, Extensions, Helpers
 ├─ Services/
 │   ├─ Networking/      # APIClient, Endpoint, RSSParser, PodcastRepository
 │   ├─ Persistence/     # RealmStack, CoreDataStack, UserDefaultsStore
 │   ├─ Playback/        # PlaybackService, RemoteCommandHandler (Sprint 2)
 │   └─ Firebase/        # AuthService, FirestoreService, PushService (Sprint 3)
 ├─ Features/
 │   ├─ Home/
 │   ├─ Search/
 │   ├─ ShowDetail/
 │   ├─ Player/          # UIKit storyboard + view model
 │   └─ Settings/
 ├─ Resources/           # Storyboards, Assets, Localizable, Config plist
 └─ Scripts/             # Git hooks, build scripts
```

### Coding Conventions
- **MVVM + Repository**: ViewController ↔ ViewModel (Combine/closures) ↔ Repository ↔ DataSource (Remote/Local).
- **Dependency Injection** qua protocol + `AppContainer`.
- **UIKit trước, SwiftUI bổ sung module**: Player và flows chính bằng Storyboard; SwiftUI module (Widget/Settings) nhúng qua `UIHostingController`.
- **Error Handling**: dùng `AppError` + `Result`.
- **Async**: Ưu tiên async/await, Combine cho binding.
- **Naming**: CamelCase, suffix rõ (`…ViewModel`, `…Repository`, `…Service`).
- **Lint/Format**: Tuân thủ `.swiftlint.yml` và `.swiftformat`; pre-commit hook đã cấu hình.

### Quản Lý Secrets
1. Sao chép file mẫu:
   ```
   cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig
   ```
2. Cập nhật giá trị thật:
   ```
   LISTEN_NOTES_API_KEY = <key>
   FIREBASE_APP_ID = <app_id>
   FIREBASE_CLIENT_ID = <client_id>
   PODCAST_INDEX_API_KEY = <key>
   PODCAST_INDEX_API_SECRET = <secret>
   ```
3. Trong Xcode → Project → PodcastHub → chọn cả Debug/Release `Base Configuration` trỏ tới `Config/Secrets.xcconfig` (hoặc nhập thủ công ở Build Settings > User-Defined). Khi đó các giá trị sẽ được inject vào Info.plist.
4. `Config/Secrets.xcconfig` và `Config/GoogleService-Info.plist` đã bị ignore khỏi git.

### Podcast Index API
- Đăng ký tài khoản tại [podcastindex.org](https://podcastindex.org/) để lấy API key/secret (khuyến nghị dùng email domain riêng). Sau khi lấy key, nhớ rotate nếu đã chia sẻ công khai.
- App sử dụng `PodcastIndexRepository` (signed requests SHA1). Nếu không có key/secret, hệ thống tự fallback sang mock JSON (`MockData/podcasts.json`).
- Endpoint đã dùng:
  - `/podcasts/trending` cho màn Home.
  - `/search/byterm` cho tìm kiếm.
  - `/podcasts/byfeedid` + `/episodes/byfeedid` cho Show Detail.
- Có thể điều chỉnh `max` trong `PodcastIndexRepository` nếu muốn nhiều episode/show hơn.

### Pre-commit Hooks
- Script nằm ở `Scripts/git-hooks/pre-commit`. Để bật:
  ```
  git config core.hooksPath Scripts/git-hooks
  ```
- Hook sẽ chạy `swiftformat` và `swiftlint --strict` trước commit.

### Firebase / GCP
- Tạo project Firebase, tải `GoogleService-Info.plist` và đặt trong `Config/`.
- Thêm dependency qua SwiftPM: `FirebaseAnalytics`, `FirebaseAuth`, `FirebaseFirestore`, `FirebaseMessaging`, `FirebaseRemoteConfig`.
- `AppDelegate` sẽ gọi `FirebaseApp.configure()` (triển khai ở Sprint 3).

### Board & Test
- Quản lý backlog Sprint bằng Notion/Jira (kanban).
- Unit test ViewModel bằng XCTest, UI test luồng chính (bắt đầu từ Sprint 1).

### Yêu Cầu Build
- Xcode 15+, iOS 16+.
- SwiftLint & SwiftFormat (brew) – run `swiftlint --version`, `swiftformat --version`.


