# Swift Opus

Type-safe [Swift](https://swift.org/) bindings for the [Opus audio codec](https://opus-codec.org/) on macOS 26+.

> [!IMPORTANT]
> **Swiftbot maintenance fork.** This fork is maintained solely for
> [Swiftbot](https://github.com/johnwatso/swiftbot). It is not intended to be a
> general-purpose replacement for the upstream project, and changes are made
> only as required to keep Swiftbot working. Its supported platform is macOS 26+
> only. For general Opus/Swift support,
> please use or contribute to [upstream](https://github.com/alta/swift-opus).

This package enables low-level Opus packet encoding and decoding to an `AVAudioPCMBuffer` suitable for playback via an `AVAudioEngine` and `AVAudioPlayerNode`. This was built for a now-defunct audio app for iOS and macOS, and runs reliably with multiple 48khz Opus audio channels over a typical 4G connection on modern iPhone devices.
## Installation

Use [Swift Package Manager](https://swift.org/package-manager/) to add this to your Xcode project or Swift package.

```swift
.package(url: "https://github.com/johnwatso/swiftbot-opus.git", from: "0.2.0")
```

The Opus C source is tracked as a [git submodule](Sources/Copus). When working
on this repository directly, clone it with `--recurse-submodules`.

## Usage

`Opus.Encoder.Configuration` exposes the standard Opus voice controls, including bitrate, VBR, complexity, DTX, in-band FEC, expected packet loss, signal type, and maximum bandwidth. For voice transports, enable FEC and pass `decodeFEC: true` when decoding the packet that follows a loss; use `decodeMissingPacket(frameCapacity:)` when no following packet is available.

Encode and decode a 20 ms, 48 kHz stereo PCM frame:

```swift
import AVFoundation
import Opus

let format = AVAudioFormat(
    opusPCMFormat: .float32,
    sampleRate: .opus48khz,
    channels: 2
)!
let encoder = try Opus.Encoder(format: format, application: .voip)
let decoder = try Opus.Decoder(format: format)

let pcm = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 960)!
pcm.frameLength = 960
var packet = Data(count: 1_275) // Maximum RFC 6716 Opus packet size.
try encoder.encode(pcm, to: &packet)

let decodedPCM = try decoder.decode(packet)

// When a packet is missing, generate 20 ms of packet-loss concealment audio.
let concealedPCM = try decoder.decodeMissingPacket(frameCapacity: 960)
```

`Encoder` and `Decoder` retain native codec state. Use one instance per audio
stream and call `reset()` before starting an unrelated stream. Input and output
buffers must use the exact PCM format supplied at initialization.

## Apple silicon benchmark

Use the release-mode benchmark to establish a local baseline before changing
libopus architecture-specific sources. It measures the same 48 kHz stereo,
20 ms voice profile used by SwiftBot and prints its architecture, per-frame
encode time, throughput, and real-time factor.

```sh
swift run -c release opus-benchmark
# Optionally choose a sample size (the default is 5,000 frames).
swift run -c release opus-benchmark --frames 10000
```

Treat the result as a comparison baseline for the same machine and build
configuration, rather than a universal performance target.

## License

See [LICENSE](LICENSE) for more information.
