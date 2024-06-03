//
//  SubtitleParser.swift
//  Test Meditation App Storyboard
//
//  Created by Travis Lizio on 3/6/2024.
//

import Foundation

func parseSRT(file: String) -> [Subtitle] {
    var subtitles: [Subtitle] = []
    let content = try! String(contentsOfFile: file)
    let components = content.components(separatedBy: "\n\n")
    
    for component in components {
        let parts = component.components(separatedBy: "\n")
        guard parts.count >= 3 else { continue }
        
        let timeParts = parts[1].components(separatedBy: " --> ")
        let start = timeStringToSeconds(timeString: timeParts[0])
        let end = timeStringToSeconds(timeString: timeParts[1])
        let text = parts[2...].joined(separator: "\n")
        
        subtitles.append(Subtitle(start: start, end: end, text: text))
    }
    return subtitles
}


func timeStringToSeconds(timeString: String) -> TimeInterval {
    let parts = timeString.components(separatedBy: ":")
    let hours = Double(parts[0])!
    let minutes = Double(parts[1])!
    let seconds = Double(parts[2].replacingOccurrences(of: ",", with: "."))!
    return hours * 3600 + minutes * 60 + seconds
}
