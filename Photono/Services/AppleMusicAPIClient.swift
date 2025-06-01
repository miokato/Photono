//
//  AppleMusicAPIClient.swift
//  Photono
//
//  Created by mio-kato on 2025/05/25.
//

import MusicKit

enum AppleMusicAPIClient {
    static func search(
        by name: String,
        with types: [any MusicCatalogSearchable.Type],
        limit: Int? = nil
    ) async throws -> MusicItemCollection<Song> {
        var request = MusicCatalogSearchRequest(
            term: name,
            types: types
        )
        request.limit = limit
        let response = try await request.response()
        return response.songs
    }
}
