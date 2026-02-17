import XCTest

@testable import ICalGuyKit

final class BrowserResolverTests: XCTestCase {
  private let resolver = BrowserResolver()

  // MARK: - Priority Chain

  func testCLIBrowserTakesPriority() {
    let config = BrowserConfig(defaultBrowser: "Safari", meet: "Firefox")
    let result = resolver.resolveBrowserName(
      cliBrowser: "Google Chrome",
      vendor: .meet,
      config: config
    )
    XCTAssertEqual(result, "Google Chrome")
  }

  func testVendorConfigOverridesDefault() {
    let config = BrowserConfig(defaultBrowser: "Safari", meet: "Google Chrome")
    let result = resolver.resolveBrowserName(
      cliBrowser: nil,
      vendor: .meet,
      config: config
    )
    XCTAssertEqual(result, "Google Chrome")
  }

  func testDefaultConfigUsedWhenNoVendorMatch() {
    let config = BrowserConfig(defaultBrowser: "Safari")
    let result = resolver.resolveBrowserName(
      cliBrowser: nil,
      vendor: .teams,
      config: config
    )
    XCTAssertEqual(result, "Safari")
  }

  func testReturnsNilForSystemDefault() {
    let result = resolver.resolveBrowserName(
      cliBrowser: nil,
      vendor: .meet,
      config: nil
    )
    XCTAssertNil(result)
  }

  func testReturnsNilWhenNoConfigAndNoVendor() {
    let result = resolver.resolveBrowserName(
      cliBrowser: nil,
      vendor: nil,
      config: nil
    )
    XCTAssertNil(result)
  }

  func testDefaultConfigUsedWhenVendorNil() {
    let config = BrowserConfig(defaultBrowser: "Firefox")
    let result = resolver.resolveBrowserName(
      cliBrowser: nil,
      vendor: nil,
      config: config
    )
    XCTAssertEqual(result, "Firefox")
  }

  // MARK: - App Resolution

  func testResolveSafariInSystemApplications() {
    let result = resolver.resolveApplicationURL("Safari")
    switch result {
    case .success(let url):
      XCTAssertTrue(url.path.contains("Safari.app"))
    case .failure:
      XCTFail("Expected Safari to be found in /System/Applications")
    }
  }

  func testResolveAbsolutePath() {
    let result = resolver.resolveApplicationURL("/Applications/Safari.app")
    switch result {
    case .success(let url):
      XCTAssertEqual(url.path, "/Applications/Safari.app")
    case .failure:
      XCTFail("Expected absolute path to Safari to resolve")
    }
  }

  func testResolveNonexistentAppReturnsError() {
    let result = resolver.resolveApplicationURL("Nonexistent Browser XYZ")
    switch result {
    case .success:
      XCTFail("Expected failure for nonexistent app")
    case .failure(let error):
      XCTAssertTrue(error.localizedDescription.contains("Nonexistent Browser XYZ"))
    }
  }

  func testResolveAbsolutePathNonexistent() {
    let result = resolver.resolveApplicationURL("/Applications/FakeBrowser.app")
    switch result {
    case .success:
      XCTFail("Expected failure for nonexistent absolute path")
    case .failure(let error):
      XCTAssertTrue(error.localizedDescription.contains("FakeBrowser"))
    }
  }
}
