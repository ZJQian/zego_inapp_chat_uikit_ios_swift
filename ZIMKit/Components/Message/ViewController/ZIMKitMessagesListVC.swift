//
//  ConversationListVC.swift
//  ZIMKitConversation
//
//  Created by Kael Ding on 2022/7/29.
//

import UIKit
import ZIM
import SwiftyUserDefaults

let tableHeaderHeight = 40.0

class ZIMKitMessagesListVC: _ViewController {
    
    private var userDetailInfoModel: UserDetailInfoModel?
    
    var onClickChatBarHandleType: ((_ chatBar: ChatBar, _ handleType: ChatHandleType) -> Void)?
    var onUserDetailLoadCompletion: ((UserDetailInfoModel?) -> Void)?
    
    
    lazy var viewModel = MessageListViewModel(conversationID: conversationID, conversationType)
    
    public weak var delegate: ZIMKitMessagesListVCDelegate?

    public var conversationID: String = ""
    public var conversationName: String = ""
    public var conversationType: ZIMConversationType = .peer
    weak var chatP2pViewController: ChatP2PViewController?

    var firstHistoryMessageViewModel: MessageViewModel?
    
    private var isLoadMessageList = false
    var isCustomerService: Bool {
        return conversationID == "10086"
    }
    private var replyCountdown: Int = 0
    private var replyTimer: Timer?

    /// Create a session page VC first, then you can create a session page by pushing or presenting the VC.
    /// - Parameters:
    ///   - conversationID: session ID.
    ///   - type: session type.
    ///   - conversationName: session name.
    convenience init(conversationID: String,
                            type: ZIMConversationType,
                            conversationName: String = "") {
        self.init()
        self.conversationID = conversationID
        self.conversationName = conversationName
        self.conversationType = type
    }

    lazy var zoomTransitionController = ZoomTransitionController()

