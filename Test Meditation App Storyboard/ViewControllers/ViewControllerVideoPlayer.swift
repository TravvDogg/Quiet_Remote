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
    
    // MARK: - Actions
    
    @IBAction func balanceSlider(_ sender: UISlider) {
        balanceSlider.value = roundf(balanceSlider.value)
        
    }
    
    // MARK: - Properties
    var audioEngine: AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    var audioMixerNode: AVAudioMixerNode!
    var audioFile: AVAudioFile!
    var audioUnitEQ: AVAudioUnitEQ!
    
    var experienceData: Experience?
    var genre: String?
    var experienceName: String?
    
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
        
        // Initialize audio engine
        audioEngine = AVAudioEngine()
        
        // Create audio player node
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        // Create mixer node
        audioMixerNode = audioEngine.mainMixerNode
        
        // Create audio unit EQ
        audioUnitEQ = AVAudioUnitEQ(numberOfBands: 4)
        audioEngine.attach(audioUnitEQ)
        
        // Connect audio nodes
        audioEngine.connect(audioPlayerNode, to: audioUnitEQ, format: nil)
        audioEngine.connect(audioUnitEQ, to: audioMixerNode, format: nil)
        
        guard let experienceData = experienceData else {
            print("experience data is unavailable.")
            return
        }
        
        // Load audio file
        if let genre = genre,
           let experienceName = experienceName,
           let soundFilePath = Bundle.main.path(forResource: experienceData.soundFile, ofType: nil, inDirectory: "Media/Experiences/\(genre)/\(experienceName)") {
            do {
                audioFile = try AVAudioFile(forReading: URL(fileURLWithPath: soundFilePath))
            } catch {
                print("Failed to load audio file: \(error)")
            }
        } else {
            print("Genre ,experience name or experienceData is missing.")
            print("Genre: \(genre ?? "not assigned"), Experience Name: \(experienceName ?? "not assigned")")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            print("view will appear or something")
            
            if let viewControllerExperienceSelect = presentingViewController as? ViewControllerExperienceSelect,
               let mainViewController = viewControllerExperienceSelect.mainViewController {
                mainViewController.stopAudioPlayers()
                print("stop audio players")
            } else {
                print("Presenting view controller is not an instance of OverlayViewController or mainViewController is nil")
            }
            
            // start video player audio.
        }
    
    // MARK: - Utility and Helper Functions

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
