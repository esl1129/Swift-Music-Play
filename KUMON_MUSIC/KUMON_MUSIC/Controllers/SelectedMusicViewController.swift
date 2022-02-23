//
//  SelectedMusicViewController.swift
//  KUMON_MUSIC
//
//  Created by mcnc on 2022/02/22.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import MediaPlayer


class SelectedMusicViewController: UIViewController, AVAudioPlayerDelegate {
    
    let musicViewModel = MusicViewModel()
    let disposeBag = DisposeBag()
    var player: AVAudioPlayer!

    @IBOutlet weak var popupMusicView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var playBtn: UIImageView!
    @IBOutlet weak var forwardBtn: UIImageView!
    @IBAction func changeTheme(_ sender: Any) {
        if let theme = UserDefaults.standard.string(forKey: "theme") {
            UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.overrideUserInterfaceStyle = theme == "dark" ? .light : .dark
        }
        UserDefaults.standard.set(UIApplication.shared.windows.filter{$0.isKeyWindow}.first?.overrideUserInterfaceStyle == .dark ? "dark" : "light" , forKey: "theme")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = nil
        tableView.dataSource = nil
        setUp()
    }
}

extension SelectedMusicViewController{
    func setUp() {
        musicViewModel.selectedMusicData
            .drive(tableView.rx.items(cellIdentifier: "selectedMusicCell")){ _, music, cell in
                cell.textLabel?.text = music.name
                cell.detailTextLabel?.text = music.artistName
            }
            .disposed(by: disposeBag)

        tableView.rx.modelSelected(Music.self)
            .subscribe(onNext: { music in
                    self.performSegue(withIdentifier: "playMusic", sender: music)
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
                    }
                } else {
                    self.coverImage.image = UIImage(systemName: "playpause.fill")
                }
                
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
    }
}


// MARK: - Tap Gesture
extension SelectedMusicViewController {
    @objc private func didTapPlayPauseButton(){
        if player == nil { return }
        if player.isPlaying == true{
            pauseMusic()
        } else {
            playMusic()
        }
    }
    @objc private func didTapForwardButton(){
        forwardMusic()
    }
    func playMusic(){
        if player == nil { return }
        playBtn.image = UIImage(systemName: "pause.fill")
        player.play()
        try? AVAudioSession.sharedInstance().setActive(true)
        
    }
    func pauseMusic(){
        if player == nil { return }
        playBtn.image = UIImage(systemName: "play.fill")
        player.pause()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    func stopMusic(){
        if player == nil { return }
        playBtn.image = UIImage(systemName: "play.fill")
        player.stop()
        try? AVAudioSession.sharedInstance().setActive(false)
    }
    func forwardMusic(){
        // if player == nil { return }
        let id = self.musicViewModel.currentMusicIndex.value
        if self.musicViewModel.repeatCheck.value == 2 {
            self.musicViewModel.currentMusicIndex.accept(id)
        } else {
            let index = self.musicViewModel.musicIndexList.value.firstIndex(of: id)!
            let newId = index == self.musicViewModel.musicIndexList.value.endIndex-1 ? self.musicViewModel.musicIndexList.value[0] : self.musicViewModel.musicIndexList.value[self.musicViewModel.musicIndexList.value.index(after: index)]
            self.musicViewModel.currentMusicIndex.accept(newId)
        }
    }
}
extension SelectedMusicViewController{
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "playMusic"{
            guard let music = sender as? Music else {
                return
            }
            let vc = segue.destination as! PlayerViewController
            vc.musicViewModel.currentMusicIndex = BehaviorRelay<Int>(value: music.index)
            self.popupMusicView.isHidden = false
        }
    }
}
