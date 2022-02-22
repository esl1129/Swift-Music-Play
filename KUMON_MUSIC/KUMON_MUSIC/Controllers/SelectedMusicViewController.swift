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


class SelectedMusicViewController: UIViewController {
    
    let musicViewModel = MusicViewModel()
    let disposeBag = DisposeBag()
    @IBOutlet weak var popupMusicView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = nil
        tableView.dataSource = nil
        // popupMusicView.isHidden = true
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
        
//        musicViewModel.currentMusicTime
//            .subscribe(onNext: { time in
//                if time != 0.0 {
//                    self.popupMusicView.isHidden = false
//                }
//            })
//            .disposed(by: disposeBag)
        tableView.rx.modelSelected(Music.self)
            .subscribe(onNext: { music in
                self.musicViewModel.currentMusicIndex = BehaviorRelay<Int>(value: music.index)
                self.performSegue(withIdentifier: "playMusic", sender: music)
            })
            .disposed(by: disposeBag)
        
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
        }
    }
}
