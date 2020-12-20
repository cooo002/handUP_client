//
//  QuestionDetailViewController.swift
//  handUP_new
//
//  Created by 김재석 on 2020/09/09.
//  Copyright © 2020 김재석. All rights reserved.
//

import UIKit
import Firebase
import FirebaseCore
import FirebaseFirestore

/*
 check
 3. 서버 데이터 cell에 적용 x
 5. 답변 관련 처리 x
 - Notification을 이용해서 데이터 읽어오기
 - Notification Obsever를 이용해서 셀에 적용하기
 - 질문 읽어오는 로직 참고하기
 */

class QuestionDetailViewController: UIViewController {
    var indexPathOfSelectedQuestionCell : Int?
    var questionUID : String?
    var questionInfos : [String:Any]?
    var answerUID : String?
    var answerInfos : [QueryDocumentSnapshot]?
    var numOfTotalCell = 4
    
    @IBOutlet weak var mainCollectionView: UICollectionView!
    
    @IBAction func touchUpToMenu(_ sender: Any) {
    }
    
    @IBAction func touchUpToBack(_ sender: Any) {
        dismiss(animated: false, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("testing -> \(indexPathOfSelectedQuestionCell)")
        print("testing -> \(questionUID)")
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        NotificationCenter.default.addObserver(self, selector: #selector(actionToReloadCollectionVieWhenQuestionInfosRoad), name: .questionInfoDidRoad, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(actinoToPerformSegue(notification:)), name: .actinoToPerformSegue, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(actionToReloadCollectionVieWhenAnswerInfosRoad), name: .answerInfoDidRoad, object: nil)
        
        defer {
            DispatchQueue.global().async { [self] in
                receivedQuestionInfoFromFireStore()
                receivedAnswerInfosFromFireStore()
                //questionInfo 읽어오는 메소드 들어갈 자리
            }
        }
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
    }
    
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "segueForWriteAnswerViewController" {
            var destination = segue.destination as? WriteAnswerViewController
            destination?.questionUid = self.questionUID
            
        }
    }
    
    
}

extension QuestionDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("-collectionView numberOfItemsInSection init-")
        guard var numOfAnserCell = self.answerInfos else{
            return self.numOfTotalCell
        }
        self.numOfTotalCell = self.answerInfos!.count + 2
        
        return self.numOfTotalCell
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("-collectionView cellForItemAt init-")
        var rowOfLastIndexPath = self.numOfTotalCell - 1
        //cell 1(질문)
        if indexPath.row == 0{
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuestionDetailCollectionViewCell", for: indexPath) as? QuestionDetailCollectionViewCell else{
                return UICollectionViewCell()
            }
            var cellTextViewHeight = (cell.labelToQuestionContents.bounds.height)
            var cellTopViewHeight = (cell.viewToTop.bounds.height)
            var cellBottomHeight = (cell.viewToBottom.bounds.height)
            var flexibleSpacing = CGFloat(integerLiteral: 40)
            var cellWidth = collectionView.bounds.width
            let cellHegiht = cellBottomHeight + cellTopViewHeight + cellTextViewHeight + flexibleSpacing
            cell.bounds.size.height = cellHegiht
            guard (questionInfos != nil) else{
                return cell
            }
            
            let keywords = self.questionInfos?["keyword"] as? [String]
            
