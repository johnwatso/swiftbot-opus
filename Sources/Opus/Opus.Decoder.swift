import AVFoundation
import Copus

extension Opus {
	public class Decoder {
		let format: AVAudioFormat
		let decoder: OpaquePointer

		// TODO: throw an error if format is unsupported
		public init(format: AVAudioFormat, application _: Application = .audio) throws {
			if !format.isValidOpusPCMFormat {
				throw Opus.Error.badArgument
			}

			self.format = format

			// Initialize Opus decoder
			var error: Opus.Error = .ok
			decoder = opus_decoder_create(Int32(format.sampleRate), Int32(format.channelCount), &error.rawValue)
			if error != .ok {
				throw error
			}
		}

		deinit {
			opus_decoder_destroy(decoder)
		}

		public func reset() throws {
			let error = Opus.Error(opus_decoder_init(decoder, Int32(format.sampleRate), Int32(format.channelCount)))
			if error != .ok {
				throw error
			}
		}
	}
}

// MARK: Public decode methods

extension Opus.Decoder {
	public func decode(_ input: Data) throws -> AVAudioPCMBuffer {
		try decode(input, decodeFEC: false)
	}

	/// Decodes an Opus packet, optionally recovering the preceding lost packet
	/// from its in-band forward error correction data.
	public func decode(_ input: Data, decodeFEC: Bool) throws -> AVAudioPCMBuffer {
		guard !input.isEmpty else {
			throw Opus.Error.badArgument
		}
		return try input.withUnsafeBytes {
			let input = $0.bindMemory(to: UInt8.self)
			guard let baseAddress = input.baseAddress else {
				throw Opus.Error.badArgument
			}
			let sampleCount = opus_decoder_get_nb_samples(decoder, baseAddress, Int32($0.count))
			if sampleCount < 0 {
				throw Opus.Error(sampleCount)
			}
			guard sampleCount > 0 else {
				throw Opus.Error.invalidPacket
			}
			let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount))!
			try decode(input, to: output, decodeFEC: decodeFEC)
			return output
		}
	}

	public func decode(_ input: UnsafeBufferPointer<UInt8>, to output: AVAudioPCMBuffer) throws {
		try decode(input, to: output, decodeFEC: false)
	}

	/// Decodes an Opus packet into an existing PCM buffer.
	///
	/// When `decodeFEC` is `true`, the packet must follow a lost packet and the
	/// encoder must have produced in-band FEC data for the preceding frame.
	public func decode(_ input: UnsafeBufferPointer<UInt8>, to output: AVAudioPCMBuffer, decodeFEC: Bool) throws {
		guard input.baseAddress != nil, !input.isEmpty, output.format.isEqual(format) else {
			throw Opus.Error.badArgument
		}
		let decodedCount: Int
		switch output.format.commonFormat {
		case .pcmFormatInt16:
			guard let outputData = output.int16ChannelData else {
				throw Opus.Error.badArgument
			}
			let frameCapacity = output.frameCapacity
			let samples = Int(frameCapacity * format.channelCount)
			let outputSamples = UnsafeMutableBufferPointer(start: outputData[0], count: samples)
			decodedCount = try decode(input, to: outputSamples, frameCapacity: frameCapacity, decodeFEC: decodeFEC)
		case .pcmFormatFloat32:
			guard let outputData = output.floatChannelData else {
				throw Opus.Error.badArgument
			}
			let frameCapacity = output.frameCapacity
			let samples = Int(frameCapacity * format.channelCount)
			let outputSamples = UnsafeMutableBufferPointer(start: outputData[0], count: samples)
			decodedCount = try decode(input, to: outputSamples, frameCapacity: frameCapacity, decodeFEC: decodeFEC)
		default:
			throw Opus.Error.badArgument
		}
		if decodedCount < 0 {
			throw Opus.Error(decodedCount)
		}
		output.frameLength = AVAudioFrameCount(decodedCount)
	}

	/// Produces packet-loss concealment (PLC) audio for a missing Opus packet.
	///
	/// - Parameter frameCapacity: The expected number of samples per channel.
	///   This is normally the duration of the missing packet.
	public func decodeMissingPacket(frameCapacity: AVAudioFrameCount) throws -> AVAudioPCMBuffer {
		guard frameCapacity > 0 else {
			throw Opus.Error.badArgument
		}
		let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity)!
		try decodeMissingPacket(to: output)
		return output
	}

	/// Produces packet-loss concealment (PLC) audio in an existing PCM buffer.
	public func decodeMissingPacket(to output: AVAudioPCMBuffer) throws {
		guard output.format.isEqual(format) else {
			throw Opus.Error.badArgument
		}
		let decodedCount: Int
		switch output.format.commonFormat {
		case .pcmFormatInt16:
			guard let outputData = output.int16ChannelData else {
				throw Opus.Error.badArgument
			}
			let decoded = opus_decode(decoder, nil, 0, outputData[0], Int32(output.frameCapacity), 0)
			guard decoded >= 0 else {
				throw Opus.Error(decoded)
			}
			decodedCount = Int(decoded)
		case .pcmFormatFloat32:
			guard let outputData = output.floatChannelData else {
				throw Opus.Error.badArgument
			}
			let decoded = opus_decode_float(decoder, nil, 0, outputData[0], Int32(output.frameCapacity), 0)
			guard decoded >= 0 else {
				throw Opus.Error(decoded)
			}
			decodedCount = Int(decoded)
		default:
			throw Opus.Error.badArgument
		}
		output.frameLength = AVAudioFrameCount(decodedCount)
	}
}

// MARK: Private decode methods

extension Opus.Decoder {
	private func decode(
		_ input: UnsafeBufferPointer<UInt8>,
		to output: UnsafeMutableBufferPointer<Int16>,
		frameCapacity: AVAudioFrameCount,
		decodeFEC: Bool
	) throws -> Int {
		guard let outputAddress = output.baseAddress else {
			throw Opus.Error.badArgument
		}
		let decodedCount = opus_decode(
			decoder,
			input.baseAddress!,
			Int32(input.count),
			outputAddress,
			Int32(frameCapacity),
			decodeFEC ? 1 : 0
		)
		if decodedCount < 0 {
			throw Opus.Error(decodedCount)
		}
		return Int(decodedCount)
	}

	private func decode(
		_ input: UnsafeBufferPointer<UInt8>,
		to output: UnsafeMutableBufferPointer<Float32>,
		frameCapacity: AVAudioFrameCount,
		decodeFEC: Bool
	) throws -> Int {
		guard let outputAddress = output.baseAddress else {
			throw Opus.Error.badArgument
		}
		let decodedCount = opus_decode_float(
			decoder,
			input.baseAddress!,
			Int32(input.count),
			outputAddress,
			Int32(frameCapacity),
			decodeFEC ? 1 : 0
		)
		if decodedCount < 0 {
			throw Opus.Error(decodedCount)
		}
		return Int(decodedCount)
	}
}