    lazy var indicatorView: UIActivityIndicatorView = {
        let indicatorView = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: tableHeaderHeight))
        if #available(iOS 13.0, *) {
            indicatorView.style = .medium
        } else {
            indicatorView.style = .gray
        }
        return indicatorView
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView().withoutAutoresizingMaskConstraints
        tableView.separatorStyle = .none
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 0.0
        tableView.estimatedSectionFooterHeight = 0.0
        tableView.estimatedSectionHeaderHeight = 0.0
        tableView.contentInset = UIEdgeInsets(top: 16.0, left: 0, bottom: 60, right: 0)
        tableView.backgroundColor = .background2
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = indicatorView

        tableView.register(TextMessageCell.self, forCellReuseIdentifier: TextMessageCell.reuseId)
        tableView.register(GiftMessageCell.self, forCellReuseIdentifier: GiftMessageCell.reuseId)
        tableView.register(CallMessageCell.self, forCellReuseIdentifier: CallMessageCell.reuseId)
        tableView.register(FollowMessageCell.self, forCellReuseIdentifier: FollowMessageCell.reuseId)
        tableView.register(SystemMessageCell.self, forCellReuseIdentifier: SystemMessageCell.reuseId)
        tableView.register(ImageMessageCell.self, forCellReuseIdentifier: ImageMessageCell.reuseId)
        tableView.register(AudioMessageCell.self, forCellReuseIdentifier: AudioMessageCell.reuseId)
        tableView.register(VideoMessageCell.self, forCellReuseIdentifier: VideoMessageCell.reuseId)
        tableView.register(FileMessageCell.self, forCellReuseIdentifier: FileMessageCell.reuseId)
        tableView.register(UnknownMessageCell.self, forCellReuseIdentifier: UnknownMessageCell.reuseId)

        let tap = UITapGestureRecognizer(target: self, action: #selector(tap(_:)))
        tableView.addGestureRecognizer(tap)

        return tableView
    }()

    lazy var chatBar: ChatBar = {
        let chatBar = ChatBar().withoutAutoresizingMaskConstraints
        chatBar.delegate = self
        return chatBar
    }()

    lazy var optionsView: MessageOptionsView = {
        let optionsView = MessageOptionsView(frame: view.bounds)
            .withoutAutoresizingMaskConstraints
        optionsView.delegate = self
        return optionsView
    }()

    lazy var audioPlayer = MessageAudioPlayer(with: tableView)
    
    open override func setUp() {
        super.setUp()

        view.backgroundColor = .background2
    }

    open override func setUpLayout() {
        super.setUpLayout()

        // we need add tableView first,
        // or the navigationbar will change to translucent on ios 15.
        view.addSubview(tableView)
        view.addSubview(chatBar)
        
        chatBar.pin(anchors: [.left, .right, .bottom], to: view)
        tableView.pin(anchors: [.left, .right, .top], to: view)
        tableView.bottomAnchor.pin(equalTo: chatBar.topAnchor, constant: 54).isActive = true
        
        if isCustomerService {
            chatBar.chatHandleBar.isHidden = true
        } else {
            chatBar.chatHandleBar.isHidden = false
        }
    }

    open override func updateContent() {
        super.updateContent()

    }

    func setupNav() {
        if conversationName.count > 0 {
            navigationItem.title = conversationName
        } else {
            let name = conversationType == .peer ?
                L10n("message_title_chat") :
                L10n("message_title_group_chat")
            navigationItem.title = name
        }

        let leftButton = UIButton(type: .custom)
        if viewModel.isShowCheckBox {
            leftButton.setTitle(L10n("conversation_cancel"), for: .normal)
            leftButton.setTitleColor(.zim_textBlack1, for: .normal)
        } else {
            leftButton.setImage(loadImageSafely(with: "chat_nav_left"), for: .normal)
        }
        leftButton.addTarget(self, action: #selector(leftItemClick), for: .touchUpInside)
        leftButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        leftButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        if !viewModel.isShowCheckBox {
            leftButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: -20, bottom: 0, right: 0)
        }
        let leftItem = UIBarButtonItem(customView: leftButton)
        self.navigationItem.leftBarButtonItem = leftItem

        if conversationType == .group {
            let rightButton = UIButton(type: .custom)
            rightButton.setImage(loadImageSafely(with: "chat_nav_right"), for: .normal)
            rightButton.addTarget(self, action: #selector(rightItemClick(_:)), for: .touchUpInside)
            rightButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
            rightButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
            let rightItem = UIBarButtonItem(customView: rightButton)
            navigationItem.rightBarButtonItem = viewModel.isShowCheckBox ? nil : rightItem
        }
    }

    open override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        configViewModel()
        
        let group = DispatchGroup()
        getMessageList(group: group)
        getUserInfo(group: group)
        group.notify(queue: DispatchQueue.main) { [weak self] in
            self?.sendSystemMessage()
        }
        addNotifications()
        setupNav()
        getMsgReservationWordList()
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadMsgReservationWord), name: MCNoti.handleMsgReservationWordSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notReceiveMessageReply(_ :)), name: MCNoti.notReceiveMessageReply, object: nil)
    }
    
    @objc func reloadMsgReservationWord() {
        getMsgReservationWordList()
    }
    
    @objc func notReceiveMessageReply(_ noti: Notification) {
        
        guard UserManager.user?.genderEnum == .male else { return }
        let isReply = noti.object as? Bool ?? false
        if isReply {
            self.stopTimer()
        } else {
            self.startTimer()
        }
    }
    
    func startTimer() {
        stopTimer()
        replyTimer = Timer(timeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self else { return }
            self.replyCountdown += 1
            if self.replyCountdown > 10 {
                //发送送礼物消息
                ZIMKitCore.shared.sendMCSystemMessage("Send her a gift, maybe she will reply".localized, router: MCRouterType.sendGift, to: self.conversationID)
                self.stopTimer()
            }
        })
        RunLoop.main.add(replyTimer!, forMode: .common)
    }
    
    func stopTimer() {
        
        self.replyCountdown = 0
        if let replyTimer {
            replyTimer.invalidate()
            self.replyTimer = nil
        }
    }
    
    
    func getMsgReservationWordList() {
        API.MsgReservationWord.list.fetch(modelType: [ChatPreTextModel].self).success { [weak self] response in
            guard let self else { return }
            self.chatBar.preTextView.setDataList(response.data ?? [], conversationId: self.conversationID)
        }
    }

    deinit {
        removeNotifications()
    }

    open override func willMove(toParent parent: UIViewController?) {
        super.willMove(toParent: parent)
        if parent == nil {
            viewModel.clearConversationUnreadMessageCount()
        }
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioPlayer.stop()
        chatBar.resignFirstResponder()
    }

    // observe viewmodel's properties
    func configViewModel() {
        viewModel.$isReceiveNewMessage.bind { [weak self] _ in
            self?.tableView.reloadData()
            self?.scrollToBottom(true)
            self?.hideOptionsView()
        }
        viewModel.$isSendingNewMessage.bind { [weak self] _ in
            self?.tableView.reloadData()
        }
//        viewModel.$deleteMessages.bind { [weak self] messages in
//            if messages.count == 0 { return }
//            self?.deleteMessages(messages)
//        }
        viewModel.$connectionEvent.bind { [weak self] event in
            if event == .kickedOut {
                self?.chatBar.cancelRecord()
                self?.hideOptionsView()
            }
        }
        viewModel.$isHistoryMessageLoaded.bind { [weak self] _ in
            guard let self  = self else { return }
            if self.viewModel.isNoMoreMsg {
                self.indicatorView.h = 0
            } else {
                self.indicatorView.h = tableHeaderHeight
            }
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            
            guard let lastMessageViewModel = self.firstHistoryMessageViewModel else { return }

            var visibleHeight = 0.0
            for msgViewModel in self.viewModel.messageViewModels {
                if msgViewModel === lastMessageViewModel { break }
                visibleHeight += msgViewModel.cellHeight
            }

            if self.viewModel.isNoMoreMsg {
                visibleHeight -= tableHeaderHeight
            }
            if !lastMessageViewModel.isShowTime {
                visibleHeight -= 32.5
            }
            let contentY = visibleHeight - self.tableView.safeAreaInsets.top - self.tableView.contentInset.top
            self.tableView.setContentOffset(CGPoint(x: 0, y: contentY), animated: false)
        }
    }
    
    func getUserInfo(group: DispatchGroup) {
        group.enter()
        let params = ["accountId": conversationID]
        API.User.userDetail.fetch(params,modelType: UserDetailInfoModel.self).success { [weak self] response in
            guard let self else { return }
            self.userDetailInfoModel = response.data
            self.onUserDetailLoadCompletion?(response.data)
            group.leave()
        }.failed { error in
            group.leave()
        }
    }
    
    func getMessageList(group: DispatchGroup? = nil) {
        
        group?.enter()
        viewModel.getMessageList { [weak self] error in
            guard let self  = self else { return }
            
            group?.leave()
            self.indicatorView.stopAnimating()
            if error.code != .success {
                HUDHelper.showErrorMessageIfNeeded(error.code.rawValue, defaultMessage: error.message)
                return
            }
            if self.viewModel.isNoMoreMsg {
                self.indicatorView.h = 0
            } else {
                self.indicatorView.h = tableHeaderHeight
            }
            
            if self.viewModel.messageViewModels.count == 0 {
                ZIMKitCore.shared.sendTextMessage("👋", to: self.conversationID, type: .peer)
            }
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
            self.scrollToBottom(false)
            self.showOrHideChatBar()
            self.isLoadMessageList = true
            
        }
    }
    
    func showOrHideChatBar() {
        
        let list = viewModel.messageViewModels.filter { vm in
            vm.message.textContent.isMCSystemMessage
        }
        if list.count > 0 {
            chatBar.isHidden = true
            tableView.bottomAnchor.pin(equalTo: chatBar.topAnchor).isActive = false
            tableView.bottomAnchor.pin(equalTo: view.bottomAnchor).isActive = true
            chatP2pViewController?.reloadUI(hideMoreButton: true)
        }
        
        if isCustomerService {
            chatP2pViewController?.reloadUI(hideMoreButton: true)
        }
    }

    func loadMoreMessages() {

        if viewModel.isLoadingData { return }

        if viewModel.isNoMoreMsg {
            indicatorView.stopAnimating()
            return
        }

        firstHistoryMessageViewModel = viewModel.messageViewModels.first
        let nextMessage = viewModel.messageViewModels.first?.message.zim
        viewModel.loadMoreMessages(nextMessage) { [weak self] error in
            self?.indicatorView.stopAnimating()
            if error.code != .success {
                HUDHelper.showErrorMessageIfNeeded(error.code.rawValue, defaultMessage: error.message)
                return
            }
        }
    }
    
    func sendSystemMessage() {
        
        guard let model = userDetailInfoModel else { return }
        guard isLoadMessageList else { return }
        guard !isCustomerService else { return }
        guard !MCIMManager.shared.haveSendAuthSystemMessage(to: conversationID) else { return }
        
        for vm in self.viewModel.messageViewModels {
            if vm.message.type == .system {
                return
            }
            if vm.message.textContent.isMCSystemMessage {
                return
            }
            if vm.message.textContent.isZegoSystemMessage {
                return
            }
        }
        //女性是否认证过（真人认证过或平台认证过）
        var auth = false
        if model.gender == .male {
            if UserManager.user?.realPersonAuth == true || UserManager.user?.platformAuth == true {
                auth = true
            } else {
                auth = false
            }
        } else {
            if model.realPersonAuth == true || model.platformAuth {
                auth = true
            }
        }
        
        if model.gender == .male {
            //对方是男性
            if !auth {
                ZIMKitCore.shared.sendMCSystemMessage("The income is halved before passing the authentication.", router: .certifiy, to: conversationID)
                MCIMManager.shared.saveSendAuthSystemMessageUserList(conversationID)
            }
            
        } else {
            //对方是女性
            if auth {
                ZIMKitCore.shared.sendMCSystemMessage("\(model.nickName~) has been authenticated, just make friends with confidence.".localized, to: conversationID)
                
            } else {
                ZIMKitCore.shared.sendMCSystemMessage("\(model.nickName~) has not been authenticated, please be cautious when making friends.".localized, to: conversationID)
            }
            
            MCIMManager.shared.saveSendAuthSystemMessageUserList(conversationID)
        }
    }
}

