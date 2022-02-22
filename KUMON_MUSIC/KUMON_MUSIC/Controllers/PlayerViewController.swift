//
//  PlayerViewController.swift
//  KUMON_MUSIC
//
//  Created by mcnc on 2022/02/21.
//

import UIKit
import AVFoundation
import RxSwift
import RxRelay
import RxCocoa
import MediaPlayer

let timer = Driver<Int>.interval(.seconds(1)).map { _ in
    return 1
}

class PlayerViewController: UIViewController, AVAudioPlayerDelegate {
    let musicViewModel = MusicViewModel()
    let disposeBag = DisposeBag()
    var songUrl: URL?
    var player: AVAudioPlayer!
    var isRunningSecond = false
    
    var playList: [Music] = []
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playBtn: UIImageView!
    @IBOutlet weak var forwardBtn: UIImageView!
    @IBOutlet weak var backwardBtn: UIImageView!
    @IBOutlet weak var shuffleBtn: UIImageView!
    @IBOutlet weak var repeatBtn: UIImageView!
    @IBOutlet weak var durationSlider: UISlider!
    override func viewDidLoad() {
        super.viewDidLoad()
        remoteCommandCenterSetting()
    }
    override func viewWillAppear(_ animated: Bool) {
        print(self.musicViewModel.currentMusicIndex.value)
        setUp()
        configure()
        playMusic()
    }
}

