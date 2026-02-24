//
//  GripTitleUITests.swift
//  GripUITests
//
//  Created by luca on 13.10.2025.
//

import XCTest

final class GripTitleUITests: GripCustomConfigCase {
    override func setUp() async throws {
        try await super.setUp()
        try updateConfig(#"title = "GripUITestsLaunchTests""#)
    }

    @MainActor
    func testTitle() throws {
        let app = try gripApplication()
        app.launch()

        XCTAssertEqual(app.windows.firstMatch.title, "GripUITestsLaunchTests", "Oops, `title=` doesn't work!")
    }
}
