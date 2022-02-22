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
        "music_name" : "TEST001",
        "artist_name" : "ARTIST001",
        "track_name" : "TEST001",
        "cover_name" : "TEST001"
        },
        {
        "music_name" : "TEST002",
        "artist_name" : "ARTIST002",
        "track_name" : "TEST002",
        "cover_name" : "TEST002"

        },
        {
        "music_name" : "TEST003",
        "artist_name" : "ARTIST003",
        "track_name" : "TEST003",
        "cover_name" : "TEST003"

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
                observer.onNext(getInstanceData!.MusicInfo)
            } else {
                observer.onNext(getInstanceData!.MusicInfo.filter{$0.name.lowercased().contains(str.lowercased()) || $0.artistName.lowercased().contains(str.lowercased())})
            }
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    func getSelectedMusicList(_ list: [String]) -> Observable<[Music]>{
        return Observable.create { observer -> Disposable in
            
            let dataJSON = JSON.data(using: .utf8)!
            // let dataJSON = try JSONSerialization.data(withJSONObject: [], options: .prettyPrinted)
            let getInstanceData = try? JSONDecoder().decode(MusicArr.self, from: dataJSON)
            observer.onNext(getInstanceData!.MusicInfo.filter{list.contains($0.name)})
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
}