// MARK: - SetUp
extension PlayerViewController{
    func setUp(){
        musicViewModel.selectedMusicData
            .asDriver()
            .drive(onNext: {
                self.playList = $0
            })
            .disposed(by: disposeBag)
        
//        musicViewModel.currentMusicIndex
//            .subscribe(onNext: { index in
//                self.musicViewModel.currentMusic.accept(self.playList[index])
//            })
//            .disposed(by: disposeBag)
        
        timer.asObservable()
            .subscribe(onNext: { [weak self] value in
                if self!.isRunningSecond {
                    self?.musicViewModel.currentMusicTime.accept((self?.musicViewModel.currentMusicTime.value)!+1.0)
                }
            })
            .disposed(by: disposeBag)
        musicViewModel.currentMusicTime
            .subscribe(onNext: { time in
                self.durationSlider.value = time/(self.musicViewModel.durationMusicTime.value)
                if self.durationSlider.value >= 1.0 {
                    self.forwardMusic()
                }
            })
            .disposed(by: disposeBag)
        
        musicViewModel.currentMusic
            .asDriver()
            .drive(onNext: { music in
                let url = Bundle.main.url(forResource: music.coverName, withExtension: "png")
                if let url = url {
                    do {
                        let data = NSData(contentsOf: url)
                        self.coverImage.image = UIImage(data: data! as Data)
                        self.remoteCommandInfoCenterSetting(music, UIImage(data: data! as Data)!)
                    } catch let error {
                        print(error.localizedDescription)
                    }
                } else {
                    self.coverImage.image = UIImage(systemName: "playpause.fill")
                }
                
                self.songUrl = Bundle.main.url(forResource: music.trackName, withExtension: "mp3")

                self.titleLabel.text = music.name
                self.artistLabel.text = music.artistName
            })
            .disposed(by: disposeBag)
        
        let playPauseTap = UITapGestureRecognizer(target: self, action: #selector(didTapPlayPauseButton))
        playBtn.addGestureRecognizer(playPauseTap)
        playBtn.isUserInteractionEnabled = true
        let forwardTap = UITapGestureRecognizer(target: self, action: #selector(didTapForwardButton))
        forwardBtn.addGestureRecognizer(forwardTap)
        forwardBtn.isUserInteractionEnabled = true
        let backwardTap = UITapGestureRecognizer(target: self, action: #selector(didTapBackwardButton))
        backwardBtn.addGestureRecognizer(backwardTap)
        backwardBtn.isUserInteractionEnabled = true
    }
}

// MARK: - Music Play
extension PlayerViewController{
    func configure() -> Bool {
        self.musicViewModel.currentMusicTime.accept(0.0)
        if let url = songUrl {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player.volume = 0.1
                isRunningSecond = true
                self.musicViewModel.durationMusicTime.accept(Float(player.duration))
            } catch {
                print("error")
            }
        } else {
            return false
        }
        return true
    }
    
    @objc private func didTapPlayPauseButton(){
        if player == nil { return }
        if player.isPlaying == true{
            pauseMusic()
        } else {
            playMusic()
        }
    }
    @objc private func didTapForwardButton(){
        if player == nil { return }
        forwardMusic()
    }
    @objc private func didTapBackwardButton(){
        if player == nil { return }
        backwardMusic()
    }
    
    func playMusic(){
        self.isRunningSecond = true
        playBtn.image = UIImage(systemName: "pause.fill")
        player.play()
    }
    func pauseMusic(){
        isRunningSecond = false
        playBtn.image = UIImage(systemName: "play.fill")
        player.pause()
    }
    
    func forwardMusic(){
        if player == nil { return }
        let id = self.musicViewModel.currentMusicIndex.value
        let index = self.musicViewModel.musicIndexList.value.firstIndex(of: id)!
        let newId = index == self.musicViewModel.musicIndexList.value.endIndex ? self.musicViewModel.musicIndexList.value[0] : self.musicViewModel.musicIndexList.value[self.musicViewModel.musicIndexList.value.index(after: index)]
        self.musicViewModel.currentMusicIndex.accept(newId)

        isRunningSecond = false
        pauseMusic()
        if configure() {
            playMusic()
        } else {
            forwardMusic()
        }
    }
    
    func backwardMusic(){
        if player == nil { return }
        let id = self.musicViewModel.currentMusicIndex.value
        let index = self.musicViewModel.musicIndexList.value.firstIndex(of: id)!
        let newId = index == self.musicViewModel.musicIndexList.value.startIndex ? self.musicViewModel.musicIndexList.value[self.musicViewModel.musicIndexList.value.count-1] : self.musicViewModel.musicIndexList.value[self.musicViewModel.musicIndexList.value.index(before: index)]
        self.musicViewModel.currentMusicIndex.accept(newId)

        isRunningSecond = false
        pauseMusic()
        if configure() {
            playMusic()
        } else {
            backwardMusic()
        }
    }
    
    func remoteCommandCenterSetting() { // remote control event 받기 시작
        UIApplication.shared.beginReceivingRemoteControlEvents()
        let center = MPRemoteCommandCenter.shared() // 제어 센터 재생버튼 누르면 발생할 이벤트를 정의합니다.
        
        center.playCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            self.playMusic()
            return MPRemoteCommandHandlerStatus.success
            
        } // 제어 센터 pause 버튼 누르면 발생할 이벤트를 정의합니다.
        center.pauseCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            self.pauseMusic()
            return MPRemoteCommandHandlerStatus.success
        }
        center.nextTrackCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            self.forwardMusic()
            return MPRemoteCommandHandlerStatus.success
        }
        center.previousTrackCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            self.forwardMusic()
            return MPRemoteCommandHandlerStatus.success
        }
    }
    
    func remoteCommandInfoCenterSetting(_ music: Music, _ image: UIImage) {
        let center = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = center.nowPlayingInfo ?? [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = music.name
        nowPlayingInfo[MPMediaItemPropertyArtist] = music.artistName
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size in
            return image
        })
        if player == nil {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = 0.0 // 콘텐츠 재생 시간에 따른 progressBar 초기화
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0 // 콘텐츠 현재 재생시간
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = 0.0
        } else {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration // 콘텐츠 재생 시간에 따른 progressBar 초기화
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate // 콘텐츠 현재 재생시간
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
        }
        center.nowPlayingInfo = nowPlayingInfo
        
    }
}
