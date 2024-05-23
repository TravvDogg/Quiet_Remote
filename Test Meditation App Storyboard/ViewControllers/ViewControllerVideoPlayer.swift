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
    
    // MARK: - Actions
    
    
    // Audio volume customisation
    
    // Parameters
    var ambientMusicVolumeDefault: Float = 0.25
    var voiceOverVolumeDefault: Float = 1.0
    
    var ambientMusicVolumeMax: Float = 0.75
    var ambientMusicVolumeMin: Float = 0.0
    var voiceOverVolumeMax: Float = 1.0
    var voiceOverVolumeMin: Float = 0.0
    // Update values
    @IBAction func balanceSlider(_ sender: UISlider) {
        balanceSlider.value = roundf(balanceSlider.value) // Slider value snapping
        
        var sliderDecimalValue = balanceSlider.value / balanceSlider.maximumValue
        calculateVolume(value: sliderDecimalValue)
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
        
        guard let experienceData = experienceData else {
            print("Experience data is unavailable.")
            return
        }
        
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
                print("Ambient Music finished, triggering end of playback.")
                self.handleEndOfPlayback()
            }
        } else {
            completionHandler = {
                print("VoiceOver finished, triggering end of playback.")
                self.handleEndOfPlayback()
            }
        }
        
        ambientMusicPlayerNode.scheduleFile(ambientMusicFile, at: nil, completionHandler: ambientMusicDuration >= voiceOverDuration ? completionHandler : nil)
        voiceOverPlayerNode.scheduleFile(voiceOverFile, at: nil, completionHandler: voiceOverDuration > ambientMusicDuration ? completionHandler : nil)
        
        ambientMusicPlayerNode.play()
        voiceOverPlayerNode.play()
        
        startProgressTimer()
    }
    
    func startProgressTimer() {
        progressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }
    @objc func updateProgress() {
        guard longerDuration > 0 else { return }
        
        let currentTime = ambientMusicPlayerNode.lastRenderTime.flatMap { ambientMusicPlayerNode.playerTime(forNodeTime: $0)}?.sampleTime ?? 0
        
        let progress = Double(currentTime) / ambientMusicFile.fileFormat.sampleRate / longerDuration
        experienceProgress.setProgress(Float(progress), animated: true)
    }
    
    func handleEndOfPlayback() {
        progressTimer?.invalidate()
        progressTimer = nil
        experienceProgress.setProgress(1.0, animated: true)
    }
    
    func pauseAudio() {
        ambientMusicPlayerNode.pause()
        voiceOverPlayerNode.pause()
    }

    func stopAudio() {
        ambientMusicPlayerNode.stop()
        voiceOverPlayerNode.stop()
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
        stopAudio()
        audioEngine.stop()
    }
    
    // Volume Calculation
    func calculateVolume(value: Float) {
            let voiceOverVolume: Float
            let ambientVolume: Float
            
            if value <= 0.5 {
                voiceOverVolume = voiceOverVolumeDefault + 2 * (0.5 - value) * (voiceOverVolumeDefault - voiceOverVolumeMin)
                ambientVolume = ambientMusicVolumeDefault - 2 * (0.5 - value) * (ambientMusicVolumeDefault - voiceOverVolumeMin)
            } else {
                voiceOverVolume = voiceOverVolumeDefault + 2 * (value - 0.5) * (voiceOverVolumeDefault - voiceOverVolumeMin)
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
