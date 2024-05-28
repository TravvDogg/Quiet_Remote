//
//  ViewControllerCredits.swift
//  Test Meditation App Storyboard
//
//  Created by Travis Lizio on 25/5/2024.
//

import UIKit

class ViewControllerCredits: UIViewController {
    
    // MARK: - Outlets

    @IBOutlet weak var creditsTextView: UITextView!
    
    @IBOutlet weak var backgroundView: UIView!
    
    // MARK: - Actions
    
    @IBAction func back(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Properties
    var experienceData: Experience?
    var genre: String?
    var experienceName: String?
    
    // Your function to set the formatted text
    func updateCreditsTextView() {
        let attributedString = NSMutableAttributedString()
        
        let centered = NSMutableParagraphStyle()
        centered.alignment = .center
        let leftAligned = NSMutableParagraphStyle()
        leftAligned.alignment = .left

        // Text attributes
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 20),
            .foregroundColor: UIColor.white,
            .paragraphStyle: centered
        ]
        let sectionTitleAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 16),
            .foregroundColor: UIColor.white,
            .paragraphStyle: centered
        ]
        let contentAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.white,
            .paragraphStyle: leftAligned
        ]
        
        // Title
        let title = NSAttributedString(
            string: "\(experienceData?.title ?? "No title available")\n\n",
            attributes: titleAttributes
        )
        attributedString.append(title)

        // Credits
        let creditsTitle = NSAttributedString(
            string: "Credits\n",
            attributes: sectionTitleAttributes
        )
        attributedString.append(creditsTitle)

        // Script
        let scriptCredit = NSAttributedString(
            string: "Script: \(experienceData?.credits.scriptCredit ?? "No script credit available")\n",
            attributes: contentAttributes
        )
        attributedString.append(scriptCredit)

        // VoiceOver
        if (experienceData?.hasVoiceOver ?? false) {
            let voiceOverCredit = NSAttributedString(
                string: "VoiceOver: \(experienceData?.credits.voiceOverCredit ?? "No voice-over credit available")\n",
                attributes: contentAttributes
            )
            attributedString.append(voiceOverCredit)
        }

        if (experienceData?.hasAmbientSound ?? false) {
            // Ambient Sound
            let ambientSoundCredit = NSAttributedString(
                string: "Ambient Sound: \(experienceData?.credits.ambientSoundCredit ?? "No ambient sound credit available")\n",
                attributes: contentAttributes
            )
            attributedString.append(ambientSoundCredit)
        }

        if (experienceData?.hasHaptics ?? false) {
            // Haptics
            let hapticsCredit = NSAttributedString(
                string: "Haptics: \(experienceData?.credits.hapticsCredit ?? "No haptics credit available")\n",
                attributes: contentAttributes
            )
            attributedString.append(hapticsCredit)
        }

        // Description
        let descriptionTitle = NSAttributedString(
            string: "\nDescription\n",
            attributes: sectionTitleAttributes
        )
        attributedString.append(descriptionTitle)
        
        let description = NSAttributedString(
            string: "\(experienceData?.description ?? "No description available")",
            attributes: contentAttributes
        )
        attributedString.append(description)

        // Set the attributed string to the UITextView
        creditsTextView.attributedText = attributedString
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        if let backgroundColor = ColorManager.shared.backgroundColor {
            self.backgroundView.backgroundColor = backgroundColor
            //TODO: - set background color to be seperate from the main genre's colors.
        }
        
        updateCreditsTextView()
    }
    
    // MARK: - UI Configuration
    func configureUI() {
        if #available(iOS 13.0, *) {
            // Force dark mode to fit the app's theme
            overrideUserInterfaceStyle = .dark
        }
    }

}
