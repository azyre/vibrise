import Foundation

struct Song: Identifiable, Equatable, Codable {
    let id: String
    let title: String
    let artist: String
    let artworkURL: URL?
    let audioURL: URL?
}

extension Song {
    static let mockMorningLight = Song(
        id: "mock-morning-light",
        title: "Morning Light",
        artist: "Daydrift",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1470071459604-3b5ec3a7fe05?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let gentleAwakening = Song(
        id: "gentle-awakening",
        title: "Gentle Awakening",
        artist: "Soft Parade",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let rainyThoughts = Song(
        id: "rainy-thoughts",
        title: "Rainy Thoughts",
        artist: "Cloud Harbor",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1501908734255-16579c18c25f?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let electricSunrise = Song(
        id: "electric-sunrise",
        title: "Electric Sunrise",
        artist: "Signal Bloom",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let forestWalk = Song(
        id: "forest-walk",
        title: "Forest Walk",
        artist: "Moss Avenue",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let winterSilence = Song(
        id: "winter-silence",
        title: "Winter Silence",
        artist: "North Static",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let dawnSignal = Song(
        id: "dawn-signal",
        title: "Dawn Signal",
        artist: "Halo District",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let amberSkies = Song(
        id: "amber-skies",
        title: "Amber Skies",
        artist: "Sora Lane",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let quietHarbor = Song(
        id: "quiet-harbor",
        title: "Quiet Harbor",
        artist: "Blue Static",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1500375592092-40eb2168fd21?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let silverMornings = Song(
        id: "silver-mornings",
        title: "Silver Mornings",
        artist: "Velvet Current",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let moonlitSteps = Song(
        id: "moonlit-steps",
        title: "Moonlit Steps",
        artist: "Night Avenue",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1500534623283-312aade485b7?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let coastlines = Song(
        id: "coastlines",
        title: "Coastlines",
        artist: "Seabright",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1501594907352-04cda38ebc29?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let slowComet = Song(
        id: "slow-comet",
        title: "Slow Comet",
        artist: "Neon Vale",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1504384308090-c894fdcc538d?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let paleBloom = Song(
        id: "pale-bloom",
        title: "Pale Bloom",
        artist: "Iris Harbor",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1490750967868-88aa4486c946?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let auroraLetters = Song(
        id: "aurora-letters",
        title: "Aurora Letters",
        artist: "Paper North",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1493246507139-91e8fad9978e?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let blueNoon = Song(
        id: "blue-noon",
        title: "Blue Noon",
        artist: "Glass Harbor",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1506744038136-46273834b3fb?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let softTransit = Song(
        id: "soft-transit",
        title: "Soft Transit",
        artist: "Metro Pine",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1494526585095-c41746248156?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let lilacHours = Song(
        id: "lilac-hours",
        title: "Lilac Hours",
        artist: "Violet Coast",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1465146344425-f00d5f5c8f07?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let stillWater = Song(
        id: "still-water",
        title: "Still Water",
        artist: "North Pier",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let openWindows = Song(
        id: "open-windows",
        title: "Open Windows",
        artist: "Golden Room",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1499084732479-de2c02d45fc4?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let softAtlas = Song(
        id: "soft-atlas",
        title: "Soft Atlas",
        artist: "Maple Signal",
        artworkURL: URL(string: "https://images.unsplash.com/photo-1504208434309-cb69f4fe52b0?w=400&h=400&fit=crop"),
        audioURL: nil
    )

    static let previewFavorites: [Song] = [
        .mockMorningLight,
        .gentleAwakening,
        .rainyThoughts,
        .electricSunrise,
        .forestWalk,
        .winterSilence,
        .dawnSignal,
        .amberSkies,
        .quietHarbor,
        .silverMornings,
        .moonlitSteps,
        .coastlines,
        .slowComet,
        .paleBloom,
        .auroraLetters,
        .blueNoon
    ]
}
