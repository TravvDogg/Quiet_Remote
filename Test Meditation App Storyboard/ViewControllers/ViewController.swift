//
//  ViewController.swift
//  Test Meditation App Storyboard
//
//  Created by Travis Lizio on 25/3/2024. (assisted by ChatGPT and Claude AI)
//

import UIKit
import AVFoundation
import ObjectiveC


// MARK: - Utility Methods
class ViewController: UIViewController {
    static func shared() -> ViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "MainViewController") as! ViewController
    }
    
    // MARK: - Outlets
    
    @IBOutlet weak var headingLabel: UILabel!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var tabControl: UISegmentedControl!
    @IBOutlet weak var uiEllipsesButton: UIButton!
    
    @IBOutlet weak var experienceSelectButton: UIButton!
    
    // MARK: - Actions
    @IBAction func uiEllipsesButtonPressed(_ sender: UIButton) {
        updateEllipsesButtonUI()
        sender.showsMenuAsPrimaryAction = true
    }
    
    let muteOffIcon = UIImage(systemName: "speaker.wave.2")
    let muteOnIcon = UIImage(systemName: "speaker.slash")
    
    func updateEllipsesButtonUI() {
        if isMuted {
            uiEllipsesButton.menu = UIMenu(
                title: "",
                children: [
                    UIAction (
                        title: "Unmute Menu Music",
                        image: muteOffIcon,
                        handler: { _ in self.toggleMute()}
                    )
                ]
            )
        } else {
            uiEllipsesButton.menu = UIMenu(
                title: "",
                children: [
                    UIAction (
                    title: "Mute Menu Music",
                    image: muteOnIcon,
                    handler: { _ in self.toggleMute()}
                    )
                ]
            )
        }
        
        ColorManager.shared.muteUI = uiEllipsesButton.menu?.children
        
    }
    
    // MARK: - Properties
    var currentHeadingText: String = ""
    var isScreenBeingHeld = false
    var titleAnimator: UIViewPropertyAnimator?
    var titleBackAnimator: UIViewPropertyAnimator?
    var comparison: (Double, Double) -> Bool = (>)
    var audioPlayers: [AVAudioPlayer?] = [nil, nil, nil, nil]
    var isMuted = false
    var muteStateKey = "isMuted"
    var selectedSegmentIndex = 0
    var currentPlayerIndex: Int = -1
    var ExperiencePlayback = false
    var selectedGenre: String?
    
        
    // MARK: - UI Configuration
    func configureUI() {
        if #available(iOS 13.0, *) {
            // Force dark mode to fit the app's theme
            overrideUserInterfaceStyle = .dark
        }
    }
        
    // MARK: - UI Update Methods
    @objc func segmentedControlValueChanged(_ sender: UISegmentedControl) {
    
        // This method is called when the value of the segmented control changes
        // It updates the UI elements based on the selected segment
        selectedSegmentIndex = sender.selectedSegmentIndex
        
        guard selectedSegmentIndex >= 0 && selectedSegmentIndex < audioPlayers.count else {
            print("Index out of bounds: \(selectedSegmentIndex)")
            return
        }
        
        switch selectedSegmentIndex {
        case 0:
            //Ground
            ColorManager.shared.backgroundColor = UIColor(named: ColorAssets.GroundPrimary)
            ColorManager.shared.tintColor = UIColor(named: ColorAssets.GroundTint)
            ColorManager.shared.header = "Stress and Anxiety Relief"
            selectedGenre = "Ground"
        case 1:
            //Sunrise
            ColorManager.shared.backgroundColor = UIColor(named: ColorAssets.SunrisePrimary)
            ColorManager.shared.tintColor = UIColor(named: ColorAssets.SunriseTint)
            ColorManager.shared.header = "Energize and Inspire"
            selectedGenre = "Ground" // Just for now
        case 2:
            //Grass
            ColorManager.shared.backgroundColor = UIColor(named: ColorAssets.GrassPrimary)
            ColorManager.shared.tintColor = UIColor(named: ColorAssets.GrassTint)
            ColorManager.shared.header = "Tranquility and Focus"
            selectedGenre = "Ground" // Just for now
        case 3:
            //Moon
            ColorManager.shared.backgroundColor = UIColor(named: ColorAssets.MoonPrimary)
            ColorManager.shared.tintColor = UIColor(named: ColorAssets.MoonTint)
            ColorManager.shared.header = "Sleep and Relaxation"
            selectedGenre = "Nighttime"
        default:
            return // Exit method if selected index is out of bounds
        }
        headingLabel.text = ColorManager.shared.header
        
        
        // Disable crossfade if the menu is muted
        if isMuted {
            if currentPlayerIndex >= 0 && currentPlayerIndex < audioPlayers.count {
                // If muted, stop the current audio player
                if let currentPlayer = audioPlayers[currentPlayerIndex] {
                    currentPlayer.stop()
                }
            }
        } else {
            // Crossfade between tracks only if not muted and the selected segment is different from the current one
            if selectedSegmentIndex != currentPlayerIndex {
                if let currentPlayer = audioPlayers[currentPlayerIndex],
                   let nextPlayer = audioPlayers[selectedSegmentIndex] {
                    crossfade(from: currentPlayer, to: nextPlayer)
                    currentPlayerIndex = selectedSegmentIndex // Update currentPlayerIndex after crossfade
                }
            }
        }
            
            // Update UI elements with animation
            UIView.animate(withDuration: 0.5, delay: 0, options: [.allowUserInteraction], animations: {
                self.backgroundView.backgroundColor = ColorManager.shared.backgroundColor
                self.tabControl.selectedSegmentTintColor = ColorManager.shared.tintColor
            }, completion: nil)
        }
        
    // MARK: - Gesture Handling
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        // This method handles the pan gesture for swiping between segments
        
        // Static variable to accumulate translation distance
        struct Accumulated {
            static var distance: CGFloat = 0.0
        }
        
        let translation = gesture.translation(in: view)
        // Accumulate the horizontal translation
        Accumulated.distance += translation.x
        
        let totalWidth = view.bounds.width
        // Define a threshold for changing segments based on the total width and the number of segments
        let threshold = totalWidth / CGFloat(tabControl.numberOfSegments) / 4 // Adjust this divisor to control sensitivity. Higher value will be more sensitive
        
        // Reset the gesture's translation so the accumulation doesn't include previously handled translations
        gesture.setTranslation(CGPoint.zero, in: view)
        
        switch gesture.state {
        case .began:
            // Start animating the title upwards
            titleAnimator?.stopAnimation(true)
            titleAnimator = UIViewPropertyAnimator(duration: 0.5, curve: .easeInOut) {
                self.headingLabel.transform = CGAffineTransform(translationX: 0, y: -50).scaledBy(x: 0.8, y: 0.8)
                self.headingLabel.alpha = 0.5
            }
            titleAnimator?.startAnimation()
        case .changed:
            if abs(Accumulated.distance) > threshold {
                let previousIndex = tabControl.selectedSegmentIndex
                if Accumulated.distance < 0 { // Swiping Right
                    if tabControl.selectedSegmentIndex > 0 {
                        tabControl.selectedSegmentIndex -= 1
                        triggerHapticFeedback()
                    }
                } else { // Swiping Left
                    if tabControl.selectedSegmentIndex < tabControl.numberOfSegments - 1 {
                        tabControl.selectedSegmentIndex += 1
                        triggerHapticFeedback()
                    }
                }
                
                if tabControl.selectedSegmentIndex != previousIndex {
                    // Reset the accumulated distance after changing a segment
                    Accumulated.distance = 0
                    // Trigger the change action to the segmented control
                    segmentedControlValueChanged(tabControl)
                } else {
                    // Reset the accumulated distance even if the segment didn't change
                    Accumulated.distance = 0
                }
                
                //print("Selected Segment Index: \(tabControl.selectedSegmentIndex)")
            }
        case .ended, .cancelled:
            // Animate the title back to its original position
            titleAnimator?.stopAnimation(true)
            titleBackAnimator?.stopAnimation(true)
            titleBackAnimator = UIViewPropertyAnimator(duration: 0.6, dampingRatio: 0.6) {
                self.headingLabel.transform = .identity
                self.headingLabel.alpha = 1.0
            }
            titleBackAnimator?.startAnimation()
            Accumulated.distance = 0 // Reset the accumulated distance
        default:
            break
        }
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isMuted = UserDefaults.standard.bool(forKey: muteStateKey)
        do {
            try AVAudioSession.sharedInstance().setActive(isMuted ? false : true)
        } catch {
            print("Audio session activation failed: \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        isMuted = UserDefaults.standard.bool(forKey: muteStateKey)

        configureUI()
        
        beginPlayback()
        
        loadAudioFiles()
        if !isMuted {
            if let firstPlayer = audioPlayers.first {
                firstPlayer?.play()
                currentPlayerIndex = 0 // Set the current index to the first screen
            }
        } else {
            // If muted, stop all audio players
            for player in audioPlayers {
                player?.stop()
            }
        }
        
        //Set default value to Ground
        ColorManager.shared.backgroundColor = UIColor(named: ColorAssets.GroundPrimary)
        ColorManager.shared.tintColor = UIColor(named: ColorAssets.GroundTint)
        ColorManager.shared.header = "Stress and Anxiety Relief"
        selectedGenre = "Ground"
        
        updateEllipsesButtonUI()
        
        tabControl.addTarget(self, action: #selector(segmentedControlValueChanged(_:)), for: .valueChanged)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGesture)
    }
        
    // MARK: - Utility and Helper Functions
    func triggerHapticFeedback() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        feedbackGenerator.impactOccurred()
    }
    
    func loadAudioFiles() {
        // This method loads the audio files from the bundle
        
        let audioFileNames = [
            "Meditation App Menu Music - Ground.m4a",
            "Meditation App Menu Music - Grass.m4a",
            "Meditation App Menu - Autumn Morning.m4a",
            "Meditation App Menu Music - Nighttime.m4a"
        ]
        for (index, fileName) in audioFileNames.enumerated() {
            guard let url = Bundle.main.url(forResource: fileName, withExtension: nil, subdirectory:"/Media/Audio") else {
                print("Could not find file: \(fileName)")
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1 // Loop indefinitely
                audioPlayers[index] = player
                //print("Loaded \(fileName) successfully")
            } catch {
                print("Could not load file: \(fileName), error: \(error)")
            }
        }
        for player in audioPlayers where player != nil {
            player?.prepareToPlay()
        }
    }
    
    func fadeVolume(player: AVAudioPlayer, toVolume endVolume: Float, duration: TimeInterval, completion: @escaping () -> Void) {
        // This method fades the volume of an audio player to a specified end volume over a given duration
        
        let startVolume = player.volume
        let volumeChangePerSecond = (endVolume - startVolume) / Float(duration)
        
        var timeElapsed: TimeInterval = 0
        
        player.volumeFadeTimer?.invalidate() // Invalidate any existing timer
        player.volumeFadeTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            if timeElapsed < duration {
                player.volume += volumeChangePerSecond * 0.1
                timeElapsed += 0.1
            } else {
                timer.invalidate()
                player.volume = endVolume
                completion()
            }
        }
    }

    func crossfade(from currentPlayer: AVAudioPlayer?, to nextPlayer: AVAudioPlayer?, initialDuration: TimeInterval = 0.5) {
        guard let currentPlayer = currentPlayer, let nextPlayer = nextPlayer else { return }

        let currentTime = currentPlayer.currentTime
        nextPlayer.currentTime = currentTime

        // Calculate remaining duration based on current volume if already fading
        //let currentVolume = currentPlayer.volume
        //let nextVolume = nextPlayer.volume
        //let adjustedDuration = initialDuration * Double(1 - nextVolume)

        // Start fade-out and fade-in with adjusted durations
        /* fadeVolume(player: currentPlayer, toVolume: 0, duration: adjustedDuration) {
            currentPlayer.stop() // Ensure player is stopped after fade-out
        } */
        
        currentPlayer.stop()
        
        nextPlayer.play() // Ensure next player starts playing from the same timecode
        /* fadeVolume(player: nextPlayer, toVolume: 1.0, duration: adjustedDuration, completion: {
            // Completion handler for fade-in
        }) */
    }

    func resetAudioPlayers(except index: Int) {
        // This method resets any ongoing audio operations for all players except the one at the specified index
        
        for (i, player) in audioPlayers.enumerated() {
            if i != index, let player = player {
                player.stop()
                player.currentTime = 0
                player.volumeFadeTimer?.invalidate()
                player.volumeFadeTimer = nil
            }
        }
    }
    
    public func stopAudioPlayers() {
        for player in audioPlayers {
            player?.stop()
        }
    }
    
    func beginPlayback() {
        do {
            if !isMuted {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
            } else {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
                try AVAudioSession.sharedInstance().setActive(false)
            }
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func toggleMute() {
        isMuted.toggle()
        

        UserDefaults.standard.set(isMuted, forKey: muteStateKey)
        
        if isMuted {
            // Fade out the audio
            if let currentPlayer = audioPlayers[currentPlayerIndex] {
                fadeVolume(player: currentPlayer, toVolume: 0.0, duration: 0.5) {
                    currentPlayer.stop()
                }
            }
        } else {
            // Play the currently selected audio track
            currentPlayerIndex = selectedSegmentIndex
            // Fade in the audio
            if let currentPlayer = audioPlayers[currentPlayerIndex] {
                currentPlayer.volume = 0.0
                currentPlayer.play()
                fadeVolume(player: currentPlayer, toVolume: 1.0, duration: 0.5, completion: {})
                currentPlayerIndex = selectedSegmentIndex
            }
        }
        
        beginPlayback()
        updateEllipsesButtonUI()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            if segue.identifier == "OpenExperienceSelect" {
                if let viewControllerExperienceSelect = segue.destination as? ViewControllerExperienceSelect {
                    viewControllerExperienceSelect.mainViewController = self
                    viewControllerExperienceSelect.selectedGenre = selectedGenre
                    viewControllerExperienceSelect.selectedExperienceName = "Experience Demo"
                }
            }
        }
    
}

// MARK: - Extensions

extension AVAudioPlayer {
    private struct AssociatedKeys {
        static var volumeFadeTimerKey = "volumeFadeTimerKey"
    }

    var volumeFadeTimer: Timer? {
        get {
            return objc_getAssociatedObject(self, AssociatedKeys.volumeFadeTimerKey) as? Timer // Warn - Forming 'UnsafeRawPointer' to a variable of type 'Optional<Timer>'; this is likely incorrect because 'Optional<Timer>' may contain an object reference.
        }
        set(timer) {
            if let timer = timer {
                objc_setAssociatedObject(self, AssociatedKeys.volumeFadeTimerKey, timer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) // Warn - Forming 'UnsafeRawPointer' to a variable of type 'Optional<Timer>'; this is likely incorrect because 'Optional<Timer>' may contain an object reference.
            }
        }
    }
}

class ColorManager {
    static let shared = ColorManager()
    var backgroundColor: UIColor?
    var tintColor: UIColor?
    var header: String?
    var muteUI: [UIMenuElement]?
    
    private init() {}
}
