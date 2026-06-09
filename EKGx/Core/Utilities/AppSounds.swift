import AVFoundation

// Preloads TapSound once at first use and plays it on every button press.
// Using .ambient + .mixWithOthers so the click never interrupts music,
// calls, or the ECG beep — it simply layers on top.
final class AppSounds {

    static let shared = AppSounds()

    private var tapPlayer: AVAudioPlayer?

    private init() {
        guard let asset = NSDataAsset(name: "TapSound") else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient, mode: .default, options: [.mixWithOthers]
            )
            tapPlayer = try AVAudioPlayer(data: asset.data)
            tapPlayer?.numberOfLoops = 0
            tapPlayer?.volume = 0.03
            tapPlayer?.prepareToPlay()
        } catch {
            print("TapSound not found")
        }
    }

    func tap() {
        guard let p = tapPlayer else { return }
        if p.isPlaying { p.stop() }
        p.currentTime = 0
        p.play()
    }
}