            cell.labelToQuestionContents.text = self.questionInfos?["contents"] as? String ?? ""
            cell.labelToQuestionHeadLine.text = self.questionInfos?["title"] as? String ?? ""
            cell.labelToNumOfQuestionUserAsking.text = self.questionInfos?["questions"] as? String ?? ""
            cell.labelToQuestionUserID.text = self.questionInfos?["writerEmail"] as? String ?? ""
            cell.labelToDate.text =  self.questionInfos?["date"] as? String ?? ""
            cell.labelToQuestionKeyWordFirst.text = keywords?[0] ?? ""
            cell.labelToQuestionKeyWordSecond.text = keywords?[1] ?? ""
            cell.labelToQuestionKeyWordThird.text = keywords?[2] ?? ""
            return cell
        }//cell 2(연관질문)
        else if indexPath.row == rowOfLastIndexPath{
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuestionDetailRelationCollectionViewCell", for: indexPath) as? QuestionDetailRelationCollectionViewCell else{
                return UICollectionViewCell()
            }
            
            return cell
        }//cell 3(답변)
        else{
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuestionDetailAnswerCollectionViewCell", for: indexPath) as? QuestionDetailAnswerCollectionViewCell else{
                return UICollectionViewCell()
            }
            guard var answerInfosArr = self.answerInfos else{
                print("data checking!!!")
                return cell
            }
            if answerInfosArr.count == 0{
                cell.labelToAnswerUserMajorField.text = ""
                cell.labelToDate.text =  "1시간전"
                cell.labelToAnswerUserID.text = ""
                cell.labelToAnswerContents.text = " "
                cell.buttonClick = {
                    let alert = UIAlertController(title: " 확인", message: "현재 1대1 질문하기 기능은 점검 때문에 사용할 수 없습니다ㅠㅠ", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                return cell
            }
            else{
                var row = indexPath.row - 1
                cell.labelToAnswerUserMajorField.text = "testing"
                cell.labelToDate.text =  answerInfosArr[row]["date"] as? String
                cell.labelToAnswerUserID.text = answerInfosArr[row]["writerEmail"] as? String
                cell.labelToAnswerContents.text =  answerInfosArr[row]["contents"] as? String
                cell.buttonClick = {
                    let alert = UIAlertController(title: " 확인", message: "현재 1대1 질문하기 기능은 점검 때문에 사용할 수 없습니다ㅠㅠ", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                return cell
            }
        }
    }
}

extension QuestionDetailViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {        
        var rowOfLastIndexPath = 3
        var cellWidth = collectionView.bounds.width
        var cellHegiht : CGFloat!
        //cell 1(질문)
        if indexPath.row == 0{
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuestionDetailCollectionViewCell", for: indexPath) as? QuestionDetailCollectionViewCell else{
                fatalError()
            }
            var cellTextViewHeight = (cell.labelToQuestionContents.bounds.height)
            var cellTopViewHeight = (cell.viewToTop.bounds.height)
            var cellBottomHeight = (cell.viewToBottom.bounds.height)
            var flexibleSpacing = CGFloat(integerLiteral: 60)
            cellHegiht = cellTextViewHeight+cellTopViewHeight+cellBottomHeight+flexibleSpacing
        }//cell 2(답변)
        else if indexPath.row == rowOfLastIndexPath{
            cellHegiht = CGFloat(integerLiteral: 300)
        }//cell 3(연관질문)
        else{
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "QuestionDetailAnswerCollectionViewCell", for: indexPath) as? QuestionDetailAnswerCollectionViewCell else{
                fatalError()
            }
            var cellTextViewHeight = (cell.labelToAnswerContents.bounds.height)
            var cellTopViewHeight = (cell.viewToTop.bounds.height)
            var cellBottomHeight = (cell.buttonToIndepthQuestion.bounds.height)
            var flexibleSpacing = CGFloat(integerLiteral: 60)
            cellHegiht = cellTextViewHeight+cellTopViewHeight+cellBottomHeight+flexibleSpacing
        }
        return CGSize(width: cellWidth, height: cellHegiht)
    }
    
}

extension QuestionDetailViewController{
    func returnQuseitonCell(cell: QuestionDetailCollectionViewCell) -> QuestionDetailCollectionViewCell{
        return cell
    }
    
    func returnAnswerCell(cell:  QuestionDetailRelationCollectionViewCell) -> QuestionDetailRelationCollectionViewCell{
        return cell
    }
    
    func returnRelationQuseitonCell(cell: QuestionDetailAnswerCollectionViewCell) -> QuestionDetailAnswerCollectionViewCell{
        return cell
    }
    
}

extension QuestionDetailViewController{
    func receivedQuestionInfoFromFireStore(){
        // questionInfo데이터 땡겨오고, Notification 등록, questionUID
        var db = Firestore.firestore()
        var uid = Auth.auth().currentUser?.uid
        let docRef = db.collection("questions").document(self.questionUID!)
        
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data().map(String.init(describing:)) ?? "nil"
                print("Document data -> \(document.data())")
                NotificationCenter.default.post(name: .questionInfoDidRoad, object: nil, userInfo: ["data":document.data()])
                print("Document data: \(dataDescription)")
            } else {
                print("Document does not exist")
            }
        }
    }
    
    func receivedAnswerInfosFromFireStore(){
        // answerInfos데이터 땡겨오고, Notification 등록, questionUID
        // answerInfos는 답변이 계속 달리니 리스너로 구성!
        var db = Firestore.firestore()
        var uid = Auth.auth().currentUser?.uid
        var reloadAnswerInfosTempArr = [QueryDocumentSnapshot]()
        var documentIDTempArr = [String]()
        var answerDataPath = db.collection("questionRelation").document(self.questionUID!).collection("answer").order(by: "date", descending: false)
        
        answerDataPath.addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            
            print("AnswerInfos Testing  -> \(documents[0])")
            NotificationCenter.default.post(name: .answerInfoDidRoad , object: nil, userInfo: ["answerInfos":documents])
        }
    }
    
    @objc func actionToReloadCollectionVieWhenQuestionInfosRoad(notification: NSNotification){
        // questionInfo 데이터 땡겨오고, Notification 등록
        guard let data = notification.userInfo?["data"] as? [String:Any] else {
            return
        }
        self.questionInfos = data
        
        
        DispatchQueue.main.async {
            // collectionView reload
            self.mainCollectionView.reloadData()
        }
    }
    
    @objc func actionToReloadCollectionVieWhenAnswerInfosRoad(notification: NSNotification){
        // answerInfos 데이터 땡겨오고(Arr로 구성), Notification 등록
        // answerReload 참고
        guard let data = notification.userInfo?["answerInfos"]  as? [QueryDocumentSnapshot] else{
            return
        }
        self.answerInfos = data
        DispatchQueue.main.async {
            self.mainCollectionView.reloadData()
        }
    }
    
    
    @objc func actinoToPerformSegue(notification: NSNotification){
        // 데이터 땡겨오고, Notification 등록
        DispatchQueue.main.async {
            // collectionView reload
            self.performSegue(withIdentifier: "segueForWriteAnswerViewController", sender: nil)
        }
    }
}
