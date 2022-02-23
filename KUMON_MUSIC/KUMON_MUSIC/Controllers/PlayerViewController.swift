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

let timer = Driver<Int>.interval(.milliseconds(1)).map { _ in
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
    @IBOutlet weak var currentTimeLabel: UILabel!
    @IBOutlet weak var durationTimeLabel: UILabel!
    @IBAction func scrubAudio(_ sender: Any) {
        player.stop()
        player.currentTime = TimeInterval(durationSlider.value)
        player.prepareToPlay()
        player.play()
    }
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
        
        timer.asObservable()
            .subscribe(onNext: { [weak self] value in
                if let self = self, self.player != nil {
                    self.updateTime()
                    self.updateSlider()
                }
            })
            .disposed(by: disposeBag)
        musicViewModel.currentMusicTime
            .subscribe(onNext: { time in
                self.durationSlider.value = self.player == nil ? 0.0 : time/Float(self.player.duration)
                if self.durationSlider.value >= 1.0 {
                    self.durationSlider.value = 0.0
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
                    }
                } else {
                    self.coverImage.image = UIImage(systemName: "playpause.fill")
                }
                
                self.songUrl = Bundle.main.url(forResource: music.trackName, withExtension: "mp3")
                self.titleLabel.text = music.name
                self.artistLabel.text = music.artistName
                self.configure()
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
        let repeatTap = UITapGestureRecognizer(target: self, action: #selector(didTapRepeatButton))
        repeatBtn.addGestureRecognizer(repeatTap)
        repeatBtn.isUserInteractionEnabled = true
        let shuffleTap = UITapGestureRecognizer(target: self, action: #selector(didTapShuffleButton))
        shuffleBtn.addGestureRecognizer(shuffleTap)
        shuffleBtn.isUserInteractionEnabled = true
    }
}

// MARK: - Music Play
extension PlayerViewController{
    func configure(){
        pauseMusic()
        self.musicViewModel.currentMusicTime.accept(0.0)
        if let url = songUrl {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player.volume = 0.5
                durationSlider.maximumValue = Float(player.duration)
                isRunningSecond = true
                let du = Int(self.player.duration)
                let str = String(format: "%02d:%02d", du/60, du%60)
                self.durationTimeLabel.text = str
                playMusic()
            } catch {
                print("error")
            }
        }
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
        currentTimeLabel.text = "00:00"
        forwardMusic()
    }
    @objc private func didTapBackwardButton(){
        if player == nil { return }
        currentTimeLabel.text = "00:00"
        backwardMusic()
    }
    @objc private func didTapRepeatButton(){
        switch self.musicViewModel.repeatCheck.value {
        case 0:
            self.musicViewModel.repeatCheck.accept(1)
            repeatBtn.tintColor = UIColor.label
            repeatBtn.image = UIImage(systemName: "repeat")
        case 1:
            self.musicViewModel.repeatCheck.accept(2)
            repeatBtn.tintColor = UIColor.label
            repeatBtn.image = UIImage(systemName: "repeat.1")
        case 2:
            self.musicViewModel.repeatCheck.accept(0)
            repeatBtn.tintColor = UIColor.gray
            repeatBtn.image = UIImage(systemName: "repeat")
        default:
            return
        }
    }
    @objc private func didTapShuffleButton(){
        if shuffleBtn.tintColor == UIColor.gray{
            shuffleBtn.tintColor = UIColor.label
        } else {
            shuffleBtn.tintColor = UIColor.gray
        }
    }
    func playMusic(){
        if player == nil { return }
        self.isRunningSecond = true
        playBtn.image = UIImage(systemName: "pause.fill")
        player.play()
        try? AVAudioSession.sharedInstance().setActive(true)
        
    }
    func pauseMusic(){
        if player == nil { return }
        isRunningSecond = false
        playBtn.image = UIImage(systemName: "play.fill")
        player.pause()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    func stopMusic(){
        if player == nil { return }
        isRunningSecond = false
        playBtn.image = UIImage(systemName: "play.fill")
        player.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    func updateTime() {
        if player == nil { return }
        let currentTime = Int(player.currentTime)
        let duration = Int(player.duration)
        let total = currentTime - duration
        let totalString = String(total)
        
        let minutes = currentTime/60
        let seconds = currentTime - minutes / 60
        
        currentTimeLabel.text = NSString(format: "%02d:%02d", minutes,seconds) as String
    }
    func updateSlider() {
        if player == nil { return }
        durationSlider.value = Float(player.currentTime)
    }
    
    func forwardMusic(){
        if player == nil { return }
        let id = self.musicViewModel.currentMusicIndex.value
        if self.musicViewModel.repeatCheck.value == 2 {
            self.musicViewModel.currentMusicIndex.accept(id)
        } else {
            let index = self.musicViewModel.musicIndexList.value.firstIndex(of: id)!
            let newId = index == self.musicViewModel.musicIndexList.value.endIndex-1 ? self.musicViewModel.musicIndexList.value[0] : self.musicViewModel.musicIndexList.value[self.musicViewModel.musicIndexList.value.index(after: index)]
            self.musicViewModel.currentMusicIndex.accept(newId)
        }
        isRunningSecond = false
    }
    
    func backwardMusic(){
        if player == nil { return }
        let id = self.musicViewModel.currentMusicIndex.value
        if self.musicViewModel.repeatCheck.value == 2 {
            self.musicViewModel.currentMusicIndex.accept(id)
        } else {
            let index = self.musicViewModel.musicIndexList.value.firstIndex(of: id)!
            let newId = index == self.musicViewModel.musicIndexList.value.startIndex ? self.musicViewModel.musicIndexList.value[self.musicViewModel.musicIndexList.value.count-1] : self.musicViewModel.musicIndexList.value[self.musicViewModel.musicIndexList.value.index(before: index)]
            self.musicViewModel.currentMusicIndex.accept(newId)
        }
        isRunningSecond = false
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
