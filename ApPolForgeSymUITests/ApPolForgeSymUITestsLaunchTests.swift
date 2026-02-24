//
//  ApPolForgeSymUITestsLaunchTests.swift
//  ApPolForgeSymUITests
//
//  Created by Donald Clark on 1/11/26.
//

import XCTest

final class ApPolForgeSymUITestsLaunchTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for the app's root view to appear before screenshotting
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
