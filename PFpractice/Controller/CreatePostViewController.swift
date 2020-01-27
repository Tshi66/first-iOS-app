//
//  CreatePostViewController.swift
//  PFpractice
//
//  Created by 渡辺崇博 on 2019/11/18.
//  Copyright © 2019 渡辺崇博. All rights reserved.
//

import UIKit
import RealmSwift
import Validator
import Loaf
import CropViewController

class CreatePostViewController: UIViewController, UINavigationControllerDelegate, UITextFieldDelegate, ContentScrollable {
    
    //MARC: Properties
    @IBOutlet weak var themeIcon: UILabel!
    @IBOutlet weak var presentIcon: UILabel!
    @IBOutlet weak var dateIcon: UILabel!
    @IBOutlet weak var budgetIcon: UILabel!
    @IBOutlet weak var backImageView: UIImageView!
    @IBOutlet weak var heroImageView: UIImageView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var themeTextField: UITextField!
    @IBOutlet weak var presentTextField: UITextField!
    @IBOutlet weak var dateTextField: UITextField!
    @IBOutlet weak var budgetTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var nameVdLabel: UILabel!
    @IBOutlet weak var themeVdLabel: UILabel!
    @IBOutlet weak var presentVdLabel: UILabel!
    @IBOutlet weak var dateVdLabel: UILabel!
    @IBOutlet weak var budgetVdLabel: UILabel!
    
    var heroImage:UIImage?
    var backImgae:UIImage?
    var tapId:String = ""
    var datePicker = UIDatePicker()
    let realm = try! Realm()
    var croppingStyle = CropViewCroppingStyle.default
    //ユニークなIdを付与する
    var post = Post.create()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //FAアイコン。
        iconSetToLabel()
        
        hideKeyboardWhenTappedAround()
        
        nameTextField.delegate = self
        themeTextField.delegate = self
        presentTextField.delegate = self
        dateTextField.delegate = self
        budgetTextField.delegate = self
        
