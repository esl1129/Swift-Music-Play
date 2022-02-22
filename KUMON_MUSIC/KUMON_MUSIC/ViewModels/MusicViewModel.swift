//
//  MusicViewModel.swift
//  KUMON_MUSIC
//
//  Created by mcnc on 2022/02/21.
//

import Foundation
import RxSwift
import RxCocoa
import RxRelay

class MusicViewModel{
    lazy var currentMusicIndex = BehaviorRelay<Int>(value: 0)
    lazy var currentMusic = BehaviorRelay<Music>(value: Music())
    lazy var searchMusic = BehaviorRelay<String>(value: "")
    
    lazy var currentMusicTime = BehaviorRelay<Float>(value: 0.0)
    lazy var durationMusicTime = BehaviorRelay<Float>(value: 0.0)

    lazy var musicIndexList = BehaviorRelay<[String]>(value: ["TEST001","TEST003"])
    
    lazy var musicData: Driver<[Music]> = {
        return self.searchMusic.asObservable()
            .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest(APIManager.shared.getAllMusicList)
            .asDriver(onErrorJustReturn: [])
    }()
    lazy var selectedMusicData: Driver<[Music]> = {
        return self.musicIndexList.asObservable()
            .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest(APIManager.shared.getSelectedMusicList)
            .asDriver(onErrorJustReturn: [])
    }()
    
}
