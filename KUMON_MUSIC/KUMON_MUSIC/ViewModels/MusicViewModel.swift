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
    lazy var currentMusicIndex = BehaviorRelay<Int>(value: 1)
    lazy var searchMusic = BehaviorRelay<String>(value: "")
    lazy var musicIndexList = BehaviorRelay<[Int]>(value: [1,2,3])
    lazy var repeatCheck = BehaviorRelay<Int>(value: 1)

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
    lazy var currentMusic: Driver<Music> = {
        return self.currentMusicIndex.asObservable()
            .throttle(.milliseconds(200), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .flatMapLatest(APIManager.shared.getCurrentMusic)
            .asDriver(onErrorJustReturn: Music())
    }()
    
}
