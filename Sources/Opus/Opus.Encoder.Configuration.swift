import AVFoundation
import Copus
import OpusShim

extension Opus.Encoder {
	public enum Signal: Int32, Sendable {
		case automatic = -1_000
		case voice = 3_001
		case music = 3_002
	}

	public enum Bandwidth: Int32, Sendable {
		case narrowband = 1_101
		case mediumband = 1_102
		case wideband = 1_103
		case superwideband = 1_104
		case fullband = 1_105
	}

	public struct Configuration: Sendable {
		public var bitrate: Int32?
		public var complexity: Int?
		public var usesVariableBitrate: Bool?
		public var usesConstrainedVariableBitrate: Bool?
		public var usesDiscontinuousTransmission: Bool?
		public var usesInbandFEC: Bool?
		public var expectedPacketLossPercentage: Int?
		public var signal: Signal?
		public var maximumBandwidth: Bandwidth?

		public init(
			bitrate: Int32? = nil,
			complexity: Int? = nil,
			usesVariableBitrate: Bool? = nil,
			usesConstrainedVariableBitrate: Bool? = nil,
			usesDiscontinuousTransmission: Bool? = nil,
			usesInbandFEC: Bool? = nil,
			expectedPacketLossPercentage: Int? = nil,
			signal: Signal? = nil,
			maximumBandwidth: Bandwidth? = nil
		) {
			self.bitrate = bitrate
			self.complexity = complexity
			self.usesVariableBitrate = usesVariableBitrate
			self.usesConstrainedVariableBitrate = usesConstrainedVariableBitrate
			self.usesDiscontinuousTransmission = usesDiscontinuousTransmission
			self.usesInbandFEC = usesInbandFEC
			self.expectedPacketLossPercentage = expectedPacketLossPercentage
			self.signal = signal
			self.maximumBandwidth = maximumBandwidth
		}
	}

	public func configure(_ configuration: Configuration) throws {
		if let bitrate = configuration.bitrate { try check(opus_swift_encoder_set_bitrate(encoder, bitrate)) }
		if let complexity = configuration.complexity {
			guard (0...10).contains(complexity) else { throw Opus.Error.badArgument }
			try check(opus_swift_encoder_set_complexity(encoder, Int32(complexity)))
		}
		if let value = configuration.usesVariableBitrate { try check(opus_swift_encoder_set_vbr(encoder, value ? 1 : 0)) }
		if let value = configuration.usesConstrainedVariableBitrate { try check(opus_swift_encoder_set_constrained_vbr(encoder, value ? 1 : 0)) }
		if let value = configuration.usesDiscontinuousTransmission { try check(opus_swift_encoder_set_dtx(encoder, value ? 1 : 0)) }
		if let value = configuration.usesInbandFEC { try check(opus_swift_encoder_set_inband_fec(encoder, value ? 1 : 0)) }
		if let value = configuration.expectedPacketLossPercentage {
			guard (0...100).contains(value) else { throw Opus.Error.badArgument }
			try check(opus_swift_encoder_set_packet_loss_percentage(encoder, Int32(value)))
		}
		if let value = configuration.signal { try check(opus_swift_encoder_set_signal(encoder, value.rawValue)) }
		if let value = configuration.maximumBandwidth { try check(opus_swift_encoder_set_max_bandwidth(encoder, value.rawValue)) }
	}

	public var lookahead: AVAudioFrameCount {
		var samples: Int32 = 0
		return opus_swift_encoder_get_lookahead(encoder, &samples) == OPUS_OK ? AVAudioFrameCount(samples) : 0
	}

	private func check(_ result: Int32) throws {
		guard result == OPUS_OK else { throw Opus.Error(result) }
	}
}
