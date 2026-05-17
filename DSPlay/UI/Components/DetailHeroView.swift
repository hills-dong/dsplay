import SwiftUI

/// Apple-Music-style hero: square art, title, accent subtitle, meta line,
/// and Play / Shuffle pill buttons.
struct DetailHeroView: View {
    let synology: SynologyClient
    let representativeSongId: String?
    var eyebrow: String? = nil          // artist / "Compilation" — shown in accent
    let title: String
    var meta: String? = nil             // "12 songs"
    let onPlay: () -> Void
    let onShuffle: () -> Void

    var body: some View {
        #if os(iOS)
        // Phone: vertical hero (Apple Music) — centered cover, title, artist
        // and meta; full-width Play / Shuffle pills.
        VStack(spacing: 12) {
            CoverImage(synology: synology, songId: representativeSongId, cornerRadius: 10)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 260)
                .frame(maxWidth: .infinity, alignment: .center)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
            info(centered: true)
        }
        .padding(.bottom, 24)
        #else
        HStack(alignment: .bottom, spacing: 24) {
            CoverImage(synology: synology, songId: representativeSongId, cornerRadius: 8)
                .frame(width: 200, height: 200)
                .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
            info(centered: false)
            Spacer(minLength: 0)
        }
        .padding(.bottom, 28)
        #endif
    }

    private func info(centered: Bool) -> some View {
        VStack(alignment: centered ? .center : .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(centered ? .center : .leading)
                .fixedSize(horizontal: false, vertical: true)
            if let eyebrow {
                Text(eyebrow)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .multilineTextAlignment(centered ? .center : .leading)
            }
            if let meta {
                Text(meta)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }

            HStack(spacing: 12) {
                pill("Play", "play.fill", action: onPlay)
                pill("Shuffle", "shuffle", action: onShuffle)
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, alignment: centered ? .center : .leading)
    }

    private func pill(_ label: String, _ symbol: String,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 12, weight: .semibold))
                Text(label).font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize()
            }
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 22)
            .padding(.vertical, 12)
            #if os(iOS)
            .frame(maxWidth: .infinity)
            #else
            .frame(minWidth: 110)
            #endif
            .background(Color.gray.opacity(0.16), in: .capsule)
        }
        .buttonStyle(.plain)
    }
}
