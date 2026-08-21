import AVFoundation
@_exported import Copus
import CoreAudio

public enum Opus: CaseIterable {}

extension Opus {
	/// The largest valid encoded Opus packet, in bytes.
	///
	/// This is the maximum payload size defined by the Opus specification. RTP
	/// transports may impose a smaller limit.
	public static let maximumPacketSize = 1_275
}
