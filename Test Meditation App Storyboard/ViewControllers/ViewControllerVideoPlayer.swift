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
        balanceSlider.value
    }
    
    // MARK: - Properties
    
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
        
        
    }
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        print("view will appear or something")
        AudioManager.shared.stopAllAudio()
        
        // start video player audio.
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

class AudioManager {
    static let shared = AudioManager()
    
    var audioPlayers: [AVAudioPlayer?] = [nil, nil, nil, nil]
    
    func stopAllAudio(){
        for player in audioPlayers {
            player?.stop()
        }
    }
}
