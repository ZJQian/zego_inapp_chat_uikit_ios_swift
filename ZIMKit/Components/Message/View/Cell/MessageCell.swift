//
//  MessageCell.swift
//  ZIMKit
//
//  Created by Kael Ding on 2022/8/17.
//

import Foundation

protocol MessageCellDelegate: AnyObject {
    func messageCell(_ cell: MessageCell, longPressWith messageViewModel: MessageViewModel)
    func messageCell(_ cell: MessageCell, avatarClickWith userId: String)
}

extension MessageCellDelegate {
    func messageCell(_ cell: MessageCell, avatarClickWith messageViewModel: MessageViewModel) {}
}

class MessageCell: _TableViewCell {

    class var reuseId: String {
        String(describing: MessageCell.self)
    }

    lazy var timeLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.textAlignment = .center
        label.font = UIFont.avenirNextMediumFont(ofSize: 12)
        label.textColor = UIColor.black.withAlphaComponent(0.4)
        return label
    }()

    lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        imageView.image = UIImage(named: "icon_avatar_default")
        imageView.layer.cornerRadius = 25.0
        imageView.layer.masksToBounds = true
        return imageView
    }()

    lazy var nameLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        label.textAlignment = .left
        label.textColor = .zim_textGray5
        return label
    }()

    lazy var containerView: UIView = {
        let view = UIView().withoutAutoresizingMaskConstraints
        view.backgroundColor = .clear
        return view
    }()

    lazy var indicator: UIActivityIndicatorView = {
        var style = UIActivityIndicatorView.Style.gray
        if #available(iOS 13.0, *) {
            style = .medium
        }
        let indicator = UIActivityIndicatorView(style: style).withoutAutoresizingMaskConstraints
        return indicator
    }()

    lazy var retryButton: UIButton = {
        let button = UIButton(type: .custom).withoutAutoresizingMaskConstraints
        button.setImage(loadImageSafely(with: "message_send_fail"), for: .normal)
        return button
    }()

    lazy var selectIcon = UIImageView().withoutAutoresizingMaskConstraints
    lazy var selectButton: UIButton = {
        let button = UIButton(type: .custom).withoutAutoresizingMaskConstraints
        button.backgroundColor = .clear
        return button
    }()

    var messageVM: MessageViewModel? {
        didSet {
            updateContentIfNeeded()
        }
    }

    weak var delegate: MessageCellDelegate?

    private var avatarTopConstraint: NSLayoutConstraint!
    private var avatarHorizontalConstraint: NSLayoutConstraint!
    private var nameHorizontalConstraint: NSLayoutConstraint!
    private var containerWidthConstraint: NSLayoutConstraint!
    private var containerHeightConstraint: NSLayoutConstraint!
    private var containerTopConstraint: NSLayoutConstraint!
    private var containerHorizontalConstraint: NSLayoutConstraint!
    private var retryButtonHorizontalConstraint: NSLayoutConstraint!

    override func setUp() {
        super.setUp()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(longPressAction))
        containerView.addGestureRecognizer(longPress)

        selectButton.addTarget(self, action: #selector(selectButtonClick), for: .touchUpInside)
    }

    override func setUpLayout() {
        super.setUpLayout()

        contentView.addSubview(timeLabel)
        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.pin(equalTo: contentView.centerXAnchor),
            timeLabel.topAnchor.pin(equalTo: contentView.topAnchor, constant: 4),
            timeLabel.heightAnchor.pin(equalToConstant: 16.5)
        ])

        contentView.addSubview(avatarImageView)
        avatarImageView.pin(to: 50.0)
        updateAvatarConstraint()
        
        let avatarTap = UITapGestureRecognizer(target: self, action: #selector(avatarTapAction))
        avatarImageView.addGestureRecognizer(avatarTap)
        

        contentView.addSubview(selectIcon)
        selectIcon.pin(to: 23.0)
        selectIcon.leadingAnchor.pin(equalTo: contentView.leadingAnchor, constant: 8.0).isActive = true
        selectIcon.centerYAnchor.pin(equalTo: avatarImageView.centerYAnchor).isActive = true

        contentView.addSubview(nameLabel)
        NSLayoutConstraint.activate([
            nameLabel.topAnchor.pin(equalTo: avatarImageView.topAnchor),
            nameLabel.widthAnchor.pin(equalToConstant: 160),
            nameLabel.heightAnchor.pin(equalToConstant: 15)
        ])
        updateNameLabelConstraint()

        contentView.addSubview(containerView)
        containerWidthConstraint = containerView.widthAnchor.pin(equalToConstant: 0)
        containerHeightConstraint = containerView.heightAnchor.pin(equalToConstant: 0)
        containerWidthConstraint.isActive = true
        containerHeightConstraint.isActive = true
        updateContainerConstraint()

        contentView.addSubview(retryButton)
        NSLayoutConstraint.activate([
            retryButton.centerYAnchor.pin(equalTo: containerView.centerYAnchor),
            retryButton.widthAnchor.pin(equalToConstant: 24.0),
            retryButton.heightAnchor.pin(equalToConstant: 24.0)
        ])
        updateRetryButtonConstraint()

        contentView.addSubview(indicator)
        indicator.pin(to: retryButton)

        contentView.embed(selectButton)
    }

    private func updateAvatarConstraint() {
        // inActive pre constraint
        if avatarTopConstraint != nil {
            avatarTopConstraint.isActive = false
        }
        if avatarHorizontalConstraint != nil {
            avatarHorizontalConstraint.isActive = false
        }

        avatarTopConstraint = avatarImageView.topAnchor.pin(equalTo: contentView.topAnchor)
        if messageVM?.isShowTime == true {
            avatarTopConstraint = avatarImageView.topAnchor.pin(
                equalTo: timeLabel.bottomAnchor,
                constant: 12)
        }
        let leadingConstant = messageVM?.isShowCheckBox == true ? 39.0 : 15.0
        avatarHorizontalConstraint = avatarImageView.leadingAnchor.pin(
            equalTo: contentView.leadingAnchor,
            constant: leadingConstant)
        if messageVM?.message.info.direction == .send {
            avatarHorizontalConstraint =  avatarImageView.trailingAnchor.pin(equalTo: contentView.trailingAnchor, constant: -15)
        }
        avatarTopConstraint.isActive = true
        avatarHorizontalConstraint.isActive = true
    }

    private func updateNameLabelConstraint() {
        if nameHorizontalConstraint != nil {
            nameHorizontalConstraint.isActive = false
        }
        nameHorizontalConstraint = nameLabel.leadingAnchor.pin(
            equalTo: avatarImageView.trailingAnchor,
            constant: 12)
        if messageVM?.message.info.direction == .send {
            nameHorizontalConstraint = nameLabel.trailingAnchor.pin(
                equalTo: avatarImageView.leadingAnchor,
                constant: -12)
        }
        nameHorizontalConstraint.isActive = true
    }

    private func updateContainerConstraint() {

        var contentW = 0.0
        var contentH = 0.0
        if let message = messageVM {
            contentW = message.contentSize.width + message.cellConfig.contentInsets.left * 2
            contentH = message.contentSize.height + message.cellConfig.contentInsets.top * 2
        }
        containerWidthConstraint.constant = contentW
        containerHeightConstraint.constant = contentH

        if containerTopConstraint != nil {
            containerTopConstraint.isActive = false
        }
        if containerHorizontalConstraint != nil {
            containerHorizontalConstraint.isActive = false
        }
        
        containerTopConstraint = containerView.topAnchor.pin(equalTo: avatarImageView.topAnchor)
        if messageVM?.isShowName == true {
            containerTopConstraint = containerView.topAnchor.pin(
                equalTo: nameLabel.bottomAnchor,
                constant: 2)
        }
        containerTopConstraint.isActive = true

        containerHorizontalConstraint = containerView.leadingAnchor.pin(
            equalTo: avatarImageView.trailingAnchor,
            constant: 13)
        if messageVM?.message.info.direction == .send {
            containerHorizontalConstraint = containerView.trailingAnchor.pin(
                equalTo: avatarImageView.leadingAnchor,
                constant: -13)
        }
        containerHorizontalConstraint.isActive = true
        
    }

    private func updateRetryButtonConstraint() {
        if retryButtonHorizontalConstraint != nil {
            retryButtonHorizontalConstraint.isActive = false
        }
        retryButtonHorizontalConstraint = retryButton.leadingAnchor.pin(
            equalTo: containerView.trailingAnchor,
            constant: 8)
        if messageVM?.message.info.direction == .send {
            retryButtonHorizontalConstraint = retryButton.trailingAnchor.pin(
                equalTo: containerView.leadingAnchor,
                constant: -8)
        }
        retryButtonHorizontalConstraint.isActive = true
    }

    override func updateContent() {
        super.updateContent()

        guard let messageVM = messageVM else { return }
        let message = messageVM.message

        updateAvatarConstraint()
        updateNameLabelConstraint()
        updateContainerConstraint()
        updateRetryButtonConstraint()

        if message.info.sentStatus == .sending && message.info.direction == .send {
            indicator.startAnimating()
        } else {
            indicator.stopAnimating()
        }

        timeLabel.isHidden = !messageVM.isShowTime
        if messageVM.isShowTime {
            timeLabel.text = timestampToMessageDateStr(message.info.timestamp)
        }

        updateSenderUserInfo()

        retryButton.isHidden = !(message.info.sentStatus == .sendFailed && message.info.direction == .send)

        selectIcon.isHidden = !messageVM.isShowCheckBox
        selectButton.isHidden = !messageVM.isShowCheckBox
        selectIcon.image = loadImageSafely(
            with: messageVM.isSelected
                ? "message_multiSelect_selected"
                : "message_multiSelect_normal")

    }
    
    func updateSenderUserInfo() {
        guard let messageVM = messageVM else { return }
        let message = messageVM.message
        
        avatarImageView.loadImage(with: message.info.senderUserAvatarUrl, placeholder: "icon_avatar_placeholder")
        
        nameLabel.isHidden = !messageVM.isShowName
        if messageVM.isShowName {
            var name = message.info.senderUserName ?? ""
            name = name.count > 0 ? name : message.info.senderUserID
            nameLabel.text = name
        }
    }
}

extension MessageCell {
    @objc func longPressAction(_ longPress: UILongPressGestureRecognizer) {
        if longPress.state == .began {
            guard let message = messageVM else { return }
            delegate?.messageCell(self, longPressWith: message)
        }
    }

    @objc func selectButtonClick(_ sender: UIButton) {
        guard let message = messageVM else { return }
        message.isSelected = !message.isSelected
        selectIcon.image = loadImageSafely(
            with: message.isSelected
                ? "message_multiSelect_selected"
                : "message_multiSelect_normal")
    }
    
    @objc func avatarTapAction() {
        
        guard let message = messageVM, message.message.info.direction == .receive else { return }
        delegate?.messageCell(self, avatarClickWith: message.message.info.senderUserID)
    }
}
