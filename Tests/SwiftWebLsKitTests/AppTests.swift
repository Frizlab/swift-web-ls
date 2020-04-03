import XCTVapor

@testable import SwiftWebLsKit



final class AppTests: XCTestCase {
	
	func testAppInit() throws {
		let app = Application(.testing)
		defer {app.shutdown()}
		try configure(app)
		
		/* TODO! */
	}
	
}
