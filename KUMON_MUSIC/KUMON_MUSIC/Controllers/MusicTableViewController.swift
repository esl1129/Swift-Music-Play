//
//  MusicTableViewController.swift
//  KUMON_MUSIC
//
//  Created by mcnc on 2022/02/21.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa

class MusicTableViewController: UITableViewController {
    let musicViewModel = MusicViewModel()
    let disposeBag = DisposeBag()
    var touchX: CGFloat = 0.0
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = nil
        tableView.dataSource = nil
        setUp()
    }
    
}

extension MusicTableViewController{
    func setUp() {
        searchBar.rx.text.orEmpty
            .debounce(RxTimeInterval.microseconds(5), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .asDriver(onErrorJustReturn: "")
            .drive(self.musicViewModel.searchMusic)
            .disposed(by: disposeBag)
        
        musicViewModel.musicData
            .drive(tableView.rx.items(cellIdentifier: "allMusicCell")){ _, music, cell in
                if self.musicViewModel.musicIndexList.value.contains(music.index) {
                    cell.imageView?.image = UIImage(systemName: "play.fill")
                } else {
                    cell.imageView?.image = UIImage(systemName: "play")
                }
                cell.textLabel?.text = music.name
                cell.detailTextLabel?.text = music.artistName
            }
            .disposed(by: disposeBag)
        tableView.rx.modelSelected(Music.self)
            .subscribe(onNext: { model in
                print(model.name)
                var value = self.musicViewModel.musicIndexList.value
                if value.contains(model.index) {
                    value.remove(at: value.firstIndex(of: model.index)!)
                    self.musicViewModel.musicIndexList.accept(value)
                } else {
                    value.append(model.index)
                    self.musicViewModel.musicIndexList.accept(value)
                }
                print(self.musicViewModel.musicIndexList.value)
            })
            .disposed(by: disposeBag)
    }
}