        setDatePicker()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //ContentScrollable監視開始
        configureObserver()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //ContentScrollable監視終了
        removeObserver()
        
    }
    
    @objc func done() {
        dateTextField.endEditing(true)
        
        // 日付のフォーマット
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        dateTextField.text = "\(formatter.string(from: datePicker.date))"
    }
    
    //MARC: IBAction
    
    @IBAction func createPostButton(_ sender: UIButton) {
        
        validateTextField()
        
        guard nameVdLabel.text == "ok" && themeVdLabel.text == "ok" && presentVdLabel.text == "ok" && dateVdLabel.text == "ok" && budgetVdLabel.text == "ok" else {
            
            Loaf("ポストが作成されませんでした。", state: .error, location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
            
            return
        }
        
        saveAlert()
        
    }
    
    @IBAction func backTapGesture(_ sender: UITapGestureRecognizer) {
        setImgPicker()
        tapId = "backImage"
    }
    @IBAction func heroTapGesture(_ sender: UITapGestureRecognizer) {
        setImgPicker()
        tapId = "heroImage"
    }
    private func setImgPicker(){
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    internal func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    private func iconSetToLabel(){
        
        fontAwesomeIconSet(iconLabel: themeIcon, iconName: .fontAwesomeIcon(name: .heart))
        fontAwesomeIconSet(iconLabel: presentIcon, iconName: .fontAwesomeIcon(name: .gem))
        fontAwesomeIconSet(iconLabel: dateIcon, iconName: .fontAwesomeIcon(name: .calendarAlt))
        fontAwesomeIconSet(iconLabel: budgetIcon, iconName: .fontAwesomeIcon(name: .moneyBillAlt))
        
    }
    
    private func fontAwesomeIconSet(iconLabel: UILabel, iconName: String) {
        let font = UIFont.fontAwesome(ofSize: 20.0, style: .regular)
        let color = AppTheme().mainColor
        let fontAwesomeIcon = iconName
        
        iconLabel.font = font
        iconLabel.text = fontAwesomeIcon
        iconLabel.textColor = color
    }
    
    private func setDatePicker() {
        datePicker.datePickerMode = UIDatePicker.Mode.date
        datePicker.timeZone = NSTimeZone.local
        datePicker.locale = Locale.current
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 40))
        let spacelItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let doneItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        toolbar.setItems([spacelItem, doneItem], animated: true)
        
        dateTextField.inputView = datePicker
        dateTextField.inputAccessoryView = toolbar
        
    }
    
    private func realmAddPost(post: Post){
        do {
            try realm.write {
                realm.add(post)
            }
        } catch {
            print("Error saving post \(error)")
        }
    }
    
    private func saveAlert(){
        let alert = UIAlertController(title: "ポストを新規作成しますか？", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "作成", style: .default) { (action) in
            
            self.inputContentToPost()
            
            //1つ前の画面に戻る
            self.navigationController?.popViewController(animated: false)
            
            //Loafでメッセージ表示
            self.loafOfCreated()
            
            //postをrealmに保存
            self.realmAddPost(post: self.post)
        }
        
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel) { (action: UIAlertAction!) in
        }
        
        alert.addAction(action)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    private func loafOfCreated() {
        
        let image = self.post.photo
        let name = self.post.name
        Loaf("\(String(describing: name))のポストを作成しました。", state: .custom(.init(backgroundColor: .systemGreen, icon: image)), location: .top, presentingDirection: .vertical, dismissingDirection: .vertical, sender: self).show()
    }
    
    private func inputContentToPost() {
        
        post.name = self.nameTextField.text ?? ""
        post.theme = self.themeTextField.text ?? ""
        post.present = self.presentTextField.text ?? ""
        post.date = self.dateTextField.text ?? ""
        post.budget = Int(self.budgetTextField.text ?? "") ?? 0
        post.backImage = self.backImageView.image
        post.photo = self.heroImageView.image
    }
    
    private func validateTextField() {
        
        //空白文字が含むとエラー
        let stringRule = ValidationRulePattern(pattern: "^[\\S]+$", error: ExampleValidationError("空白等は含めないで下さい"))
        //数字以外はエラー
        let budgetRule = ValidationRulePattern(pattern: "^[\\d]+$", error: ExampleValidationError("金額を入力して下さい"))
        //20../../..の型でないとエラー
        let dateRule = ValidationRulePattern(pattern: "20../../..", error: ExampleValidationError("日付を入力して下さい"))
        
        applyRuleToTF(textField: nameTextField, rule: stringRule, VDLabel: nameVdLabel)
        applyRuleToTF(textField: themeTextField, rule: stringRule, VDLabel: themeVdLabel)
        applyRuleToTF(textField: presentTextField, rule: stringRule, VDLabel: presentVdLabel)
        applyRuleToTF(textField: dateTextField, rule: dateRule, VDLabel: dateVdLabel)
        applyRuleToTF(textField: budgetTextField, rule: budgetRule, VDLabel: budgetVdLabel)
        
    }
    
    private func applyRuleToTF(textField: UITextField, rule: ValidationRulePattern, VDLabel: UILabel) {
        
        let validateTF = textField.validate(rule: rule)
        reflectValidateResalut(result: validateTF, label: VDLabel)
    }
    
    private func reflectValidateResalut(result: ValidationResult, label: UILabel) {
        switch result {
        case .valid:
            label.text = "ok"
        case .invalid(let failures):
            label.text = (failures.first as? ExampleValidationError)?.message
        }
    }
    
}

extension CreatePostViewController: UIImagePickerControllerDelegate, CropViewControllerDelegate{
    
    internal func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
        
    }
    
    internal func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let pickerImage = (info[UIImagePickerController.InfoKey.originalImage] as? UIImage) else { return }
        
        //pickerで取得したUIImageのデータサイズをカットする。（realmが5MB以下対応だから）
        let resizedImage:UIImage = pickerImage.resized(withPercentage: 0.3)!
                
        croppingStyle = {
            
            tapId == "heroImage" ? .circular : .default

        }()
        
        let cropController = CropViewController(croppingStyle: croppingStyle, image: resizedImage)
        cropController.delegate = self
             
        if croppingStyle == .circular {
            
            cropController.title = "プロフィール画像"
            
        } else {
            
            cropController.customAspectRatio = backImageView.frame.size
            cropController.aspectRatioPickerButtonHidden = true
            cropController.resetAspectRatioEnabled = false
            cropController.rotateButtonsHidden = true
            cropController.cropView.cropBoxResizeEnabled = false
            cropController.title = "背景画像"
        }
        
        picker.dismiss(animated: true) {
            
            self.present(cropController, animated: true, completion: nil)
            
        }
    }
    
    internal func cropViewController(_ cropViewController: CropViewController, didCropToCircularImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    internal func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        updateImageViewWithImage(image, fromCropViewController: cropViewController)
    }
    
    private func updateImageViewWithImage(_ image: UIImage, fromCropViewController cropViewController: CropViewController) {
        
        if tapId == "heroImage" {
            
            self.heroImageView.image = image
            
        } else {
            
            self.backImageView.image = image
        }
        
        cropViewController.dismiss(animated: true, completion: nil)
    }
}
