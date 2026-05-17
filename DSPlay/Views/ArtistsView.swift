import SwiftUI

struct ArtistsView: View {
    @Environment(AppModel.self) private var app
    @State private var artists: [ArtistDTO]?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                LabelText("Artists" + (artists.map { " · \($0.count)" } ?? "…"))
                    .padding(.bottom, 24)
                ForEach(artists ?? []) { a in
                    NavigationLink(value: Route.artistDetail(name: a.name)) {
                        Text(a.name)
                            .font(Theme.serif(18))
                            .foregroundStyle(Theme.ink)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Divider().overlay(Color.black.opacity(0.08))
                }
            }
            .frame(maxWidth: Theme.maxW, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.padX)
            .padding(.vertical, 32)
        }
        .scrollContentBackground(.hidden)
        .thinScrollbars()
        .task {
            if artists == nil { artists = try? await app.synology.listArtists() }
        }
    }
}
