import SwiftUI

struct SearchView: View {
    @Environment(AppModel.self) private var app
    @State private var query = ""
    @State private var results: [TrackDTO]?
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LabelText("Search").padding(.bottom, 8)
                TextField("Type a song, artist, or album…", text: $query)
                    .textFieldStyle(.plain)
                    .font(Theme.serif(28, italic: true))
                    .foregroundStyle(Theme.ink)
                    .padding(.vertical, 12)
                    .overlay(Rectangle().frame(height: 1).foregroundStyle(Theme.ink),
                             alignment: .bottom)
                    .onSubmit(run)

                if busy { LabelText("Searching…").padding(.top, 32) }
                if let error {
                    Text(error).foregroundStyle(Theme.accent).padding(.top, 16)
                }
                if let results {
                    LabelText("\(results.count) results").padding(.vertical, 24)
                    TrackListView(tracks: results,
                                  currentTrackId: app.player.currentTrack?.id,
                                  onPick: pick)
                }
            }
            .frame(maxWidth: Theme.maxW, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.padX)
            .padding(.vertical, 32)
        }
        .scrollContentBackground(.hidden)
        .thinScrollbars()
    }

    private func run() {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        busy = true; error = nil
        Task {
            do { results = try await app.synology.search(query: q) }
            catch let e as BridgeHandlerError { error = e.message }
            catch { self.error = error.localizedDescription }
            busy = false
        }
    }

    private func pick(_ track: TrackDTO) {
        guard let list = results,
              let start = list.firstIndex(where: { $0.id == track.id }) else { return }
        Task { try? await app.engine.setQueue(tracks: list, startIndex: start) }
    }
}
