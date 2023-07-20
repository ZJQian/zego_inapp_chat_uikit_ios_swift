//
//  ConversationCell.swift
//  ZIMKit
//
//  Created by Kael Ding on 2022/8/5.
//

import Foundation

class ConversationCell: _TableViewCell {

    static let reuseIdentifier = String(describing: ConversationCell.self)

    lazy var headImageView = UIImageView().withoutAutoresizingMaskConstraints

    lazy var titleLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.textAlignment = .left
        label.font = UIFont.avenirHeavyFont(ofSize: 18)
        label.textColor = .title
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.textAlignment = .left
        label.font = UIFont.avenirBookFont(ofSize: 13)
        label.textColor = .title.withAlphaComponent(0.6)
        return label
    }()

    lazy var timeLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.textAlignment = .right
        label.font = UIFont.avenirNextRegularFont(ofSize: 12)
        label.textColor = .title.withAlphaComponent(0.6)
        return label
    }()

    lazy var msgFailImageView: UIImageView = {
        let imageView = UIImageView().withoutAutoresizingMaskConstraints
        imageView.image = loadImageSafely(with: "conversation_msg_fail")
        return imageView
    }()

    lazy var unReadBubble = UnReadBubble().withoutAutoresizingMaskConstraints

    lazy var line: UIView = {
        let view = UIView().withoutAutoresizingMaskConstraints
        view.backgroundColor = .clear
        contentView.addSubview(view)
        return view
    }()

    var model: ZIMKitConversation? {
        didSet {
            updateContentIfNeeded()
        }
    }

    var subtitleLeadingConstraint: NSLayoutConstraint!

    override func setUp() {
        super.setUp()

        backgroundColor = .zim_backgroundWhite
        selectionStyle = .none
    }

    override func setUpLayout() {
        super.setUpLayout()

        contentView.addSubview(headImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subTitleLabel)
        contentView.addSubview(timeLabel)
        contentView.addSubview(line)
        contentView.addSubview(unReadBubble)
        contentView.addSubview(msgFailImageView)

        headImageView.layer.cornerRadius = 30.0
        headImageView.layer.masksToBounds = true
        headImageView.leadingAnchor.pin(
            equalTo: contentView.leadingAnchor,
            constant: 16).isActive = true
        headImageView.pin(to: 60.0)
        headImageView.pin(anchors: [.centerY], to: contentView)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.pin(
                equalTo: headImageView.trailingAnchor,
                constant: 11),
            titleLabel.topAnchor.pin(
                equalTo: contentView.topAnchor,
                constant: 23.5),
            titleLabel.trailingAnchor.pin(
                equalTo: timeLabel.leadingAnchor,
                constant: -16),
            titleLabel.heightAnchor.pin(equalToConstant: 24.5)
        ])

        subtitleLeadingConstraint = subTitleLabel.leadingAnchor.pin(equalTo: titleLabel.leadingAnchor)
        NSLayoutConstraint.activate([
            subtitleLeadingConstraint,
            subTitleLabel.topAnchor.pin(equalTo: titleLabel.bottomAnchor, constant: 7),
            subTitleLabel.trailingAnchor.pin(equalTo: contentView.trailingAnchor, constant: -40),
            subTitleLabel.heightAnchor.pin(equalToConstant: 18)
        ])

        NSLayoutConstraint.activate([
            timeLabel.topAnchor.pin(equalTo: contentView.topAnchor, constant: 23.5),
            timeLabel.trailingAnchor.pin(equalTo: contentView.trailingAnchor, constant: -16),
            timeLabel.heightAnchor.pin(equalToConstant: 16.5)
        ])

        NSLayoutConstraint.activate([
            line.leadingAnchor.pin(equalTo: titleLabel.leadingAnchor),
            line.heightAnchor.pin(equalToConstant: 0.5)
        ])
        line.pin(anchors: [.trailing, .bottom], to: contentView)

        NSLayoutConstraint.activate([
            unReadBubble.centerYAnchor.pin(equalTo: subTitleLabel.centerYAnchor, constant: -2),
            unReadBubble.trailingAnchor.pin(equalTo: contentView.trailingAnchor, constant: -16),
        ])
        unReadBubble.pin(to: 18.0)
        
//        unReadBubble.leadingAnchor.pin(
//            equalTo: contentView.leadingAnchor,
//            constant: 46).isActive = true
//        unReadBubble.topAnchor.pin(
//            equalTo: contentView.topAnchor,
//            constant: 11).isActive = true
//        unReadBubble.pin(to: 20.0)

        msgFailImageView.leadingAnchor.pin(equalTo: titleLabel.leadingAnchor).isActive = true
        msgFailImageView.topAnchor.pin(equalTo: titleLabel.bottomAnchor, constant: 7).isActive = true
        msgFailImageView.pin(to: 16.5)
    }

    override func updateContent() {
        super.updateContent()

        guard let model = model else { return }

        // load image
        var placeHolder = "icon_avatar_placeholder"
        if model.type == .group {
            placeHolder = "groupAvatar_default"
        }
        headImageView.loadImage(with: model.avatarUrl, placeholder: placeHolder)

        let userName = model.name.count > 0
            ? model.name
            : model.id
        titleLabel.text = userName

        // update time
        if model.lastMessage?.info.timestamp == 0 {
            timeLabel.text = ""
        } else {
            timeLabel.text = timestampToConversationDateStr(model.lastMessage?.info.timestamp)
        }

        // update subtitle
        subTitleLabel.text = model.lastMessage?.getShortString()

        unReadBubble.setNum(model.unreadMessageCount)

        msgFailImageView.isHidden = model.lastMessage?.info.sentStatus != .sendFailed

        if model.lastMessage?.info.sentStatus == .sendFailed {
            subtitleLeadingConstraint.constant = 20.5
        } else {
            subtitleLeadingConstraint.constant = 0
        }
    }
}