// MARK: - Actions
extension ZIMKitMessagesListVC {
    @objc func leftItemClick(_ btn: UIButton) {
        if viewModel.isShowCheckBox {
            enableMultiSelect(false)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    @objc func rightItemClick(_ btn: UIButton) {
        let groupDetailVC = GroupDetailVC(conversationID, conversationName)
        self.navigationController?.pushViewController(groupDetailVC, animated: true)
    }

    @objc func tap(_ tap: UITapGestureRecognizer?) {
        chatBar.resignFirstResponder()
    }
}

// MARK: - TableView
extension ZIMKitMessagesListVC: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.messageViewModels.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if indexPath.row >= viewModel.messageViewModels.count {
            return MessageCell()
        }

        let messageVM = viewModel.messageViewModels[indexPath.row]
        messageVM.isShowCheckBox = viewModel.isShowCheckBox

        let cell = self.tableView.dequeueReusableCell(withIdentifier: messageVM.reuseIdentifier, for: indexPath) as! MessageCell

        cell.messageVM = messageVM
        cell.delegate = self

        return cell
    }
    
    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        
        if indexPath.row >= viewModel.messageViewModels.count {
            return
        }
        let messageVM = viewModel.messageViewModels[indexPath.row]
        let message = messageVM.message
        
        guard let cell = cell as? MessageCell else { return }
        if message.info.senderUserName == nil {
            viewModel.queryMessageUserInfo(message.info.senderUserID) { [weak cell] error in
                cell?.updateSenderUserInfo()
            }
        }
    }
}

