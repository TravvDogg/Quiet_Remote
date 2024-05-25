//
//  ViewControllerExperienceSelect.swift
//  Test Meditation App Storyboard
//
//  Created by Travis Lizio on 14/3/2024. (assisted by ChatGPT and Claude AI)
//

import UIKit
import Foundation
import AVFoundation

// MARK: - Utility Methods
class ViewControllerExperienceSelect: UIViewController {
    
    func loadExperienceData(genre: String, experienceName: String) async -> (Experience?, UIImage?, TimeInterval?) {
        guard let jsonPath = Bundle.main.path(forResource: "videoData", ofType: "json", inDirectory: "Media/Experiences/\(selectedGenre ?? "")/\(selectedExperienceName ?? "")") else {
            print("Failed to find JSON file")
            return (nil, nil, nil)
        }
        
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) else {
            print("Failed to load JSON data")
            return (nil, nil, nil)
        }
        
        let decoder = JSONDecoder()
        guard let experience = try? decoder.decode(Experience.self, from: jsonData) else {
            print("Failed to decode JSON data")
            return (nil, nil, nil)
        }
        
        // Load thumbnail image
        guard let thumbnailPath = Bundle.main.path(forResource: experience.thumbnail, ofType: nil, inDirectory: "Media/Experiences/\(genre)/\(experienceName)") else {
            print("Failed to find thumbnail image")
            return (experience, nil, nil)
        }
        
        guard let thumbnailImage = UIImage(contentsOfFile: thumbnailPath) else {
            print("Failed to load thumbnail image")
            return (experience, nil, nil)
            
        }
        
        // Get the duration of the ambient music and voice-over files
        var ambientMusicDuration: TimeInterval?
        var voiceOverDuration: TimeInterval?

        if let ambientMusicFilePath = Bundle.main.path(forResource: experience.ambientMusicFile, ofType: "mp3", inDirectory: "Media/Experiences/\(genre)/\(experienceName)") {
            let ambientMusicUrl = URL(fileURLWithPath: ambientMusicFilePath)
            let ambientMusicAsset = AVURLAsset(url: ambientMusicUrl)
            do {
                ambientMusicDuration = try await ambientMusicAsset.load(.duration).seconds
            } catch {
                print("Failed to load ambient music duration: \(error.localizedDescription)")
            }
        } else {
            print("Failed getting ambient music at Media/Experiences/\(genre)/\(experienceName)/\(experience.ambientMusicFile).mp3")
        }

        if let voiceOverFilePath = Bundle.main.path(forResource: experience.voiceOverFile, ofType: "mp3", inDirectory: "Media/Experiences/\(genre)/\(experienceName)") {
            let voiceOverUrl = URL(fileURLWithPath: voiceOverFilePath)
            let voiceOverAsset = AVURLAsset(url: voiceOverUrl)
            do {
                voiceOverDuration = try await voiceOverAsset.load(.duration).seconds
            } catch {
                print("Failed to load voice-over duration: \(error.localizedDescription)")
            }
        } else {
            print("Failed getting voice-over at Media/Experiences/\(genre)/\(experienceName)/\(experience.voiceOverFile).mp3")
        }
        // Set the duration variable to the length of the longer file
        var duration: TimeInterval?
        if let ambientMusicDuration = ambientMusicDuration, let voiceOverDuration = voiceOverDuration {
            duration = max(ambientMusicDuration, voiceOverDuration)
        } else if let ambientMusicDuration = ambientMusicDuration {
            duration = ambientMusicDuration
        } else if let voiceOverDuration = voiceOverDuration {
            duration = voiceOverDuration
        }

