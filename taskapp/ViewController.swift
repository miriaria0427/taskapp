//
//  ViewController.swift
//  taskapp
//
//  Created by mayuka on 2018/05/23.
//  Copyright © 2018年 miriaria0427. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController,UITableViewDelegate,UITableViewDataSource,UISearchBarDelegate{

    @IBOutlet weak var TableView: UITableView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    
    //Realmのインスタンスを取得する
    let realm = try! Realm()
    
    //DB内でタスクが格納されるリスト
    // 日付近い順\順でソート：降順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try!Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        TableView.delegate = self
        TableView.dataSource = self
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.tintColor = UIColor.red
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UITableViewDataSourceプロトコルのメソッド
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    // 各セルの内容を返すメソッド　(行数分実行される)
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = TableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        //cellに値を設定する
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        
        //日付の表示形式を指定
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        //テーブルに登録されている日付のデータをstring型に変換して表示
        let dateString:String = formatter.string(from:task.date)
        cell.detailTextLabel?.text = dateString
        
        return cell
    }
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //セルをタップした時にタスク作成/編集画面に遷移する
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    // セルが削除が可能なことを伝えるメソッド
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCellEditingStyle {
        return .delete
    }
    
    //検索ボタンを押した時に呼ばれるメソッド
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar){
        self.view.endEditing(true)
       //検索結果を配列に格納してTableViewを更新させる
        self.taskArray = try!Realm().objects(Task.self).filter("category CONTAINS[c] %@", searchBar.text!)
        TableView.reloadData()
    }
    
    //検索バーのキャンセルボタンが押された時に呼ばれるメソッド
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar){
        self.view.endEditing(true)
        searchBar.text = ""
        //元の全てのデータを表示させる
        self.taskArray = realm.objects(Task.self)
        
        TableView.reloadData()
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // 削除されたタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(self.taskArray[indexPath.row])
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }

    // segueで画面遷移する時に呼ばれる
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        // segueのidentifierが"cellSegue"の場合は配列から該当するTaskクラスのインスタンスの内容を反映する。(セルタップ）
        if segue.identifier == "cellSegue" {
            let indexPath = self.TableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            //segueのidentifierが"cellSegue"でない場合、すでに存在しているタスクIDのうち最大のものを取得して＋１する。(＋タップ)
            let task = Task() //タスクのインスタンス生成
            task.date = Date() //現在時刻を取得
            
            let taskArray = realm.objects(Task.self) //タスクテーブルの全レコードの配列を取得
            if taskArray.count != 0 {
                task.id = taskArray.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
        
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        TableView.reloadData()
        }
}

