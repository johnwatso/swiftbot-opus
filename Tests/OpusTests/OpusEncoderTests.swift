import AVFoundation
import XCTest

@testable import Opus

final class OpusEncoderTests: XCTestCase {
	func testInit() throws {
		try AVAudioFormatTests.validFormats.forEach {
			_ = try Opus.Encoder(format: $0)
		}

		try AVAudioFormatTests.invalidFormats.forEach {
			XCTAssertThrowsError(try Opus.Encoder(format: $0)) { error in
				XCTAssertEqual(error as! Opus.Error, Opus.Error.badArgument)
			}
		}
	}

	func testRejectsMismatchedInputFormat() throws {
		let encoderFormat = AVAudioFormat(opusPCMFormat: .float32, sampleRate: .opus48khz, channels: 2)!
		let inputFormat = AVAudioFormat(opusPCMFormat: .int16, sampleRate: .opus48khz, channels: 2)!
		let input = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: 960)!
		input.frameLength = 960
		let encoder = try Opus.Encoder(format: encoderFormat)
		var output = Data(count: 1_275)

		XCTAssertThrowsError(try encoder.encode(input, to: &output)) { error in
			XCTAssertEqual(error as? Opus.Error, .badArgument)
		}
	}

	func testRejectsEmptyOutputBuffer() throws {
		let format = AVAudioFormat(opusPCMFormat: .float32, sampleRate: .opus48khz, channels: 2)!
		let input = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 960)!
		input.frameLength = 960
		let encoder = try Opus.Encoder(format: format)
		var output = Data()

		XCTAssertThrowsError(try encoder.encode(input, to: &output)) { error in
			XCTAssertEqual(error as? Opus.Error, .bufferTooSmall)
		}
	}
}
