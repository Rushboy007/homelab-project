import XCTest
@testable import Homelab

@MainActor
final class ServicesStoreTests: XCTestCase {

    // MARK: - Initial State

    func testInitialState() {
        let store = ServicesStore()
        XCTAssertEqual(store.connectedCount, 0)
        XCTAssertFalse(store.isReady)
        XCTAssertFalse(store.isConnected(.portainer))
        XCTAssertFalse(store.isConnected(.pihole))
        XCTAssertFalse(store.isConnected(.beszel))
        XCTAssertFalse(store.isConnected(.gitea))
        XCTAssertNil(store.isReachable(.portainer))
    }

    // MARK: - Connect / Disconnect

    func testConnectService() async {
        let store = ServicesStore()
        let conn = ServiceConnection(type: .portainer, url: "https://portainer.local", token: "jwt123")

        await store.connectService(conn)

        XCTAssertTrue(store.isConnected(.portainer))
        XCTAssertEqual(store.connectedCount, 1)
        XCTAssertNotNil(store.connection(for: .portainer))
        XCTAssertEqual(store.connection(for: .portainer)?.url, "https://portainer.local")
    }

    func testDisconnectService() async {
        let store = ServicesStore()
        let conn = ServiceConnection(type: .pihole, url: "https://pihole.local", token: "sid123")

        await store.connectService(conn)
        XCTAssertTrue(store.isConnected(.pihole))

        store.disconnectService(.pihole)
        XCTAssertFalse(store.isConnected(.pihole))
        XCTAssertEqual(store.connectedCount, 0)
        XCTAssertNil(store.connection(for: .pihole))
    }

    func testConnectMultipleServices() async {
        let store = ServicesStore()

        await store.connectService(ServiceConnection(type: .portainer, url: "https://p.local", token: "t1"))
        await store.connectService(ServiceConnection(type: .pihole, url: "https://ph.local", token: "t2"))
        await store.connectService(ServiceConnection(type: .beszel, url: "https://b.local", token: "t3"))

        XCTAssertEqual(store.connectedCount, 3)
        XCTAssertTrue(store.isConnected(.portainer))
        XCTAssertTrue(store.isConnected(.pihole))
        XCTAssertTrue(store.isConnected(.beszel))
        XCTAssertFalse(store.isConnected(.gitea))
    }

    // MARK: - Reachability

    func testReachabilityNilWhenNotConnected() {
        let store = ServicesStore()
        XCTAssertNil(store.isReachable(.portainer))
    }

    func testIsPingingDefault() {
        let store = ServicesStore()
        XCTAssertFalse(store.isPinging(.portainer))
        XCTAssertFalse(store.isPinging(.pihole))
    }

    // MARK: - Update Fallback URL

    func testUpdateFallbackURL() async {
        let store = ServicesStore()
        let conn = ServiceConnection(type: .gitea, url: "https://gitea.local", token: "tok")

        await store.connectService(conn)
        XCTAssertNil(store.connection(for: .gitea)?.fallbackUrl)

        await store.updateFallbackURL(for: .gitea, fallbackUrl: "https://gitea.backup")
        XCTAssertEqual(store.connection(for: .gitea)?.fallbackUrl, "https://gitea.backup")

        // Empty string should clear fallback
        await store.updateFallbackURL(for: .gitea, fallbackUrl: "")
        XCTAssertNil(store.connection(for: .gitea)?.fallbackUrl)
    }

    // MARK: - ServiceType

    func testServiceTypeAllCases() {
        XCTAssertEqual(ServiceType.allCases.count, 4)
        XCTAssertTrue(ServiceType.allCases.contains(.portainer))
        XCTAssertTrue(ServiceType.allCases.contains(.pihole))
        XCTAssertTrue(ServiceType.allCases.contains(.beszel))
        XCTAssertTrue(ServiceType.allCases.contains(.gitea))
    }

    // MARK: - ServiceConnection

    func testServiceConnectionURLCleaning() {
        let conn = ServiceConnection(type: .portainer, url: "  https://portainer.local///  ", token: "t")
        XCTAssertEqual(conn.url, "https://portainer.local")
    }

    func testServiceConnectionEmptyFallback() {
        let conn1 = ServiceConnection(type: .pihole, url: "https://pi.local", token: "t", fallbackUrl: "")
        XCTAssertNil(conn1.fallbackUrl)

        let conn2 = ServiceConnection(type: .pihole, url: "https://pi.local", token: "t", fallbackUrl: nil)
        XCTAssertNil(conn2.fallbackUrl)

        let conn3 = ServiceConnection(type: .pihole, url: "https://pi.local", token: "t", fallbackUrl: "https://backup")
        XCTAssertEqual(conn3.fallbackUrl, "https://backup")
    }
}
