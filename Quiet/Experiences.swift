//
//  Experiences.swift
//  Quiet
//
//  Created by Travis Lizio on 26/3/2024.
//

import Foundation

struct Experience: Codable {
    let title: String
    let description: String
    let thumbnail: String
    let subtitles: String
    let hasVoiceOver: Bool
    let voiceOver: String
    let hasAmbientSound: Bool
    let ambientSound: String
    let hasHaptics: Bool
    let haptics: String
    let credits: Credits
    let videoFileLocation: String
    
    struct Credits: Codable {
        let voiceOverCredit: String
        let ambientSoundCredit: String
        let hapticsCredit: String
        let scriptCredit: String
    }
}
