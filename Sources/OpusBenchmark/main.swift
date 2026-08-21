import AVFoundation
import Darwin
import Foundation
import Opus

@main
enum OpusBenchmark {
	static func main() {
		do {
			try run(arguments: Array(CommandLine.arguments.dropFirst()))
		}
		catch {
			FileHandle.standardError.write(Data("opus-benchmark failed: \(error)\n".utf8))
			exit(1)
		}
	}

	private static func run(arguments: [String]) throws {
		let iterations = try parseIterations(arguments)
		let format = AVAudioFormat(
			opusPCMFormat: .float32,
			sampleRate: .opus48khz,
			channels: 2
		)!
		let input = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 960)!
		input.frameLength = 960
		fillWithDeterministicSpeechLikeSignal(input)

		let encoder = try Opus.Encoder(format: format, application: .voip)
		try encoder.configure(
			.init(
				bitrate: 96_000,
				complexity: 8,
				usesVariableBitrate: true,
				usesConstrainedVariableBitrate: true,
				usesInbandFEC: true,
				expectedPacketLossPercentage: 10,
				signal: .voice,
				maximumBandwidth: .fullband
			))

		// Warm up allocation and codec state before timing the representative
		// 20 ms Discord/SwiftBot voice frame configuration.
		for _ in 0..<100 {
			_ = try encoder.encode(input)
		}

		var encodedByteCount = 0
		let startedAt = DispatchTime.now().uptimeNanoseconds
		for _ in 0..<iterations {
			encodedByteCount += try encoder.encode(input).count
		}
		let elapsedNanoseconds = DispatchTime.now().uptimeNanoseconds - startedAt
		let elapsedSeconds = Double(elapsedNanoseconds) / 1_000_000_000
		let audioSeconds = Double(iterations) * 0.02
		let averageMicroseconds = Double(elapsedNanoseconds) / Double(iterations) / 1_000
		let architecture: String
		#if arch(arm64)
			architecture = "arm64 (Apple silicon)"
		#elseif arch(x86_64)
			architecture = "x86_64"
		#else
			architecture = "unknown"
		#endif

		print("Opus voice encode benchmark")
		print("architecture: \(architecture)")
		print("frames: \(iterations) (\(String(format: "%.1f", audioSeconds)) s audio)")
		print("elapsed: \(String(format: "%.3f", elapsedSeconds)) s")
		print("average encode: \(String(format: "%.1f", averageMicroseconds)) µs/frame")
		print("throughput: \(String(format: "%.1f", Double(iterations) / elapsedSeconds)) frames/s")
		print("real-time factor: \(String(format: "%.1f", audioSeconds / elapsedSeconds))x")
		print("encoded bytes: \(encodedByteCount)")
	}

	private static func parseIterations(_ arguments: [String]) throws -> Int {
		guard !arguments.isEmpty else { return 5_000 }
		guard arguments.count == 2,
			arguments[0] == "--frames",
			let value = Int(arguments[1]),
			value > 0
		else {
			throw BenchmarkError.invalidArguments
		}
		return value
	}

	private static func fillWithDeterministicSpeechLikeSignal(_ buffer: AVAudioPCMBuffer) {
		guard let channels = buffer.floatChannelData else { return }
		let sampleRate = Float(buffer.format.sampleRate)
		for frame in 0..<Int(buffer.frameLength) {
			let time = Float(frame) / sampleRate
			let sample =
				Float(0.15) * sin(2 * Float.pi * 180 * time)
				+ Float(0.05) * sin(2 * Float.pi * 530 * time)
			channels[0][frame] = sample
			channels[1][frame] = sample
		}
	}

	private enum BenchmarkError: LocalizedError {
		case invalidArguments

		var errorDescription: String? {
			"Usage: swift run -c release opus-benchmark [--frames <positive integer>]"
		}
	}
}