extension ZIMKitMessagesListVC: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row >= viewModel.messageViewModels.count {
            return 59.0
        }
        let messageVM = viewModel.messageViewModels[indexPath.row]
        return messageVM.cellHeight
    }

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        chatBar.resignFirstResponder()
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let minContentY = tableHeaderHeight - tableView.safeAreaInsets.top - tableView.contentInset.top
        if scrollView.contentOffset.y < minContentY && !viewModel.isNoMoreMsg {
            if !indicatorView.isAnimating {
                indicatorView.startAnimating()
//                self.loadMoreMessages()
            }
        } else {
            if indicatorView.isAnimating {
                indicatorView.stopAnimating()
            }
        }
    }
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let minContentY = tableHeaderHeight - tableView.safeAreaInsets.top - tableView.contentInset.top
        if scrollView.contentOffset.y < minContentY && !viewModel.isNoMoreMsg {
            self.loadMoreMessages()
        }
    }
}

extension ZIMKitMessagesListVC: ChatBarDelegate {
    func chatBar(_ chatBar: ChatBar, didChangeStatus status: ChatBarStatus) {

    }

    func chatBarDidUpdateConstraints(_ chatBar: ChatBar) {
        if chatBar.status == .select ||
            chatBar.status == .normal ||
            chatBar.status == .voice { return }
        scrollToBottom(false)
    }

