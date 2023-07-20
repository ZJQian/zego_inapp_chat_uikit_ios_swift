//
//  ZIMKitConversationListVC.swift
//  ZIMKitConversation
//
//  Created by Kael Ding on 2022/7/29.
//

import UIKit
import SwiftyUserDefaults

class ZIMKitConversationListVC: _ViewController {
    
    public weak var delegate: ZIMKitConversationListVCDelegate?
    public weak var messageDelegate: ZIMKitMessagesListVCDelegate?

    lazy var viewModel = ConversationListViewModel()
    
    private var myConversationList = [ZIMKitConversation]()

    lazy var noDataView: ConversationNoDataView = {
        let noDataView = ConversationNoDataView(frame: view.bounds).withoutAutoresizingMaskConstraints
        noDataView.delegate = self
        return noDataView
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: view.bounds, style: .plain).withoutAutoresizingMaskConstraints
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = view.backgroundColor
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ConversationCell.self, forCellReuseIdentifier: ConversationCell.reuseIdentifier)
        tableView.rowHeight = 95
        tableView.separatorStyle = .none
        tableView.delaysContentTouches = false
        return tableView
    }()
    
    lazy var notiTipView: UIView = {
        let notiView = UIView()
        notiView.isUserInteractionEnabled = true
        notiView.backgroundColor = UIColor.hexColor("#F9881E")
        return notiView
    }()
    
    open override func setUp() {
        super.setUp()
        view.backgroundColor = .white
        self.navigationItem.title = "In-app Chat"
    }

    open override func setUpLayout() {
        super.setUpLayout()
        
        view.addSubview(notiTipView)
        notiTipView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            if !RemoteNotiManager.shared.notiGranted, !RemoteNotiManager.shared.closeNotiTipManual {
                make.height.equalTo(43)
            } else {
                make.height.equalTo(0)
            }
        }
        
        
        let notitap = UITapGestureRecognizer(target: self, action: #selector(notiTapAction))
        notiTipView.addGestureRecognizer(notitap)
        
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(named: "icon_close_s"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonAction), for: .touchUpInside)
        notiTipView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
        
        let notiLabel = UILabel()
        notiLabel.textColor = UIColor.white
        notiLabel.numberOfLines = 0
        notiTipView.addSubview(notiLabel)
        notiLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(12)
            make.centerY.equalToSuperview().offset(1)
            make.right.equalToSuperview().offset(-32)
            make.height.equalTo(27)
        }
        let paraStyle = NSMutableParagraphStyle()
        paraStyle.maximumLineHeight = 13.5
        let text = "Message notice disabled. Unable to receive new messages.".localized
        let astr = NSMutableAttributedString(string: text, attributes: [.font: UIFont.avenirNextMediumFont(ofSize: 13)])
        astr.addAttributes([.paragraphStyle: paraStyle], range: NSRange(location: 0, length: text.count))
        notiLabel.attributedText = astr

        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(notiTipView.snp.bottom)
        }
        tableView.emptyState.delegate = self
//        view.embed(noDataView)
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(appBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        configViewModel()
        getConversationList()
        LocalAPNS.shared.setupLocalAPNS()
    }

    deinit {
//        ZIMKit.disconnectUser()
    }

    func configViewModel() {
        // listen the conversations change and reload.
        viewModel.$conversations.bind { [weak self] _ in
            
            self?.getUserInfoList()
            
        }
    }
    
    func getConversationList() {
        viewModel.getConversationList { [weak self] conversations, error in
            if error.code == .success {
                self?.getUserInfoList()
                return
            }
            guard let self = self else { return }
//            self.noDataView.setButtonTitle(L10n("conversation_reload"))
//            self.noDataView.isHidden = false
            self.tableView.emptyViewShow(.noResponse)
            HUDHelper.showErrorMessageIfNeeded(error.code.rawValue, defaultMessage: error.message)
            
            
        }
    }
    
    func getUserInfoList() {
        
        var isHaveEmptyName = false
        for conversation in viewModel.conversations {
            if conversation.name.count == 0 || conversation.avatarUrl.count == 0 {
                isHaveEmptyName = true
                break
            }
        }
        
        if !isHaveEmptyName {
            myConversationList = viewModel.conversations
            if self.myConversationList.count == 0 {
                self.tableView.emptyViewShow(.noMessage)
            } else {
                self.tableView.emptyViewHide()
            }
            self.tableView.reloadData()
            return
        }
        
        let ids = viewModel.conversations.compactMap { conversation in
            conversation.id
        }
        API.User.baseInfoList.fetch(ids).successJSON { [weak self] response in
            
            let list = response["data"] as? [[String: Any]] ?? []
            var tmplist = self?.viewModel.conversations ?? []
            for dic in list {
                let id = dic["id"] as? Int64 ?? 0
                let nickName = dic["nickName"] as? String
                let avatar = dic["avatar"] as? String
                for (index, conversation) in tmplist.enumerated() {
                    if id == conversation.id.intValue {
                        let tmpConversation = conversation
                        tmpConversation.name = nickName ?? "\(id)"
                        tmpConversation.avatarUrl = avatar~
                        tmplist[index] = tmpConversation
                    }
                }
            }
            self?.myConversationList = tmplist
            if self?.myConversationList.count == 0 {
                self?.tableView.emptyViewShow(.noMessage)
            } else {
                self?.tableView.emptyViewHide()
            }
            self?.tableView.reloadData()
        }
    }

    func loadMoreConversations() {
        viewModel.loadMoreConversations()
    }
    
    @objc func closeButtonAction() {
        RemoteNotiManager.shared.closeNotiTipManual = true
        notiTipView.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        view.layoutIfNeeded()
    }
    
    @objc func notiTapAction() {
        AppUtils.shared.openSystemSettings()
    }
    
    @objc func appBecomeActive() {
        
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                // 已经授权
                RemoteNotiManager.shared.notiGranted = true
                DispatchQueue.main.async {
                    self.notiTipView.snp.updateConstraints { make in
                        make.height.equalTo(0)
                    }
                    self.view.layoutIfNeeded()
                }
               
            default:
                RemoteNotiManager.shared.notiGranted = false
                
                DispatchQueue.main.async {
                    self.notiTipView.snp.updateConstraints { make in
                        make.height.equalTo(43)
                    }
                    self.view.layoutIfNeeded()
                }
                break
            }
        }
    }
}

