import SwiftUI

/// Apple-Music-style audio-quality badge. The Synology stream endpoint
/// transcodes server-side to lossless WAV, so every track is Lossless.
/// Hovering reveals the concrete parameters in a tooltip card (a custom
/// overlay — `.help()` is unreliable when nested inside a Button).
struct QualityBadge: View {
    var compact: Bool = false
    var track: TrackDTO? = nil

    @State private var hovering = false

    private var sourceFormat: String? {
        guard let path = track?.path else { return nil }
        let ext = (path as NSString).pathExtension.uppercased()
        return ext.isEmpty ? nil : ext
    }

    private var lines: [String] {
        var l = ["Lossless"]
        let fmt = track?.codec?.uppercased() ?? sourceFormat
        if let fmt { l.append("Format: \(fmt)") }
        if let b = track?.bitrate, b > 0 {
            l.append("Bitrate: \(b / 1000) kbps")
        }
        if let sr = track?.sampleRate, sr > 0 {
            let khz = Double(sr) / 1000
            l.append(String(format: "Sample rate: %.1f kHz", khz))
        }
        if let ch = track?.channels, ch > 0 {
            let name = ch == 1 ? "Mono" : (ch == 2 ? "Stereo" : "\(ch)ch")
            l.append("Channels: \(ch) (\(name))")
        }
        if let d = track?.duration, d > 0 { l.append("Duration: \(fmtTime(d))") }
        l.append("Stream: WAV · PCM (server-transcoded)")
        return l
    }

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "waveform")
                .font(.system(size: compact ? 7 : 8, weight: .bold))
            if !compact {
                Text("LOSSLESS")
                    .font(.system(size: 8, weight: .bold))
                    .tracking(0.5)
            }
        }
        .foregroundStyle(Theme.accent)
        .padding(.horizontal, compact ? 4 : 5)
        .padding(.vertical, 2)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Theme.accent.opacity(0.55), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
        .overlay(alignment: .bottom) {
            if hovering {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(lines, id: \.self) { line in
                        Text(line)
                            .font(.system(size: 11))
                            .foregroundStyle(line == "Lossless" ? Theme.accent : .primary)
                            .fontWeight(line == "Lossless" ? .semibold : .regular)
                    }
                }
                .fixedSize()
                .padding(10)
                .background(.regularMaterial, in: .rect(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .stroke(.primary.opacity(0.1), lineWidth: 1))
                .shadow(color: .black.opacity(0.2), radius: 8, y: 3)
                .fixedSize()
                .offset(y: -28)
                .transition(.opacity)
                .zIndex(200)
            }
        }
        .animation(.easeInOut(duration: 0.12), value: hovering)
    }
}
