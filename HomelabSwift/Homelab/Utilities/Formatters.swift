import Foundation

enum Formatters {

    static func formatBytes(_ bytes: Double, decimals: Int = 1) -> String {
        guard bytes > 0 else { return "0 B" }
        if bytes < 1 { return "\(round(bytes * pow(10, Double(decimals))) / pow(10, Double(decimals))) B" }
        let k: Double = 1024
        let sizes = ["B", "KB", "MB", "GB", "TB"]
        let i = Int(log(bytes) / log(k))
        let safeI = min(i, sizes.count - 1)
        let value = bytes / pow(k, Double(safeI))
        return "\(round(value * pow(10, Double(decimals))) / pow(10, Double(decimals))) \(sizes[safeI])"
    }

    static func formatUptime(from startedAt: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var start: Date?
        start = formatter.date(from: startedAt)
        if start == nil {
            formatter.formatOptions = [.withInternetDateTime]
            start = formatter.date(from: startedAt)
        }
        guard let startDate = start else { return "—" }

        let diff = Date().timeIntervalSince(startDate)
        let days = Int(diff / 86400)
        let hours = Int((diff.truncatingRemainder(dividingBy: 86400)) / 3600)
        let minutes = Int((diff.truncatingRemainder(dividingBy: 3600)) / 60)

        if days > 0 { return "\(days)d \(hours)h" }
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    static func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: dateString)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: dateString)
        }
        guard let d = date else { return dateString }
        let out = DateFormatter()
        out.dateStyle = .short
        out.timeStyle = .short
        return out.string(from: d)
    }

    static func formatUnixDate(_ timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func getContainerName(from names: [String]) -> String {
        guard !names.isEmpty else { return "Unknown" }
        return names[0].replacingOccurrences(of: "^/", with: "", options: .regularExpression)
    }

    static func calculateCpuPercent(cpuDelta: Double, systemDelta: Double, cpuCount: Int) -> Double {
        guard systemDelta > 0, cpuCount > 0 else { return 0 }
        return (cpuDelta / systemDelta) * Double(cpuCount) * 100.0
    }

    static func formatGiteaDate(_ dateString: String) -> String {
        return formatDate(dateString)
    }

    static func shortSHA(_ sha: String) -> String {
        guard sha.count >= 7 else { return sha }
        return String(sha.prefix(7))
    }

    static func formatNumber(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    static func formatPercent(_ value: Double, decimals: Int = 1) -> String {
        return String(format: "%.\(decimals)f%%", value)
    }

    static func formatGB(_ gb: Double, decimals: Int = 1) -> String {
        return String(format: "%.\(decimals)f GB", gb)
    }
}