        return (experience, thumbnailImage, duration)
    }
    
        // MARK: - Outlets
    
    @IBOutlet weak var backgroundView: UIView!
    
    @IBOutlet weak var headingLabel: UILabel!
    
    @IBOutlet weak var creditsLabel: UILabel!
    
    @IBOutlet weak var thumbnailImage: UIImageView!
    
    @IBOutlet weak var uiExperienceSelectEllipsesButton: UIButton!
    
    // Title, Credits, Thumbnail, and Description
    @IBOutlet weak var titleButtonText: UIButton!
    
    
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var moreButton: UILabel!
    
    // Indicators
    @IBOutlet weak var hapticsIndicator: UIButton!
    
    @IBOutlet weak var voiceOverIndicator: UIButton!
    
    @IBOutlet weak var ambientIndicator: UIButton!
    
    var mainViewController: ViewController?
    
    // MARK: - Properties
    
    var selectedExperience: Experience?
    
    var selectedGenre: String?
    var selectedExperienceName: String?

    // MARK: - Actions
    
    let infoIcon = UIImage(systemName: "info.bubble")
    @IBAction func UiExperienceSelectEllipsesButtonPressed(_ sender: UIButton) {
        var muteUI: UIMenu
        
        let creditsMenu = UIMenu(
            title: "",
            options: .displayInline,
            children: [
                UIAction (
                    title: "Credits",
                    image: UIImage(systemName: "info.circle"),
                    handler: {_ in
                        print("Credits action selected")
                    }
                )
            ]
        )
        
        
        muteUI = UIMenu(
            title: "",
            children: ColorManager.shared.muteUI! + [creditsMenu]
        )
        
        sender.showsMenuAsPrimaryAction = true
        sender.menu = muteUI
    }
    
    @IBAction func segueToVideoPlayer(_ sender: Any) {
        if let genre = selectedGenre, let experienceName = selectedExperienceName {
                Task {
                    let (experience, thumbnailImage, duration) = await loadExperienceData(genre: genre, experienceName: experienceName)
                    selectedExperience = experience
                    
                    if selectedExperience != nil {
                        // Perform the segue to the video player
                        performSegue(withIdentifier: "showVideoPlayer", sender: self)
                    } else {
                        print("Selected experience is nil. Segue cancelled.")
                    }
                }
            } else {
                // Handle the case when selectedGenre or selectedExperienceName is nil
                print("Selected genre or experience name is missing.")
            }
    }

        
        // MARK: - UI Configuration
    func configureUI() {
        if #available(iOS 13.0, *) {
            // Force dark mode to fit the app's theme
            overrideUserInterfaceStyle = .dark
        }
    }
    
    
        // MARK: - Lifecycle Methods
    override func viewDidLoad(){
        super.viewDidLoad()
        configureUI()
        if let backgroundColor = ColorManager.shared.backgroundColor {
            self.backgroundView.backgroundColor = backgroundColor
            //TODO: - set background color to be seperate from the main genre's colors.
        }
        
        if let tintColor = ColorManager.shared.tintColor {
            
        }
        // Do any additional setup after loading the view.
        
        if let genre = selectedGenre,
           let experienceName = selectedExperienceName {
            Task {
                let (experience, thumbnailImage, duration) = await loadExperienceData(genre: genre, experienceName: experienceName)
                updateUI(experience: experience, thumbnailImage: thumbnailImage, duration: duration)
            }
        } else {
            // Handle the case when selectedGenre or selectedExperienceName is nil
            print("Selected genre or experience name is missing. - Lifecycle")
        }
    }
    func updateUI(experience: Experience?, thumbnailImage: UIImage?, duration: TimeInterval?) {
        guard let experience = experience else {
            return
        }
        
#if DEBUG
        print("------------ \(experience.title) ---------------")
        print("Title: \(experience.title)")
        print("Description: \(experience.description)")
        print("Thumbnail: \(experience.thumbnail)")
        print("Has Voice Over: \(experience.hasVoiceOver)")
        print("Has Ambient Sound: \(experience.hasAmbientSound)")
        print("Voice Over File: \(experience.voiceOverFile)")
        print("Ambient Music File: \(experience.ambientMusicFile)")
        print("Subtitles: \(experience.subtitles)")
        print("Has Haptics: \(experience.hasHaptics)")
        print("Haptics: \(experience.haptics)")
        print("Video File Location: \(experience.videoFileLocation)")
        print("Credits:")
        print("  Voice Over Credit: \(experience.credits.voiceOverCredit)")
        print("  Ambient Sound Credit: \(experience.credits.ambientSoundCredit)")
        print("  Haptics Credit: \(experience.credits.hapticsCredit)")
        print("  Script Credit: \(experience.credits.scriptCredit)")
#endif
        
        //MARK: - Indicators and Labels
        // Haptics Indicator
        if experience.hasHaptics {
            hapticsIndicator.alpha = 1
        } else {
            hapticsIndicator.alpha = 0.25
        }
        
        // Voice Over Indicator
        if experience.hasVoiceOver{
            voiceOverIndicator.alpha = 1
        } else {
            voiceOverIndicator.alpha = 0.25
        }
        
        // Ambient sound Indicator
        if experience.hasAmbientSound {
            ambientIndicator.alpha = 1
        } else {
            ambientIndicator.alpha = 0.25
        }
        
        
        // Set experience title
        headingLabel.text = experience.title
        
        // Set Credits text
        func creditToDisplay(experience: Experience, duration: TimeInterval?) -> String {
            var formattedDuration = ""

            if let duration = duration {
                if duration >= 3600 {
                    let hours = Int(duration / 3600)
                    let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
                    let hourUnit = hours == 1 ? "hour" : "hours"
                    let minuteUnit = minutes == 1 ? "minute" : "minutes"
                    formattedDuration = String(format: "%d %@ %02d %@", hours, hourUnit, minutes, minuteUnit)
                } else {
                    let minutes = Int(duration / 60)
                    let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
                    let minuteUnit = minutes == 1 ? "minute" : "minutes"
                    let secondUnit = seconds == 1 ? "second" : "seconds"
                    formattedDuration = String(format: "%d %@ %02d %@", minutes, minuteUnit, seconds, secondUnit)
                }
            }

            if !experience.credits.voiceOverCredit.isEmpty {
                return "Read by \(experience.credits.voiceOverCredit)" + (formattedDuration.isEmpty ? "" : " · \(formattedDuration)")
            } else if !experience.credits.scriptCredit.isEmpty {
                return "Script by \(experience.credits.scriptCredit)" + (formattedDuration.isEmpty ? "" : " · \(formattedDuration)")
            } else if !formattedDuration.isEmpty {
                return formattedDuration
            } else {
                print("failed to display duration or any credits: read by: \(experience.credits.voiceOverCredit). script by: \(experience.credits.scriptCredit). duration: \(String(describing: duration))")
                return ""
            }
        }

        
        creditsLabel.text = creditToDisplay(experience: experience, duration: duration)
        
        
        // Set Description Text
        descriptionLabel.text = experience.description
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = CGRect(
            x: 0,
            y: descriptionLabel.bounds.height / 2,
            width: descriptionLabel.bounds.width,
            height: descriptionLabel.bounds.height / 2
        )
        gradientLayer.colors = [
            UIColor.white.cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.startPoint = CGPoint(
            x: 0.7,
            y: 0.5
        )
        gradientLayer.endPoint = CGPoint(
            x: 0.85,
            y: 0.5
        )
        
        let opaqueLayer = CALayer()
        opaqueLayer.backgroundColor = UIColor.white.cgColor
        opaqueLayer.frame = CGRect(
            x: 0,
            y: 0,
            width: descriptionLabel.bounds.width,
            height: descriptionLabel.bounds.height / 2
        )
        
        let maskLayer = CALayer()
        maskLayer.frame = descriptionLabel.bounds
        maskLayer.addSublayer(gradientLayer)
        maskLayer.addSublayer(opaqueLayer)
        
        descriptionLabel.layer.mask = maskLayer
        
        // Set Thumbnail Image
        if let thumbnailImage = thumbnailImage {
            self.thumbnailImage.image = thumbnailImage
        }
    }
        
        // MARK: - Navigation
        
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showVideoPlayer" || segue.identifier == "showCredits" {
            if let videoPlayerViewController = segue.destination as? ViewControllerVideoPlayer {
                if let selectedExperience = selectedExperience {
                    videoPlayerViewController.experienceData = selectedExperience
                    videoPlayerViewController.genre = selectedGenre
                    videoPlayerViewController.experienceName = selectedExperienceName
                } else {
                    print("Selected experience is nil. Segue cancelled.")
                    return
                }
            }
        }
    }
}

        // MARK: - Extensions
    
// Extension to count the number of lines in a label
extension UILabel {
    func countLines() -> Int {
        guard self.text != nil else {
            return 0
        }
        
        let rect = self.bounds
        let size = self.sizeThatFits(CGSize(width: rect.width, height: CGFloat.greatestFiniteMagnitude))
        let numLines = Int(size.height / self.font.lineHeight)
        
        return numLines
    }
}
