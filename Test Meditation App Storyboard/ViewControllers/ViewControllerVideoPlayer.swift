//
//  ViewControllerVideoPlayer.swift
//  Test Meditation App Storyboard
//
//  Created by Travis Lizio on 14/4/2024.
//

import UIKit
import AVFoundation

class ViewControllerVideoPlayer: UIViewController {

    // MARK: - Outlets
    
    @IBOutlet weak var balanceSlider: UISlider!
    @IBOutlet weak var experienceProgress: UIProgressView!
    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var playbackToggle: UIButton!
    var isPlaying = false
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    // MARK: - Actions
    // Audio volume customisation
    
    // Parameters
    var ambientMusicVolumeDefault: Float = 0.35
    var voiceOverVolumeDefault: Float = 1.0
    
    var ambientMusicVolumeMax: Float = 0.75
    var ambientMusicVolumeMin: Float = 0.0
    var voiceOverVolumeMax: Float = 1.0
    var voiceOverVolumeMin: Float = 0.0
    
    var lastSnappedValue: Float = 0.0
    let feedbackGenerator = UIImpactFeedbackGenerator(style: .light)
    // Update values
    @IBAction func balanceSlider(_ sender: UISlider) {
        let roundedValue = roundf(balanceSlider.value) // Slider value snapping
        balanceSlider.value = roundedValue
        if roundedValue != lastSnappedValue {
            var sliderDecimalValue = balanceSlider.value / balanceSlider.maximumValue
            calculateVolume(value: 1 - sliderDecimalValue)
            
            feedbackGenerator.impactOccurred()
            lastSnappedValue = roundedValue
        }
    }
    

    @IBAction func togglePlayPause(_ sender: UIButton) {
        if isPlaying {
            pauseAudio()
        } else {
            playAudio()
        }
        feedbackGenerator.impactOccurred()
    }
    
    @IBAction func fastForward(_ sender: UIButton) {
        jumpToTime(10)
    }
    
    @IBAction func rewind(_ sender: UIButton) {
        jumpToTime(-10)
    }
    
    // MARK: - Properties
    
    var experienceData: Experience?
    var genre: String?
    var experienceName: String?
    
    
    // Audio Engine
    var ambientMusicPlayer: AVAudioPlayer!
    var voiceOverPlayer: AVAudioPlayer!
    
    var progressTimer: Timer?
    var longerDuration: Double = 0.0
    
    
    // MARK: - UI Configuration

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
//        configureAudioEngine()
        if let backgroundColor = ColorManager.shared.backgroundColor {
            self.backgroundView.backgroundColor = backgroundColor
            //TODO: - set background color to be seperate from the main genre's colors.
        }
        
        guard let experienceData = experienceData else {
            print("Experience data is unavailable.")
            return
        }
        setupAudioPlayers()
        
        playAudio() // error here
        
