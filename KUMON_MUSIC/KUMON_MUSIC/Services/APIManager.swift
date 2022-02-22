//
//  APIManager.swift
//  KUMON_MUSIC
//
//  Created by mcnc on 2022/02/21.
//

import Foundation
import RxSwift
import RxCocoa

let JSON = """
{
    "status" : true,
    "music_info" : [
        {
        "index" : 1,
        "music_name" : "TEST001",
        "artist_name" : "ARTIST001",
        "track_name" : "TEST001",
        "cover_name" : "TEST001"
        },
        {
        "index" : 2,
        "music_name" : "TEST002",
        "artist_name" : "ARTIST002",
        "track_name" : "TEST002",
        "cover_name" : "TEST002"

        },
        {
        "index" : 3,
        "music_name" : "TEST003",
        "artist_name" : "ARTIST003",
        "track_name" : "TEST003",
        "cover_name" : "TEST003"

        },
        {
        "index" : 4,
        "music_name" : "TEST004",
        "artist_name" : "ARTIST004",
        "track_name" : "TEST004",
        "cover_name" : "TEST004"
        }
    ]
}
"""

final class APIManager{
    static let shared = APIManager()
}

// MARK: - Get Music List
extension APIManager {
    func getAllMusicList(_ str: String) -> Observable<[Music]>{
        return Observable.create { observer -> Disposable in
            
            let dataJSON = JSON.data(using: .utf8)!
            //let dataJSON = try JSONSerialization.data(withJSONObject: JSON, options: .prettyPrinted)
            let getInstanceData = try? JSONDecoder().decode(MusicArr.self, from: dataJSON)
            if str == "" {
                observer.onNext(getInstanceData!.MusicInfo.filter{Bundle.main.url(forResource: $0.trackName, withExtension: "mp3") != nil})
            } else {
                observer.onNext(getInstanceData!.MusicInfo.filter{($0.name.lowercased().contains(str.lowercased()) || $0.artistName.lowercased().contains(str.lowercased())) && Bundle.main.url(forResource: $0.trackName, withExtension: "mp3") != nil})
            }
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func getSelectedMusicList(_ list: [Int]) -> Observable<[Music]>{
        return Observable.create { observer -> Disposable in
            
            let dataJSON = JSON.data(using: .utf8)!
            // let dataJSON = try JSONSerialization.data(withJSONObject: [], options: .prettyPrinted)
            let getInstanceData = try? JSONDecoder().decode(MusicArr.self, from: dataJSON)
            observer.onNext(getInstanceData!.MusicInfo.filter{list.contains($0.index) && Bundle.main.url(forResource: $0.trackName, withExtension: "mp3") != nil})
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    func getCurrentMusic(_ index: Int) -> Observable<Music>{
        return Observable.create { observer -> Disposable in
            
            let dataJSON = JSON.data(using: .utf8)!
            // let dataJSON = try JSONSerialization.data(withJSONObject: [], options: .prettyPrinted)
            let getInstanceData = try? JSONDecoder().decode(MusicArr.self, from: dataJSON)
            observer.onNext(getInstanceData!.MusicInfo.filter{$0.index == index && Bundle.main.url(forResource: $0.trackName, withExtension: "mp3") != nil}.first ?? Music())
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}
