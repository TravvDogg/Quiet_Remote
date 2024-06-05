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
    
    @IBOutlet weak var subtitleLabel: UILabel!
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
            calculateVolume(value: sliderDecimalValue)
            
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
        feedbackGenerator.impactOccurred()
    }
    
    @IBAction func rewind(_ sender: UIButton) {
        jumpToTime(-10)
        feedbackGenerator.impactOccurred()
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
    
    // Subtitles
    var subtitles: [Subtitle] = []
    var subtitleTimer: Timer?
    
    
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
        
        if let subtitleFileName = experienceData.subtitles, !subtitleFileName.isEmpty {
            let subtitleFilePath = Bundle.main.path(forResource: "Media/Experiences/\(genre!)/\(experienceName!)/\(subtitleFileName)", ofType:"srt")
            if let subtitleFilePath = subtitleFilePath {
                subtitles = parseSRT(file: subtitleFilePath)
            } else {
                print("Subtitle path is invalid")
            }
        } else {
            print("Subtitle file name is invalid or file name is not declared.")
        }
        
        if experienceData.hasAmbientSound || experienceData.hasVoiceOver {
            if let ambientMusicPlayer = ambientMusicPlayer, let voiceOverPlayer = voiceOverPlayer {
                if experienceData.hasHaptics && !experienceData.hasVoiceOver {
                    ambientMusicPlayer.volume = ambientMusicVolumeDefault
                    voiceOverPlayer.volume = 0.0
                } else if !experienceData.hasAmbientSound && experienceData.hasVoiceOver {
                    ambientMusicPlayer.volume = 0.0
                    voiceOverPlayer.volume = voiceOverVolumeDefault
                } else {
                    // Handle case where no audio is present or available.
                }
                
                calculateVolume(value: 0.5)
            }
        }
        if experienceData.hasAmbientSound && !experienceData.hasVoiceOver {
            balanceSlider.isEnabled = false
        } else if experienceData.hasVoiceOver && !experienceData.hasAmbientSound {
            balanceSlider.isEnabled = false
        } else {
            balanceSlider.isEnabled = true
        }
        
        playAudio()
        
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
        stopSubtitleSync()
    }
    
    // MARK: - Utility and Helper Functions
    
        // MARK: - Subtitle Functions
    func startSubtitleSync() {
        subtitleTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateSubtitle), userInfo: nil, repeats: true)
    }
    
    @objc func updateSubtitle() {
        let currentTime = max(ambientMusicPlayer?.currentTime ?? 0, voiceOverPlayer?.currentTime ?? 0)
        
        if let subtitle = subtitles.first(where: { $0.start <= currentTime && $0.end >= currentTime }) {
            if subtitleLabel.text != subtitle.text {
                fadeOutSubtitle {
                    self.subtitleLabel.text = subtitle.text
                    self.fadeInSubtitle()
                }
            }
        } else {
            if !subtitleLabel.text!.isEmpty {
                fadeOutSubtitle() {
                    self.subtitleLabel.text = ""
                }
            }
        }
    }
    
    func fadeInSubtitle(duration: TimeInterval = 0.2) {
        UIView.animate(withDuration: duration) {
            self.subtitleLabel.alpha = 1.0
        }
    }
    
    func fadeOutSubtitle(duration: TimeInterval = 0.2, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.subtitleLabel.alpha = 0.0
        }) { _ in
            completion?()
        }
    }
    
    func stopSubtitleSync() {
        subtitleTimer?.invalidate()
        subtitleTimer = nil
    }
    
        // MARK: - Audio File Setup

    func setupAudioPlayers() {
        guard let experienceData = experienceData,
              let genre = genre,
              let experienceName = experienceName else {
            print("Experience data is unavailable")
            return
        }
        
        var ambientMusicUrl: URL?
        var voiceOverUrl: URL?

        
        if experienceData.hasAmbientSound {
            let ambientMusicFileName = experienceData.ambientMusicFile
            ambientMusicUrl = Bundle.main.url(forResource: "Media/Experiences/\(genre)/\(experienceName)/\(ambientMusicFileName)", withExtension: "mp3")
        }
        
        if experienceData.hasVoiceOver {
            let voiceOverFileName = experienceData.voiceOverFile
            voiceOverUrl = Bundle.main.url(forResource: "Media/Experiences/\(genre)/\(experienceName)/\(voiceOverFileName)", withExtension: "mp3")
        }
        
        do {
            if let ambientMusicUrl = ambientMusicUrl {
                ambientMusicPlayer = try AVAudioPlayer(contentsOf: ambientMusicUrl)
                ambientMusicPlayer.volume = ambientMusicVolumeDefault
            } else {
                print("ambient music file is not available")
                ambientMusicPlayer = nil
            }
            
            if let voiceOverUrl = voiceOverUrl {
                voiceOverPlayer = try AVAudioPlayer(contentsOf: voiceOverUrl)
                voiceOverPlayer.volume = voiceOverVolumeDefault
            } else {
                print("Voiceover file is not available")
            }
        } catch {
            print("Error loading audio files: \(error.localizedDescription)")
        }
    }
    
    func getAudioFileDuration(_ audioFile: AVAudioFile) -> Double {
        return Double(audioFile.length) / audioFile.fileFormat.sampleRate
    }
    
            // MARK: - Playback Controls
    
    func playAudio() {
        if let ambientMusicPlayer = ambientMusicPlayer {
            ambientMusicPlayer.play()
        }
        if let voiceOverPlayer = voiceOverPlayer {
            voiceOverPlayer.play()
        }
        
        startProgressTimer()
        startSubtitleSync()
        isPlaying = true
        updatePlaybackToggleIcon()
    }

    func pauseAudio() {
        if let ambientMusicPlayer = ambientMusicPlayer {
            ambientMusicPlayer.pause()
        }
        if let voiceOverPlayer = voiceOverPlayer {
            voiceOverPlayer.pause()
        }
        isPlaying = false
        stopSubtitleSync()
        updatePlaybackToggleIcon()
    }
    
    func stopAudio() {
        if let ambientMusicPlayer = ambientMusicPlayer {
            ambientMusicPlayer.stop()
        }
        if let voiceOverPlayer = voiceOverPlayer {
            voiceOverPlayer.stop()
        }
        isPlaying = false
        updatePlaybackToggleIcon()
        stopSubtitleSync()
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    func jumpToTime(_ time: Double) {
        if let ambientMusicPlayer = ambientMusicPlayer {
            ambientMusicPlayer.currentTime += time
            if ambientMusicPlayer.currentTime < 0 {
                ambientMusicPlayer.currentTime = 0
            }
        }
        if let voiceOverPlayer = voiceOverPlayer {
            voiceOverPlayer.currentTime += time
            if voiceOverPlayer.currentTime < 0 {
                voiceOverPlayer.currentTime = 0
            }
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
        var currentTime: Double = 0.0
        var duration: Double = 0.0
        
        if let ambientMusicPlayer = ambientMusicPlayer {
            currentTime = max(currentTime, ambientMusicPlayer.currentTime)
            duration = max(duration, voiceOverPlayer.duration)
        }
        
        if let voiceOverPlayer = voiceOverPlayer {
            currentTime = max(currentTime, voiceOverPlayer.currentTime)
            duration = max(duration, voiceOverPlayer.duration)
        }
        
        if duration > 0 {
            let progress = currentTime / duration
            experienceProgress.setProgress(Float(progress), animated: true)
        } else {
            experienceProgress.setProgress(0.0, animated: true)
        }
    }
    
    func handleEndOfPlayback() {
        print("Handling end of playback.")
        progressTimer?.invalidate()
        progressTimer = nil
        experienceProgress.setProgress(1.0, animated: true)
        stopAudio()
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
        if let ambientMusicPlayer = ambientMusicPlayer {
            ambientMusicPlayer.volume = ambientVolume
        }
        if let voiceOverPlayer = voiceOverPlayer {
            voiceOverPlayer.volume = voiceOverVolume
        }
    }
    
    deinit {
        print("Deinitializing ViewControllerVideoPlayer.")
        stopAudio()
        stopSubtitleSync()
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
