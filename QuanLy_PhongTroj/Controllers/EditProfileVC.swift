import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class EditProfileVC: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var avatarImg: UIImageView!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var phoneTF: UITextField!
    @IBOutlet weak var saveBtn: UIButton!
    
    private var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUserData()
    }
    
    private func setupUI() {
        avatarImg.layer.cornerRadius = 50
        avatarImg.clipsToBounds = true
        avatarImg.contentMode = .scaleAspectFill
        avatarImg.backgroundColor = .systemGray6
        
        saveBtn.layer.cornerRadius = 12
    }
    
    private func loadUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("Users").document(uid).getDocument { [weak self] doc, _ in
            guard let self = self, let data = doc?.data() else { return }
            self.nameTF.text = data["hoTen"] as? String
            self.phoneTF.text = data["soDienThoai"] as? String
            
            if let avatarUrl = data["avatarUrl"] as? String, let url = URL(string: avatarUrl) {
                // Tải ảnh đơn giản (trong thực tế nên dùng SDWebImage)
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.avatarImg.image = image
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func changeAvatarTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // MARK: - Picker Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            avatarImg.image = image
            selectedImage = image
        }
        dismiss(animated: true)
    }
    
    @IBAction func saveTapped(_ sender: UIButton) {
        guard let uid = Auth.auth().currentUser?.uid,
              let name = nameTF.text, !name.isEmpty else { return }
        
        saveBtn.isEnabled = false
        saveBtn.setTitle("Đang lưu...", for: .normal)
        
        if let image = selectedImage {
            uploadAvatar(image: image, uid: uid) { [weak self] url in
                self?.updateFirestore(uid: uid, name: name, phone: self?.phoneTF.text ?? "", avatarUrl: url)
            }
        } else {
            updateFirestore(uid: uid, name: name, phone: phoneTF.text ?? "")
        }
    }
    
    private func uploadAvatar(image: UIImage, uid: String, completion: @escaping (String?) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            completion(nil)
            return
        }
        
        let ref = Storage.storage().reference().child("avatars").child("\(uid).jpg")
        ref.putData(data, metadata: nil) { metadata, error in
            if error != nil {
                completion(nil)
                return
            }
            ref.downloadURL { url, _ in
                completion(url?.absoluteString)
            }
        }
    }
    
    private func updateFirestore(uid: String, name: String, phone: String, avatarUrl: String? = nil) {
        var values: [String: Any] = [
            "hoTen": name,
            "soDienThoai": phone
        ]
        
        if let url = avatarUrl {
            values["avatarUrl"] = url
        }
        
        Firestore.firestore().collection("Users").document(uid).updateData(values) { [weak self] err in
            self?.saveBtn.isEnabled = true
            self?.saveBtn.setTitle("Cập nhật", for: .normal)
            
            if err == nil {
                let alert = UIAlertController(title: "Thành công", message: "Hồ sơ đã được cập nhật", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
                    self?.dismiss(animated: true)
                }))
                self?.present(alert, animated: true)
            }
        }
    }
    
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }
}