    func chatBar(_ chatBar: ChatBar, didSendText text: String) {
        hideOptionsView()
        
        guard let userDetailInfoModel else { return }
        guard !userDetailInfoModel.blocked else {
            MCToast.show(info: "You've been blocked by the user".localized)
            return
        }
        
        guard !userDetailInfoModel.block else {
            MCToast.show(info: "You've blocked the user".localized)
            return
        }
        
        if text.isEmpty {
            let message = L10n("message_cant_send_empty_msg")
            let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: L10n("common_sure"), style: .cancel)
            alert.addAction(action)
            self.present(alert, animated: true)
            return
        }
        
        ZIMKit.sendTextMessage(text, to: conversationID, type: conversationType) { [weak self] error in
            if error.code != .success {
                self?.showError(error)
            }
        }
    }

    func chatBar(_ chatBar: ChatBar, didSendAudioWith path: String, duration: UInt32) {
        
        guard let userDetailInfoModel else { return }
        guard !userDetailInfoModel.blocked else {
            MCToast.show(info: "You've been blocked by the user".localized)
            return
        }
        
        guard !userDetailInfoModel.block else {
            MCToast.show(info: "You've blocked the user".localized)
            return
        }
        
        ZIMKit.sendAudioMessage(path, duration: duration, to: conversationID, type: conversationType) { [weak self] error in
            if error.code != .success {
                self?.showError(error)
            }
        }
    }

    func chatBar(_ chatBar: ChatBar, didSelectMoreViewWith type: MoreFuncitonType) {
        
        guard let userDetailInfoModel else { return }
        guard !userDetailInfoModel.blocked else {
            MCToast.show(info: "You've been blocked by the user".localized)
            return
        }
        
        guard !userDetailInfoModel.block else {
            MCToast.show(info: "You've blocked the user".localized)
            return
        }
        if type == .photo {
            selectPhotoForSend()
        } else if type == .file {
            selectFileForSend()
        }
    }

    func chatBar(_ chatBar: ChatBar, didStartToRecord recorder: AudioRecorder) {
        
        guard let userDetailInfoModel else { return }
        guard !userDetailInfoModel.blocked else {
            MCToast.show(info: "You've been blocked by the user".localized)
            return
        }
        
        guard !userDetailInfoModel.block else {
            MCToast.show(info: "You've blocked the user".localized)
            return
        }
        
        audioPlayer.stop()
    }

    func chatBarDidClickDeleteButton(_ chatBar: ChatBar) {
        let messages = viewModel.messageViewModels.filter({ $0.isSelected })
        if messages.count == 0 { return }
        // delete selected messages.
        deleteMessages(messages) { [weak self] delete in
            if delete {
                self?.enableMultiSelect(false)
            }
        }
    }
    
    func chatBarDidClickHandleItem(_ chatBar: ChatBar, handleType: ChatHandleType) {
        onClickChatBarHandleType?(chatBar, handleType)
    }
}