extension ZIMKitConversationListVC: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        self.noDataView.isHidden = viewModel.conversations.count > 0
        return myConversationList.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: ConversationCell.reuseIdentifier, for: indexPath)
                as? ConversationCell else {
            return ConversationCell()
        }

        if indexPath.row >= myConversationList.count {
            return ConversationCell()
        }

        cell.model = myConversationList[indexPath.row]

        return cell
    }
}

extension ZIMKitConversationListVC: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row >= myConversationList.count { return }
        let model = myConversationList[indexPath.row]

        let defaultAction = {
            let messageListVC = ZIMKitMessagesListVC(conversationID: model.id, type: model.type, conversationName: model.name)
            messageListVC.delegate = self.messageDelegate
            self.navigationController?.pushViewController(messageListVC, animated: true)
            // clear unread messages
            self.viewModel.clearConversationUnreadMessageCount(model.id, type: model.type)
        }
        if delegate?.conversationList(_:didSelectWith:defaultAction:) == nil {
            defaultAction()
        } else {
            delegate?.conversationList?(self, didSelectWith: model, defaultAction: defaultAction)
        }
    }

    public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        if indexPath.row >= myConversationList.count { return nil }

        let conversation = myConversationList[indexPath.row]
        let action = UITableViewRowAction(style: .normal, title: L10n("conversation_delete")) { _, index in
            tableView.performBatchUpdates {
                self.viewModel.deleteConversation(conversation) { error in
                    if error.code != .success {
                        HUDHelper.showErrorMessageIfNeeded(error.code.rawValue, defaultMessage: error.message)
                    }
                }
                tableView.deleteRows(at: [index], with: .none)
            }
        }
        action.backgroundColor = .zim_backgroundRed

        return [action]
    }

    public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row >= myConversationList.count { return nil }

        let conversation = myConversationList[indexPath.row]
        let action = UIContextualAction(style: .normal, title: "Delete") { _, _, _ in
            tableView.performBatchUpdates {
                self.viewModel.deleteConversation(conversation) { error in
                    if error.code != .success {
                        HUDHelper.showErrorMessageIfNeeded(error.code.rawValue, defaultMessage: error.message)
                    } else {
                        self.tableView.reloadData()
                    }
                    
                }
                tableView.deleteRows(at: [indexPath], with: .none)
            }
        }
        action.backgroundColor = UIColor.hexColor("#FD2D55")
        
//        let actionTop = UIContextualAction(style: .normal, title: "Top".localized) { _, _, _ in
//            tableView.performBatchUpdates {
//                self.viewModel.deleteConversation(conversation) { error in
//                    if error.code != .success {
//                        HUDHelper.showMessage(error.message)
//                    }
//                }
//                tableView.deleteRows(at: [indexPath], with: .none)
//            }
//        }
//        actionTop.backgroundColor = UIColor.hexColor("#F9881E")

        let configuration = UISwipeActionsConfiguration(actions: [action])
        configuration.performsFirstActionWithFullSwipe = false

        return configuration
    }

    public func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let row = indexPath.row
        let distance = myConversationList.count - 5
        if row == distance {
            loadMoreConversations()
        }
    }
}

extension ZIMKitConversationListVC: EmptyStateDelegate {
    
    func emptyState(emptyState: EmptyState, didPressButton button: UIButton) {
        self.tableView.emptyViewHide()
        getConversationList()
    }
}

extension ZIMKitConversationListVC: ConversationNoDataViewDelegate {
    func onNoDataViewButtonClick() {
        getConversationList()
    }
}
