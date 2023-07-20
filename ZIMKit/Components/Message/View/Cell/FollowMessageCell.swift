//
//  FollowMessageCell.swift
//  MatChat
//
//  Created by admin on 2023/7/3.
//

import UIKit

class FollowMessageCell: MessageCell {

    override class var reuseId: String {
        String(describing: FollowMessageCell.self)
    }

    lazy var messageLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.textAlignment = .center
        label.font = UIFont.avenirMediumFont(ofSize: 12)
        label.textColor = UIColor.hexColor("#666666")
        label.numberOfLines = 0
        return label
    }()
    
    lazy var container: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.05)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()

    override func setUp() {
        super.setUp()
    }

    override func setUpLayout() {
                
        contentView.addSubview(timeLabel)
        timeLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(4)
            make.height.equalTo(16.5)
        }
        
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(messageVM?.contentSize.width ?? 180)
            make.height.equalTo(messageVM?.contentSize.height ?? 40)
        }

        container.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        updateMessageLabelConstraint()
    }

    private func updateMessageLabelConstraint() {
        
        if messageVM?.isShowTime == true {
            container.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(messageVM?.contentSize.width ?? 180)
                make.height.equalTo(messageVM?.contentSize.height ?? 40)
                make.top.equalTo(timeLabel.snp.bottom).offset(12)
            }
        } else {
            container.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(messageVM?.contentSize.width ?? 180)
                make.height.equalTo(messageVM?.contentSize.height ?? 40)
                make.top.equalToSuperview().offset(12)
            }
        }
    }

    override func updateContent() {

        updateMessageLabelConstraint()

        guard let messageVM = messageVM as? FollowMessageViewModel else { return }
        messageLabel.text = messageVM.followContent
        timeLabel.isHidden = !messageVM.isShowTime
        if messageVM.isShowTime {
            timeLabel.text = timestampToMessageDateStr(messageVM.message.info.timestamp)
        }
    }
}
