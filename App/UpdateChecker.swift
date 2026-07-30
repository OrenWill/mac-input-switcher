import Foundation

struct UpdateInfo {
    let hasUpdate: Bool
    let currentVersion: String
    let latestVersion: String
    let downloadURL: String
}

final class UpdateChecker {

    private static let repoAPI = "https://api.github.com/repos/OrenWill/mac-input-switcher/releases/latest"
    private static let downloadPage = "https://github.com/OrenWill/mac-input-switcher/releases/latest"

    /// 获取当前应用版本号
    static var currentVersion: String {
        if let info = Bundle.main.infoDictionary,
           let v = info["CFBundleShortVersionString"] as? String {
            return v
        }
        return "1.0.0"
    }

    /// 检查更新（异步回调）
    static func check(completion: @escaping (UpdateInfo) -> Void) {
        guard let url = URL(string: repoAPI) else {
            completion(UpdateInfo(hasUpdate: false, currentVersion: currentVersion,
                                  latestVersion: "", downloadURL: ""))
            return
        }

        var req = URLRequest(url: url, timeoutInterval: 10)
        req.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        req.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        URLSession.shared.dataTask(with: req) { data, response, error in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let tag = json["tag_name"] as? String {

                let latest = tag.hasPrefix("v") ? String(tag.dropFirst()) : tag
                let cur = currentVersion
                let hasUpdate = compareVersions(latest, cur) > 0

                let info = UpdateInfo(
                    hasUpdate: hasUpdate,
                    currentVersion: cur,
                    latestVersion: latest,
                    downloadURL: downloadPage
                )
                DispatchQueue.main.async { completion(info) }
            } else {
                DispatchQueue.main.async {
                    completion(UpdateInfo(hasUpdate: false, currentVersion: currentVersion,
                                          latestVersion: "", downloadURL: ""))
                }
            }
        }.resume()
    }

    /// 简易版本比较：按 "." 分割逐段比较
    private static func compareVersions(_ a: String, _ b: String) -> Int {
        let pa = a.split(separator: ".").compactMap { Int($0) }
        let pb = b.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(pa.count, pb.count) {
            let va = i < pa.count ? pa[i] : 0
            let vb = i < pb.count ? pb[i] : 0
            if va > vb { return 1 }
            if va < vb { return -1 }
        }
        return 0
    }
}
