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
    
    // Update values
    @IBAction func balanceSlider(_ sender: UISlider) {
        balanceSlider.value = roundf(balanceSlider.value) // Slider value snapping
        
        var sliderDecimalValue = balanceSlider.value / balanceSlider.maximumValue
        calculateVolume(value: 1 - sliderDecimalValue)
    }
    

    @IBAction func togglePlayPause(_ sender: UIButton) {
        if isPlaying {
            pauseAudio()
        } else {
            playAudio()
        }
    }
    
    
    @IBAction func fastForward(_ sender: UIButton) {
    }
    
    @IBAction func rewind(_ sender: UIButton) {
    }
    
    // MARK: - Properties
    
    var experienceData: Experience?
    var genre: String?
    var experienceName: String?
    
    
    // Audio Engine
    var audioEngine: AVAudioEngine!
    var ambientMusicPlayerNode: AVAudioPlayerNode!
    var voiceOverPlayerNode: AVAudioPlayerNode!
    
    var ambientMusicFile: AVAudioFile!
    var voiceOverFile: AVAudioFile!
    
    var ambientMusicVolume: Float = 1.0
    var voiceOverVolume: Float = 1.0
        
    var progressTimer: Timer?
    var longerDuration: Double = 0.0
    
    
    // MARK: - UI Configuration
    func configureUI() {
        if #available(iOS 13.0, *) {
            // Force dark mode to fit the app's theme
            overrideUserInterfaceStyle = .dark
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureAudioEngine()
        if let backgroundColor = ColorManager.shared.backgroundColor {
            self.backgroundView.backgroundColor = backgroundColor
            //TODO: - set background color to be seperate from the main genre's colors.
        }
        
        guard let experienceData = experienceData else {
            print("Experience data is unavailable.")
            return
        }
        
        playbackToggle.setImage(UIImage(systemName: "play.fill"), for: .normal)
        playAudio()
        
        setAmbientMusicVolume(ambientMusicVolumeDefault)
        setVoiceOverVolume(voiceOverVolumeDefault)
    }


    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
                        
            if let viewControllerExperienceSelect = presentingViewController as? ViewControllerExperienceSelect,
               let mainViewController = viewControllerExperienceSelect.mainViewController {
                mainViewController.stopAudioPlayers()
            } else {
                print("Presenting view controller is not an instance of OverlayViewController or mainViewController is nil")
            }
            
            // start video player audio.
        }
    override func viewWillDisappear(_ animated: Bool) {
        stopAudio()
    }
    
    // MARK: - Utility and Helper Functions
    
    func configureAudioEngine() {
        audioEngine = AVAudioEngine()
        
        ambientMusicPlayerNode = AVAudioPlayerNode()
        voiceOverPlayerNode = AVAudioPlayerNode()
        
        audioEngine.attach(ambientMusicPlayerNode)
        audioEngine.attach(voiceOverPlayerNode)
        
        guard let ambientMusicFileName = experienceData?.ambientMusicFile,
              let voiceOverFileName = experienceData?.voiceOverFile else {
            print("Failed to unwrap optional file names")
            return
        }
        
        // Load audio files
        guard let ambientMusicUrl = Bundle.main.url(forResource:
                "Media/Experiences/\(genre! as String)/\(experienceName! as String)/\(ambientMusicFileName)", withExtension: "mp3"),
              let voiceOverUrl = Bundle.main.url(forResource:
                "Media/Experiences/\(genre! as String)/\(experienceName! as String)/\(voiceOverFileName)", withExtension: "mp3")
        else {
            print("Failed to load audio files")
            print(ambientMusicFileName)
            return
        }
        
        do {
            ambientMusicFile = try AVAudioFile(forReading: ambientMusicUrl)
            voiceOverFile = try AVAudioFile(forReading: voiceOverUrl)
        } catch {
            print("Error loading audio files: \(error.localizedDescription)")
        }
        
        // Connect audio nodes to audio engine
        audioEngine.connect(ambientMusicPlayerNode, to: audioEngine.mainMixerNode, format: ambientMusicFile.processingFormat)
        audioEngine.connect(voiceOverPlayerNode, to: audioEngine.mainMixerNode, format: voiceOverFile.processingFormat)
        
        // Prepare the engine
        do {
            try audioEngine.start()
        } catch {
            print("Error starting the audio engine: \(error.localizedDescription)")
        }
    }
    
    func getAudioFileDuration(_ audioFile: AVAudioFile) -> Double {
        return Double(audioFile.length) / audioFile.fileFormat.sampleRate
    }
    
        // MARK: - Playback Controls
    func playAudio() {
        let ambientMusicDuration = getAudioFileDuration(ambientMusicFile)
        let voiceOverDuration = getAudioFileDuration(voiceOverFile)

        longerDuration = max(ambientMusicDuration, voiceOverDuration)

        var completionHandler: (() -> Void)?

        if ambientMusicDuration >= voiceOverDuration {
            completionHandler = {
                DispatchQueue.main.async {
                    print("Ambient Music finished, triggering end of playback.")
                    self.handleEndOfPlayback()
                }
            }
        } else {
            completionHandler = {
                DispatchQueue.main.async {
                    print("VoiceOver finished, triggering end of playback.")
                    self.handleEndOfPlayback()
                }
            }
        }

        ambientMusicPlayerNode.scheduleFile(ambientMusicFile, at: nil, completionHandler: ambientMusicDuration >= voiceOverDuration ? completionHandler : nil)
        voiceOverPlayerNode.scheduleFile(voiceOverFile, at: nil, completionHandler: voiceOverDuration > ambientMusicDuration ? completionHandler : nil)

        ambientMusicPlayerNode.play()
        voiceOverPlayerNode.play()

        startProgressTimer()
        isPlaying = true
        DispatchQueue.main.async {
            UIView.transition(with: self.playbackToggle, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.playbackToggle.setImage(UIImage(systemName: "pause.fill"), for: .normal)
            }, completion: nil)
        }
    }

    func pauseAudio() {
        ambientMusicPlayerNode.pause()
        voiceOverPlayerNode.pause()
        isPlaying = false
        DispatchQueue.main.async {
            UIView.transition(with: self.playbackToggle, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.playbackToggle.setImage(UIImage(systemName: "play.fill"), for: .normal)
            }, completion: nil)
        }
    }

    
    func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }
    @objc func updateProgress() {
        guard longerDuration > 0 else { return }
        
        if isPlaying {
            let currentTime = ambientMusicPlayerNode.lastRenderTime.flatMap { ambientMusicPlayerNode.playerTime(forNodeTime: $0)}?.sampleTime ?? 0
            let progress = Double(currentTime) / ambientMusicFile.fileFormat.sampleRate / longerDuration
            experienceProgress.setProgress(Float(progress), animated: true)
        }
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
        ambientMusicPlayerNode.stop()
        voiceOverPlayerNode.stop()
        audioEngine.stop()
    }
    
    func setAmbientMusicVolume(_ volume: Float) {
        ambientMusicVolume = volume // volume to be used within the code
        ambientMusicPlayerNode.volume = volume // volume that the audio engine uses
    }
    
    func setVoiceOverVolume(_ volume: Float) {
        voiceOverVolume = volume // volume to be used within the code
        voiceOverPlayerNode.volume = volume // volume that the audio engine uses
    }
    
    deinit {
        print("Deinitializing ViewControllerVideoPlayer.")
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
            
            setVoiceOverVolume(voiceOverVolume)
            setAmbientMusicVolume(ambientVolume)
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