// MARK: - MessageCellDelegate
extension ZIMKitMessagesListVC: ImageMessageCellDelegate,
                          UIViewControllerTransitioningDelegate,
                          AudioMessageCellDelegate,
                          VideoMessageCellDelegate,
                          FileMessageDelegate {
    func imageMessageCell(_ cell: ImageMessageCell, didClickImageWith messageVM: ImageMessageViewModel) {
        let galleryVC = GalleryVC()
        galleryVC.modalPresentationStyle = .overFullScreen
        galleryVC.transitioningDelegate = self

        let viewModels = viewModel.messageViewModels.filter { $0.message.type == .image }
        let index = viewModels.firstIndex(where: { $0.message === messageVM.message }) ?? 0

        galleryVC.content = .init(messageViewModels: viewModels,
                                  currentMessageVM: messageVM,
                                  index: index)

        galleryVC.transitionController = zoomTransitionController

        zoomTransitionController.presentedVCImageView = { [weak galleryVC] in
            let imageView =  galleryVC?.imageViewToAnimateWhenDismissing
            return imageView
        }

        zoomTransitionController.presentingImageView = { [weak self, weak galleryVC, weak cell] in
            guard let self = self else { return nil }
            guard let galleryVC = galleryVC else { return nil }
            guard let cell = cell else { return nil }

            guard let cells = self.tableView.visibleCells as? [MessageCell] else { return nil }
            for cell in cells where cell.messageVM === galleryVC.content.currentMessageVM  {
                guard let cell = cell as? ImageMessageCell else { return nil }
                return cell.thumbnailImageView
            }
            return cell.thumbnailImageView
        }
        zoomTransitionController.fromImageView = cell.thumbnailImageView
        present(galleryVC, animated: true)
    }

    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        zoomTransitionController.animationController(
            forPresented: presented,
            presenting: presenting,
            source: source)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        zoomTransitionController.animationController(forDismissed: dismissed)
    }

    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        zoomTransitionController.interactionControllerForDismissal(using: animator)
    }

    func audioMessageCell(_ cell: AudioMessageCell, didClickWith message: AudioMessageViewModel) {
//        if FileManager.default.fileExists(atPath: message.fileLocalPath) {
        if FileManager.default.fileExists(atPath: message.message.audioContent.fileLocalPath) {
            if !audioPlayer.play(with: message) {
                // show play failed tips.
                HUDHelper.showMessage(L10n("message_audio_play_error_tips"))
            }
        } else {
            print("⚠️Audio File not exist: \(message.message.audioContent.fileLocalPath)")
        }
    }

    func videoMessageCell(_ cell: VideoMessageCell, didClickImageWith messageVM: VideoMessageViewModel) {
        audioPlayer.stop()
        let playerViewController = MessageAVPlayerViewController()
        playerViewController.setup(with: messageVM)
        present(playerViewController, animated: true) {
            playerViewController.play()
        }
    }

    func fileMessageCell(_ cell: FileMessageCell, didClickImageWith message: FileMessageViewModel) {
        previewFile(with: message, cell: cell)
    }

    func messageCell(_ cell: MessageCell, longPressWith message: MessageViewModel) {
        showOptionsView(cell, message)
    }
    
    func messageCell(_ cell: MessageCell, avatarClickWith userId: String) {
        let vc = UserProfileViewController()
        vc.userID = conversationID
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Send Messages
extension ZIMKitMessagesListVC {
    func sendImageMessage(with url: URL) {
        ZIMKit.sendImageMessage(url.path, to: conversationID, type: conversationType) { [weak self] error in
            if error.code != .success {
                self?.showError(error, .image)
            }
        }
    }

    func sendVideoMessage(with url: URL) {
        ZIMKit.sendVideoMessage(url.path, to: conversationID, type: conversationType) { [weak self] error in
            if error.code != .success {
                self?.showError(error, .video)
            }
        }
    }

    func sendFileMessage(with url: URL) {
        ZIMKit.sendFileMessage(url.path, to: conversationID, type: conversationType) { [weak self] error in
            if error.code != .success {
                self?.showError(error, .file)
            }
        }
    }
}

// MARK: - Private
extension ZIMKitMessagesListVC {
    func scrollToBottom(_ animated: Bool) {
        if tableView.contentSize.height + view.safeAreaInsets.top > tableView.bounds.height {
            let offset: CGPoint = .init(x: 0, y: tableView.contentSize.height-tableView.frame.size.height+60)
            tableView.setContentOffset(offset, animated: animated)
        }
    }

    func showError(_ error: ZIMError, _ type: ZIMMessageType = .text) {
        if error.code == .networkModuleNetworkError {
            HUDHelper.showErrorMessageIfNeeded(
                error.code.rawValue,
                defaultMessage: L10n("message_network_anomaly"))
        } else if error.code == .messageModuleFileSizeInvalid {
            if type == .image {
                HUDHelper.showErrorMessageIfNeeded(
                    error.code.rawValue,
                    defaultMessage: L10n("message_photo_size_err_tips"))
            } else if type == .video {
                HUDHelper.showErrorMessageIfNeeded(
                    error.code.rawValue,
                    defaultMessage: L10n("message_video_size_err_tips"))
            } else if type == .file {
                HUDHelper.showErrorMessageIfNeeded(
                    error.code.rawValue,
                    defaultMessage: L10n("message_file_size_err_tips"))
            }
        } else if error.code == .messageModuleAuditRejected {
            
            MCToast.show(info: "Sensitive characters detected".localized)
        } else {
            HUDHelper.showErrorMessageIfNeeded(
                error.code.rawValue,
                defaultMessage: error.message)
        }
    }
}
