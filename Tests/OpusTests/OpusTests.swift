import AVFoundation
import Opus
import XCTest

final class OpusTests: XCTestCase {
	// Validate that namespaces are empty enums, with no values.
	func testEnumCases() {
		XCTAssertEqual(Opus.allCases.count, 0)
	}

}
