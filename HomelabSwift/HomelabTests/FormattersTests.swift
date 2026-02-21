import XCTest
@testable import Homelab

final class FormattersTests: XCTestCase {

    // MARK: - formatBytes

    func testFormatBytesZero() {
        XCTAssertEqual(Formatters.formatBytes(0), "0 B")
    }

    func testFormatBytesSmall() {
        XCTAssertEqual(Formatters.formatBytes(500), "500.0 B")
    }

    func testFormatBytesKilobytes() {
        XCTAssertEqual(Formatters.formatBytes(1024), "1.0 KB")
        XCTAssertEqual(Formatters.formatBytes(1536), "1.5 KB")
    }

    func testFormatBytesMegabytes() {
        XCTAssertEqual(Formatters.formatBytes(1048576), "1.0 MB")
        XCTAssertEqual(Formatters.formatBytes(10485760), "10.0 MB")
    }

    func testFormatBytesGigabytes() {
        XCTAssertEqual(Formatters.formatBytes(1073741824), "1.0 GB")
    }

    func testFormatBytesTerabytes() {
        XCTAssertEqual(Formatters.formatBytes(1099511627776), "1.0 TB")
    }

    // MARK: - formatPercent

    func testFormatPercent() {
        XCTAssertEqual(Formatters.formatPercent(0), "0.0%")
        XCTAssertEqual(Formatters.formatPercent(50.5), "50.5%")
        XCTAssertEqual(Formatters.formatPercent(100), "100.0%")
        XCTAssertEqual(Formatters.formatPercent(23.456, decimals: 2), "23.46%")
    }

    // MARK: - formatGB

    func testFormatGB() {
        XCTAssertEqual(Formatters.formatGB(0), "0.0 GB")
        XCTAssertEqual(Formatters.formatGB(1.5), "1.5 GB")
        XCTAssertEqual(Formatters.formatGB(10.25, decimals: 2), "10.25 GB")
    }

    // MARK: - formatNumber

    func testFormatNumber() {
        XCTAssertEqual(Formatters.formatNumber(0), "0")
        XCTAssertEqual(Formatters.formatNumber(42), "42")
        // Note: exact format depends on locale
        let result = Formatters.formatNumber(1000)
        XCTAssertTrue(result.contains("1") && result.contains("000"))
    }

    // MARK: - getContainerName

    func testGetContainerName() {
        XCTAssertEqual(Formatters.getContainerName(from: ["/my-container"]), "my-container")
        XCTAssertEqual(Formatters.getContainerName(from: ["/nginx", "/proxy"]), "nginx")
        XCTAssertEqual(Formatters.getContainerName(from: ["no-slash"]), "no-slash")
        XCTAssertEqual(Formatters.getContainerName(from: []), "Unknown")
    }

    // MARK: - shortSHA

    func testShortSHA() {
        XCTAssertEqual(Formatters.shortSHA("abc123def456789"), "abc123d")
        XCTAssertEqual(Formatters.shortSHA("short"), "short")
        XCTAssertEqual(Formatters.shortSHA("abc1234"), "abc1234")
    }

    // MARK: - calculateCpuPercent

    func testCalculateCpuPercent() {
        // Normal case
        let result = Formatters.calculateCpuPercent(cpuDelta: 1_000_000_000, systemDelta: 10_000_000_000, cpuCount: 4)
        XCTAssertEqual(result, 40.0, accuracy: 0.01)

        // Zero system delta
        XCTAssertEqual(Formatters.calculateCpuPercent(cpuDelta: 100, systemDelta: 0, cpuCount: 4), 0)

        // Zero CPU count
        XCTAssertEqual(Formatters.calculateCpuPercent(cpuDelta: 100, systemDelta: 1000, cpuCount: 0), 0)
    }

    // MARK: - formatUptime (ISO date string)

    func testFormatUptimeFromISO() {
        // Recent start (minutes ago)
        let minutesAgo = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-300))
        let result = Formatters.formatUptime(from: minutesAgo)
        XCTAssertTrue(result.contains("m"))

        // Hours ago
        let hoursAgo = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-7200))
        let resultH = Formatters.formatUptime(from: hoursAgo)
        XCTAssertTrue(resultH.contains("h"))

        // Days ago
        let daysAgo = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-172800))
        let resultD = Formatters.formatUptime(from: daysAgo)
        XCTAssertTrue(resultD.contains("d"))

        // Invalid input
        XCTAssertEqual(Formatters.formatUptime(from: "not-a-date"), "—")
    }

    // MARK: - formatDate

    func testFormatDate() {
        let dateStr = "2024-11-01T12:30:00Z"
        let result = Formatters.formatDate(dateStr)
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, dateStr) // Should be transformed

        // Invalid date falls back to original string
        XCTAssertEqual(Formatters.formatDate("not-a-date"), "not-a-date")
    }

    // MARK: - formatUnixDate

    func testFormatUnixDate() {
        let result = Formatters.formatUnixDate(1700000000)
        XCTAssertFalse(result.isEmpty)
    }
}
