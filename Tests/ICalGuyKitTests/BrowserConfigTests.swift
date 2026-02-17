import XCTest

@testable import ICalGuyKit

final class BrowserConfigTests: XCTestCase {
  func testVendorSpecificBrowser() {
    let config = BrowserConfig(
      defaultBrowser: "Safari",
      meet: "Google Chrome",
      zoom: "Firefox"
    )

    XCTAssertEqual(config.browser(for: .meet), "Google Chrome")
    XCTAssertEqual(config.browser(for: .zoom), "Firefox")
  }

  func testFallsBackToDefault() {
    let config = BrowserConfig(
      defaultBrowser: "Safari",
      meet: "Google Chrome"
    )

    XCTAssertEqual(config.browser(for: .teams), "Safari")
    XCTAssertEqual(config.browser(for: .webex), "Safari")
  }

  func testNilVendorReturnsDefault() {
    let config = BrowserConfig(defaultBrowser: "Safari", meet: "Google Chrome")
    XCTAssertEqual(config.browser(for: nil), "Safari")
  }

  func testReturnsNilWhenEmpty() {
    let config = BrowserConfig()
    XCTAssertNil(config.browser(for: .meet))
    XCTAssertNil(config.browser(for: nil))
  }

  func testVendorOverridesDefault() {
    let config = BrowserConfig(
      defaultBrowser: "Safari",
      meet: "Google Chrome",
      zoom: "Safari",
      teams: "Microsoft Edge",
      webex: "Google Chrome"
    )

    XCTAssertEqual(config.browser(for: .meet), "Google Chrome")
    XCTAssertEqual(config.browser(for: .zoom), "Safari")
    XCTAssertEqual(config.browser(for: .teams), "Microsoft Edge")
    XCTAssertEqual(config.browser(for: .webex), "Google Chrome")
  }
}
