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
    var song = ""
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
        setUp()
        remoteCommandCenterSetting()
        configure()
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
        musicViewModel.currentMusicIndex
            .subscribe(onNext: { index in
                self.musicViewModel.currentMusic.accept(self.playList[index])
            })
            .disposed(by: disposeBag)
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
            .subscribe(onNext: { music in
                //                 let url = Bundle.main.url(forResource: music.coverName, withExtension: "png", subdirectory: "common/images")
                
                let url = Bundle.main.url(forResource: music.coverName, withExtension: "png")
                if let url = url {
                    do {
                        let data = NSData(contentsOf: url)
                        self.coverImage.image = UIImage(data: data! as Data)
                        self.remoteCommandInfoCenterSetting(music, UIImage(data: data! as Data)!)
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
                
                self.titleLabel.text = music.name
                self.artistLabel.text = music.artistName
                self.song = music.trackName
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
    func configure(){
        let url = Bundle.main.url(forResource: self.musicViewModel.currentMusic.value.trackName, withExtension: "mp3")
        if let url = url {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player.volume = 0.1
                playBtn.image = UIImage(systemName: "pause.fill")
                player.play()
                isRunningSecond = true
                self.musicViewModel.currentMusicTime.accept(0.0)
                self.musicViewModel.durationMusicTime.accept(Float(player.duration))
            } catch {
                print("error")
            }
        }
    }
    
    @objc private func didTapPlayPauseButton(){
        if player.isPlaying == true{
            pauseMusic()
        } else {
            playMusic()
        }
    }
    @objc private func didTapForwardButton(){
        forwardMusic()
    }
    @objc private func didTapBackwardButton(){
        backwardMusic()
    }
    
    func playMusic(){
        playBtn.image = UIImage(systemName: "pause.fill")
        player.play()
        self.isRunningSecond = true
        
    }
    func pauseMusic(){
        playBtn.image = UIImage(systemName: "play.fill")
        isRunningSecond = false
        player.pause()
    }
    
    func forwardMusic(){
        let idx = self.musicViewModel.currentMusicIndex.value
        isRunningSecond = false
        player.pause()
        self.musicViewModel.currentMusicIndex.accept(idx == self.playList.count-1 ? 0 : idx+1)
        configure()
    }
    
    func backwardMusic(){
        let idx = self.musicViewModel.currentMusicIndex.value
        isRunningSecond = false
        player.pause()
        self.musicViewModel.currentMusicIndex.accept(idx == 0 ? 0 : idx-1)
        configure()
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
        
    }
    
    func remoteCommandInfoCenterSetting(_ music: Music, _ image: UIImage) {
        let center = MPNowPlayingInfoCenter.default()
        var nowPlayingInfo = center.nowPlayingInfo ?? [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = music.name
        nowPlayingInfo[MPMediaItemPropertyArtist] = music.artistName
        nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size, requestHandler: { size in
            return image
        })
        if player != nil {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = player.duration // 콘텐츠 재생 시간에 따른 progressBar 초기화
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = player.rate // 콘텐츠 현재 재생시간
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = player.currentTime
        }
        center.nowPlayingInfo = nowPlayingInfo
        
    }
}
