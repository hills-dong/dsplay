import Foundation

// SwiftUI list/grid identity. The DTOs are defined in DTOs.swift as the
// outgoing API shapes; these conformances let them drive ForEach directly.

extension TrackDTO: Identifiable, Equatable {
    static func == (lhs: TrackDTO, rhs: TrackDTO) -> Bool { lhs.id == rhs.id }
}

extension ArtistDTO: Identifiable {
    var id: String { name }
}

extension AlbumDTO: Identifiable {
    var id: String { "\(albumArtist)|\(name)" }
}

extension PlaylistDTO: Identifiable {}
