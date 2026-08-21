import AVFoundation
import Copus

extension Opus {
	public class Encoder {
		let format: AVAudioFormat
		let application: Application
		let encoder: OpaquePointer

		// TODO: throw an error if format is unsupported
		public init(format: AVAudioFormat, application: Application = .audio) throws {
			if !format.isValidOpusPCMFormat {
				throw Opus.Error.badArgument
			}

			self.format = format
			self.application = application

			// Initialize Opus encoder
			var error: Opus.Error = .ok
			encoder = opus_encoder_create(Int32(format.sampleRate), Int32(format.channelCount), application.rawValue, &error.rawValue)
			if error != .ok {
				throw error
			}
		}

		deinit {
			opus_encoder_destroy(encoder)
		}

		public func reset() throws {
			let error = Opus.Error(opus_encoder_init(encoder, Int32(format.sampleRate), Int32(format.channelCount), application.rawValue))
			if error != .ok {
				throw error
			}
		}
	}
}

// MARK: Public encode methods

extension Opus.Encoder {
	public func encode(_ input: AVAudioPCMBuffer, to output: inout Data) throws -> Int {
		let encodedCount = try output.withUnsafeMutableBytes {
			try encode(input, to: $0)
		}
		output.count = encodedCount
		return encodedCount
	}

	public func encode(_ input: AVAudioPCMBuffer, to output: inout [UInt8]) throws -> Int {
		try output.withUnsafeMutableBufferPointer {
			try encode(input, to: $0)
		}
	}

	public func encode(_ input: AVAudioPCMBuffer, to output: UnsafeMutableRawBufferPointer) throws -> Int {
		guard !output.isEmpty, let baseAddress = output.baseAddress else {
			throw Opus.Error.bufferTooSmall
		}
		let output = UnsafeMutableBufferPointer(start: baseAddress.bindMemory(to: UInt8.self, capacity: output.count), count: output.count)
		return try encode(input, to: output)
	}

	public func encode(_ input: AVAudioPCMBuffer, to output: UnsafeMutableBufferPointer<UInt8>) throws -> Int {
		guard input.format.isEqual(format) else {
			throw Opus.Error.badArgument
		}
		switch format.commonFormat {
		case .pcmFormatInt16:
			guard let inputData = input.int16ChannelData else {
				throw Opus.Error.badArgument
			}
			let input = UnsafeBufferPointer(start: inputData[0], count: Int(input.frameLength * format.channelCount))
			return try encode(input, to: output)
		case .pcmFormatFloat32:
			guard let inputData = input.floatChannelData else {
				throw Opus.Error.badArgument
			}
			let input = UnsafeBufferPointer(start: inputData[0], count: Int(input.frameLength * format.channelCount))
			return try encode(input, to: output)
		default:
			throw Opus.Error.badArgument
		}
	}
}

// MARK: private encode methods

extension Opus.Encoder {
	private func encode(_ input: UnsafeBufferPointer<Int16>, to output: UnsafeMutableBufferPointer<UInt8>) throws -> Int {
		let encodedSize = opus_encode(
			encoder,
			input.baseAddress!,
			Int32(input.count) / Int32(format.channelCount),
			output.baseAddress!,
			Int32(output.count)
		)
		if encodedSize < 0 {
			throw Opus.Error(encodedSize)
		}
		return Int(encodedSize)
	}

	private func encode(_ input: UnsafeBufferPointer<Float32>, to output: UnsafeMutableBufferPointer<UInt8>) throws -> Int {
		let encodedSize = opus_encode_float(
			encoder,
			input.baseAddress!,
			Int32(input.count) / Int32(format.channelCount),
			output.baseAddress!,
			Int32(output.count)
		)
		if encodedSize < 0 {
			throw Opus.Error(encodedSize)
		}
		return Int(encodedSize)
	}
}
