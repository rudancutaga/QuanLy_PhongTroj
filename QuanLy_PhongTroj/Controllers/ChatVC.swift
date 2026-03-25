import UIKit
import FirebaseAuth
import FirebaseFirestore

// Model
struct Message {
    let id: String
    let senderId: String
    let text: String
    let timestamp: Date
}

class MessageCell: UITableViewCell {
    private let bubbleView = UIView()
    private let messageLabel = UILabel()
    
    // Constraints to flip based on sender
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        backgroundColor = .clear
        
        bubbleView.layer.cornerRadius = 16
        bubbleView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(bubbleView)
        
        messageLabel.numberOfLines = 0
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        bubbleView.addSubview(messageLabel)
        
        // Define constraints
        leadingConstraint = bubbleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16)
        trailingConstraint = bubbleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        
        NSLayoutConstraint.activate([
            bubbleView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            bubbleView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            bubbleView.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.75),
            
            messageLabel.topAnchor.constraint(equalTo: bubbleView.topAnchor, constant: 10),
            messageLabel.bottomAnchor.constraint(equalTo: bubbleView.bottomAnchor, constant: -10),
            messageLabel.leadingAnchor.constraint(equalTo: bubbleView.leadingAnchor, constant: 14),
            messageLabel.trailingAnchor.constraint(equalTo: bubbleView.trailingAnchor, constant: -14)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(with message: Message, isCurrentUser: Bool) {
        messageLabel.text = message.text
        
        if isCurrentUser {
            bubbleView.backgroundColor = UIColor(hex: "#FF6600")
            messageLabel.textColor = .white
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
        } else {
            bubbleView.backgroundColor = .systemGray5
            messageLabel.textColor = .label
            trailingConstraint.isActive = false
            leadingConstraint.isActive = true
        }
    }
}

class ChatVC: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    // MARK: - Properties
    var room: PhongTro!
    var conversationId: String?
    var otherUserId: String?
    var otherUserName: String = "Chủ nhà"
    
    private var messages: [Message] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()
    private let currentUserId = Auth.auth().currentUser?.uid ?? ""
    
    // MARK: - IBOutlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var inputContainerView: UIView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var inputBottomConstraint: NSLayoutConstraint!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFromRoom()
        setupUI()
        setupKeyboardObservers()
        if let cid = conversationId {
            listenForMessages(cid: cid)
        }
    }
    
    private func setupFromRoom() {
        guard let room = room else { return }
        self.otherUserId = room.idNguoiDang
        self.title = room.tieuDe
        
        // Tạo conversationId giả định: min(id1, id2) + "_" + max(id1, id2)
        let ids = [currentUserId, room.idNguoiDang].sorted()
        self.conversationId = "\(ids[0])_\(ids[1])" 
    }
    
    private func setupUI() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(MessageCell.self, forCellReuseIdentifier: "MessageCell")
        messageTextField.delegate = self
    }
    
    // MARK: - Keyboard Handling
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func handleKeyboardShow(notification: NSNotification) {
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight = keyboardFrame.cgRectValue.height
            inputBottomConstraint.constant = -keyboardHeight
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
                self.scrollToBottom(animated: false)
            }
        }
    }
    
    @objc private func handleKeyboardHide(notification: NSNotification) {
        inputBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func scrollToBottom(animated: Bool) {
        guard messages.count > 0 else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
    }
    
    // MARK: - Firebase Logic
    private func listenForMessages(cid: String) {
        listener = db.collection("Conversations").document(cid).collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error listening for messages: \(error)")
                    return
                }
                
                guard let docs = snapshot?.documents else { return }
                
                self.messages = docs.compactMap { doc -> Message? in
                    let data = doc.data()
                    guard let senderId = data["senderId"] as? String,
                          let text = data["text"] as? String,
                          let timestamp = data["timestamp"] as? Timestamp else { return nil }
                    return Message(id: doc.documentID, senderId: senderId, text: text, timestamp: timestamp.dateValue())
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.scrollToBottom(animated: true)
                }
            }
    }
    
    @IBAction func handleSend(_ sender: Any? = nil) {
        guard let text = messageTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty,
              let cid = conversationId, let oid = otherUserId else { return }
        
        messageTextField.text = ""
        
        let data: [String: Any] = [
            "senderId": currentUserId,
            "text": text,
            "timestamp": Timestamp()
        ]
        
        // Add message
        let msgRef = db.collection("Conversations").document(cid).collection("messages").document()
        msgRef.setData(data)
        
        // Update conversation abstract
        db.collection("Conversations").document(cid).setData([
            "lastMessage": text,
            "lastMessageTime": Timestamp(),
            "participants": FieldValue.arrayUnion([currentUserId, oid])
        ], merge: true)
    }
    
    // MARK: - TableView Data Source
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        let message = messages[indexPath.row]
        cell.configure(with: message, isCurrentUser: message.senderId == currentUserId)
        return cell
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    deinit {
        listener?.remove()
        NotificationCenter.default.removeObserver(self)
    }
}
