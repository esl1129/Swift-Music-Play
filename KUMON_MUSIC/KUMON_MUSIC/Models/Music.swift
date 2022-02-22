//
//  Music.swift
//  KUMON_MUSIC
//
//  Created by mcnc on 2022/02/21.
//

import Foundation

struct MusicArr: Codable{
    var status: Bool
    var MusicInfo: [Music]
    
    enum CodingKeys: String, CodingKey{
        case status
        case MusicInfo = "music_info"
    }
}
struct Music: Codable {
    let index: Int
    let name: String
    let artistName: String
    let trackName: String
    let coverName: String
    
    enum CodingKeys: String, CodingKey{
        case index = "index"
        case name = "music_name"
        case artistName = "artist_name"
        case trackName = "track_name"
        case coverName = "cover_name"
    }
    
    init(){
        self.index = 0
        self.name = ""
        self.artistName = ""
        self.trackName = ""
        self.coverName = ""
    }
}
