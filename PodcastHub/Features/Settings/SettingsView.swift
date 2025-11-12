import SwiftUI

struct SettingsView: View {
    @AppStorage("playbackSpeed") private var playbackSpeed: Double = 1.0
    @AppStorage("downloadQuality") private var downloadQuality: String = "high"
    @AppStorage("enableSync") private var enableSync: Bool = true

    var body: some View {
        NavigationView {
            Form {
                Section("Phát lại") {
                    HStack {
                        Text("Tốc độ phát")
                        Spacer()
                        Picker("", selection: $playbackSpeed) {
                            Text("0.5x").tag(0.5)
                            Text("1.0x").tag(1.0)
                            Text("1.25x").tag(1.25)
                            Text("1.5x").tag(1.5)
                            Text("2.0x").tag(2.0)
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("Tải xuống") {
                    Picker("Chất lượng", selection: $downloadQuality) {
                        Text("Thấp (64 kbps)").tag("low")
                        Text("Trung bình (128 kbps)").tag("medium")
                        Text("Cao (256 kbps)").tag("high")
                    }
                }

                Section("Đồng bộ") {
                    Toggle("Đồng bộ với Firebase", isOn: $enableSync)
                    if enableSync {
                        Button("Đăng nhập") {
                            // TODO: Implement Firebase Auth
                        }
                    }
                }

                Section("Thông tin") {
                    HStack {
                        Text("Phiên bản")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Cài đặt")
        }
    }
}

#Preview {
    SettingsView()
}
