import UIKit
import FirebaseAuth
import FirebaseFirestore

struct ConversationSummary {
    let id: String
    let otherUserId: String?
    let otherUserName: String
    let lastMessage: String
    let lastMessageTime: Date?
}

class TinNhanVC: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var emptyStateView: UIView!

    private var conversations: [ConversationSummary] = []
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm dd/MM"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        loadMessages()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 76
        tableView.separatorStyle = .none
        tableView.allowsSelection = true
        tableView.isUserInteractionEnabled = true
        tableView.register(TinNhanCell.self, forCellReuseIdentifier: "TinNhanCell")
    }

    private func loadMessages() {
        guard let userId = Auth.auth().currentUser?.uid else {
            showEmptyState()
            return
        }

        activityIndicator.startAnimating()
        tableView.isHidden = true
        emptyStateView.isHidden = true

        let db = Firestore.firestore()
        db.collection("Conversations").whereField("participants", arrayContains: userId).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            guard let docs = snapshot?.documents, error == nil, !docs.isEmpty else {
                self.conversations = []
                self.showEmptyState()
                return
            }

            let rawConversations = docs.map { doc -> ConversationSummary in
                let data = doc.data()
                let participants = data["participants"] as? [String] ?? []
                let otherUserId = participants.first(where: { $0 != userId })
                let lastMessage = data["lastMessage"] as? String ?? "Bắt đầu cuộc trò chuyện"
                let lastMessageTime = (data["lastMessageTime"] as? Timestamp)?.dateValue()
                return ConversationSummary(
                    id: doc.documentID,
                    otherUserId: otherUserId,
                    otherUserName: "Đang tải...",
                    lastMessage: lastMessage,
                    lastMessageTime: lastMessageTime
                )
            }

            self.resolveParticipantNames(for: rawConversations)
        }
    }

    private func resolveParticipantNames(for rawConversations: [ConversationSummary]) {
        let db = Firestore.firestore()
        var resolvedConversations = rawConversations
        let group = DispatchGroup()

        for (index, conversation) in rawConversations.enumerated() {
            guard let otherUserId = conversation.otherUserId else {
                resolvedConversations[index] = ConversationSummary(
                    id: conversation.id,
                    otherUserId: nil,
                    otherUserName: "Người dùng không xác định",
                    lastMessage: conversation.lastMessage,
                    lastMessageTime: conversation.lastMessageTime
                )
                continue
            }

            group.enter()
            db.collection("Users").document(otherUserId).getDocument { document, _ in
                let data = document?.data()
                let resolvedName =
                    (data?["hoTen"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    ? (data?["hoTen"] as? String ?? "Người dùng")
                    : (data?["tenDangNhap"] as? String ?? "Người dùng")

                resolvedConversations[index] = ConversationSummary(
                    id: conversation.id,
                    otherUserId: otherUserId,
                    otherUserName: resolvedName,
                    lastMessage: conversation.lastMessage,
                    lastMessageTime: conversation.lastMessageTime
                )
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.activityIndicator.stopAnimating()
            self.conversations = resolvedConversations.sorted {
                ($0.lastMessageTime ?? .distantPast) > ($1.lastMessageTime ?? .distantPast)
            }

            if self.conversations.isEmpty {
                self.showEmptyState()
            } else {
                self.tableView.isHidden = false
                self.emptyStateView.isHidden = true
                self.tableView.reloadData()
            }
        }
    }

    private func showEmptyState() {
        activityIndicator.stopAnimating()
        tableView.isHidden = true
        emptyStateView.isHidden = false
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TinNhanCell", for: indexPath) as? TinNhanCell else {
            return UITableViewCell()
        }

        let conversation = conversations[indexPath.row]
        let timeText = conversation.lastMessageTime.map { dateFormatter.string(from: $0) } ?? ""
        cell.configure(
            name: conversation.otherUserName,
            unread: false,
            lastMessage: conversation.lastMessage,
            time: timeText
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatVC") as? ChatVC else {
            return
        }

        chatVC.conversationId = conversation.id
        chatVC.otherUserId = conversation.otherUserId
        chatVC.otherUserName = conversation.otherUserName

        if let navigationController = navigationController {
            navigationController.pushViewController(chatVC, animated: true)
        } else {
            let modalNavigationController = UINavigationController(rootViewController: chatVC)
            modalNavigationController.modalPresentationStyle = .fullScreen
            present(modalNavigationController, animated: true)
        }
    }
}

final class AdminMessagesVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var emptyLabel: UILabel!

    private var conversations: [ConversationSummary] = []
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        loadMessages()
    }

    private func setupAppearance() {
        view.backgroundColor = AdminPalette.background
        emptyLabel.text = "Chưa có hội thoại nào."
        emptyLabel.textColor = AdminPalette.textSecondary
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 96
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        tableView.showsVerticalScrollIndicator = false
        tableView.register(TinNhanCell.self, forCellReuseIdentifier: "TinNhanCell")
    }

    private func loadMessages() {
        guard let userId = Auth.auth().currentUser?.uid else {
            showEmptyState()
            return
        }

        activityIndicator.startAnimating()
        tableView.isHidden = true
        emptyLabel.isHidden = true

        let db = Firestore.firestore()
        db.collection("Conversations").whereField("participants", arrayContains: userId).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            guard let docs = snapshot?.documents, error == nil, !docs.isEmpty else {
                self.conversations = []
                self.showEmptyState()
                return
            }

            let rawConversations = docs.map { doc -> ConversationSummary in
                let data = doc.data()
                let participants = data["participants"] as? [String] ?? []
                let otherUserId = participants.first(where: { $0 != userId })
                let lastMessage = data["lastMessage"] as? String ?? "Bắt đầu cuộc trò chuyện"
                let lastMessageTime = (data["lastMessageTime"] as? Timestamp)?.dateValue()
                return ConversationSummary(
                    id: doc.documentID,
                    otherUserId: otherUserId,
                    otherUserName: "Đang tải...",
                    lastMessage: lastMessage,
                    lastMessageTime: lastMessageTime
                )
            }

            self.resolveParticipantNames(for: rawConversations)
        }
    }

    private func resolveParticipantNames(for rawConversations: [ConversationSummary]) {
        let db = Firestore.firestore()
        var resolvedConversations = rawConversations
        let group = DispatchGroup()

        for (index, conversation) in rawConversations.enumerated() {
            guard let otherUserId = conversation.otherUserId else {
                resolvedConversations[index] = ConversationSummary(
                    id: conversation.id,
                    otherUserId: nil,
                    otherUserName: "Người dùng không xác định",
                    lastMessage: conversation.lastMessage,
                    lastMessageTime: conversation.lastMessageTime
                )
                continue
            }

            group.enter()
            db.collection("Users").document(otherUserId).getDocument { document, _ in
                let data = document?.data()
                let resolvedName =
                    (data?["hoTen"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
                    ? (data?["hoTen"] as? String ?? "Người dùng")
                    : (data?["tenDangNhap"] as? String ?? "Người dùng")

                resolvedConversations[index] = ConversationSummary(
                    id: conversation.id,
                    otherUserId: otherUserId,
                    otherUserName: resolvedName,
                    lastMessage: conversation.lastMessage,
                    lastMessageTime: conversation.lastMessageTime
                )
                group.leave()
            }
        }

        group.notify(queue: .main) {
            self.activityIndicator.stopAnimating()
            self.conversations = resolvedConversations.sorted {
                ($0.lastMessageTime ?? .distantPast) > ($1.lastMessageTime ?? .distantPast)
            }

            self.emptyLabel.isHidden = !self.conversations.isEmpty
            self.tableView.isHidden = self.conversations.isEmpty
            self.tableView.reloadData()
        }
    }

    private func showEmptyState() {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            self.tableView.isHidden = true
            self.emptyLabel.isHidden = false
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        conversations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "TinNhanCell", for: indexPath) as? TinNhanCell else {
            return UITableViewCell()
        }

        let conversation = conversations[indexPath.row]
        let timeText = conversation.lastMessageTime.map { dateFormatter.string(from: $0) } ?? ""
        cell.configure(
            name: conversation.otherUserName,
            unread: false,
            lastMessage: conversation.lastMessage,
            time: timeText
        )
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let conversation = conversations[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        guard let chatVC = storyboard.instantiateViewController(withIdentifier: "ChatVC") as? ChatVC else {
            return
        }

        chatVC.conversationId = conversation.id
        chatVC.otherUserId = conversation.otherUserId
        chatVC.otherUserName = conversation.otherUserName

        let navigationController = UINavigationController(rootViewController: chatVC)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
}
