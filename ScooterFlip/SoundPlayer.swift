import AVFoundation

/// Короткие звуковые эффекты игры. Файлы лежат в бандле (ScooterFlip/Sounds).
@MainActor
final class SoundPlayer {
    static let shared = SoundPlayer()

    enum Sound: String {
        case caught = "snd-caught"        // СБ поймала
        case deckOpen = "snd-deck-open"   // дека открылась
        case deckMiss = "snd-deck-miss"   // промах при вскрытии деки
        case flashFail = "snd-flash-fail" // прошивка не удалась
    }

    private var players: [String: AVAudioPlayer] = [:]
    private var configured = false

    private func configure() {
        guard !configured else { return }
        configured = true
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    func play(_ sound: Sound) {
        configure()
        guard let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") else {
            return
        }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { return }
        player.prepareToPlay()
        player.play()
        // Держим плеер живым, иначе звук обрывается.
        players[sound.rawValue] = player
    }
}
