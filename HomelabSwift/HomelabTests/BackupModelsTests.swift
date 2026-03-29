import XCTest
@testable import Homelab

final class BackupModelsTests: XCTestCase {
    func testPangolinBackupMapperRoundTrip() {
        XCTAssertEqual(BackupServiceTypeMapper.backupKey(for: .pangolin), "pangolin")
        XCTAssertEqual(BackupServiceTypeMapper.serviceType(from: "pangolin"), .pangolin)

        let entry = BackupServiceEntry(
            type: "pangolin",
            label: "Pangolin Edge",
            url: "https://pangolin.local",
            token: nil,
            username: nil,
            apiKey: "pangolin-key",
            piholePassword: nil,
            piholeAuthMode: nil,
            fallbackUrl: "https://pangolin.example.com",
            allowSelfSigned: false,
            password: nil,
            isPreferred: true
        )

        let instance = entry.toServiceInstance()
        XCTAssertEqual(instance?.type, .pangolin)
        XCTAssertEqual(instance?.apiKey, "pangolin-key")
        XCTAssertEqual(instance?.fallbackUrl, "https://pangolin.example.com")
    }
}