        calculateVolume(value: 0.5)
    }

    func configureUI() {
        if #available(iOS 13.0, *) {
            // Force dark mode to fit the app's theme
            overrideUserInterfaceStyle = .dark
        }
    }

    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
                        
            if let viewControllerExperienceSelect = presentingViewController as? ViewControllerExperienceSelect,
               let mainViewController = viewControllerExperienceSelect.mainViewController {
                mainViewController.stopAudioPlayers()
            } else {
                print("Presenting view controller is not an instance of OverlayViewController or mainViewController is nil")
            }
        }
    override func viewWillDisappear(_ animated: Bool) {
        stopAudio()
    }
    
    // MARK: - Utility and Helper Functions
    
    func setupAudioPlayers() {
        guard let experienceData = experienceData,
        let genre = genre,
        let experienceName = experienceName else {
            print("Experience data is unavailable")
            return
        }
        
        let ambientMusicFileName = experienceData.ambientMusicFile
        let voiceOverFileName = experienceData.voiceOverFile
        
        guard let ambientMusicUrl = Bundle.main.url(forResource: "Media/Experiences/\(genre)/\(experienceName)/\(ambientMusicFileName)", withExtension: "mp3"),
            let voiceOverUrl = Bundle.main.url(forResource:"Media/Experiences/\(genre)/\(experienceName)/\(voiceOverFileName)", withExtension: "mp3") else {
            print("Failed to load audio files.")
            return
        }
        
        do {
            ambientMusicPlayer = try AVAudioPlayer(contentsOf: ambientMusicUrl)
            voiceOverPlayer = try AVAudioPlayer(contentsOf: voiceOverUrl)
        } catch {
            print("Error loading audio files: \(error.localizedDescription)")
        }
        
        ambientMusicPlayer?.volume = ambientMusicVolumeDefault
        voiceOverPlayer?.volume = voiceOverVolumeDefault
    }
    
    func getAudioFileDuration(_ audioFile: AVAudioFile) -> Double {
        return Double(audioFile.length) / audioFile.fileFormat.sampleRate
    }
    
        // MARK: - Playback Controls
    
    func playAudio() {
        ambientMusicPlayer?.play()
        voiceOverPlayer.play()
        startProgressTimer()
        isPlaying = true
        updatePlaybackToggleIcon()
    }

    func pauseAudio() {
        ambientMusicPlayer.pause()
        voiceOverPlayer.pause()
        isPlaying = false
        updatePlaybackToggleIcon()
    }
    
    func jumpToTime(_ time: Double) {
        guard let ambientMusicPlayer = ambientMusicPlayer, let voiceOverPlayer = voiceOverPlayer else { return }
        
        ambientMusicPlayer.currentTime += time
        voiceOverPlayer.currentTime += time
    
        if ambientMusicPlayer.currentTime < 0 {
            ambientMusicPlayer.currentTime = 0
        }
        
        if voiceOverPlayer.currentTime < 0 {
            voiceOverPlayer.currentTime = 0
        }
        
    }
    
    func updatePlaybackToggleIcon() {
        let iconName = isPlaying ? "pause.fill" : "play.fill"
        playbackToggle.setImage(UIImage(systemName: iconName), for: .normal)
    }

    
    func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }

    @objc func updateProgress() {
        guard let ambientMusicPlayer = ambientMusicPlayer, let voiceOverPlayer = voiceOverPlayer else { return }
        
        let ambientMusicDuration = ambientMusicPlayer.duration
        let voiceOverDuration = voiceOverPlayer.duration
        
        longerDuration = max(ambientMusicDuration, voiceOverDuration)
        
        let currentTime = ambientMusicPlayer.currentTime
        let progress = currentTime / longerDuration
        experienceProgress.setProgress(Float(progress), animated: true)
    }
    
    func handleEndOfPlayback() {
        print("Handling end of playback.")
        progressTimer?.invalidate()
        progressTimer = nil
        experienceProgress.setProgress(1.0, animated: true)
        stopAudio()
    }

    func stopAudio() {
        print("Stopping audio.")
        ambientMusicPlayer?.stop()
        voiceOverPlayer.stop()
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // Volume Calculation
    func calculateVolume(value: Float) {
        let voiceOverVolume: Float
        let ambientVolume: Float
        
        if value <= 0.5 {
            voiceOverVolume = voiceOverVolumeDefault + 2 * (0.5 - value) * (voiceOverVolumeDefault - voiceOverVolumeMin)
            ambientVolume = ambientMusicVolumeDefault - 2 * (0.5 - value) * (ambientMusicVolumeDefault - voiceOverVolumeMin)
        } else {
            voiceOverVolume = voiceOverVolumeDefault + 2 * (value - 0.5) * (voiceOverVolumeMax - voiceOverVolumeDefault)
            ambientVolume = voiceOverVolumeDefault - 2 * (value - 0.5) * (voiceOverVolumeMax - voiceOverVolumeDefault)
        }
        
        ambientMusicPlayer?.volume = ambientVolume
        voiceOverPlayer.volume = voiceOverVolume
    }
    
    deinit {
        print("Deinitializing ViewControllerVideoPlayer.")
        stopAudio()
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - Extensions
