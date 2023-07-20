//
//  SystemMessageCell.swift
//  ZIMKit
//
//  Created by Kael Ding on 2022/8/18.
//

import Foundation

class SystemMessageCell: MessageCell {

    override class var reuseId: String {
        String(describing: SystemMessageCell.self)
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
    
    lazy var handleButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.titleLabel?.font = UIFont.avenirHeavyFont(ofSize: 12)
        btn.setTitleColor(UIColor.hexColor("#A569F5"), for: .normal)
        btn.addTarget(self, action: #selector(btnAction), for: .touchUpInside)
        return btn
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
            make.width.equalTo(messageVM?.contentSize.width ?? UIScreen.width-30)
            make.height.equalTo(messageVM?.contentSize.height ?? 57.0)
        }

        container.addSubview(messageLabel)
        messageLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        container.addSubview(handleButton)
        handleButton.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-12)
            make.height.equalTo(14)
        }
        
        updateMessageLabelConstraint()
    }

    private func updateMessageLabelConstraint() {
        
        if messageVM?.isShowTime == true {
            container.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(messageVM?.contentSize.width ?? UIScreen.width-30)
                make.height.equalTo(messageVM?.contentSize.height ?? 57.0)
                make.top.equalTo(timeLabel.snp.bottom).offset(12)
            }
        } else {
            container.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.width.equalTo(messageVM?.contentSize.width ?? UIScreen.width-30)
                make.height.equalTo(messageVM?.contentSize.height ?? 57.0)
                make.top.equalToSuperview().offset(12)
            }
        }
    }

    override func updateContent() {

        updateMessageLabelConstraint()

        guard let messageVM = messageVM as? SystemMessageViewModel else { return }
        
        handleButton.setTitle(messageVM.schemaName, for: .normal)
        if messageVM.schema == MCRouterType.sendGift.rawValue {
            
            handleButton.isHidden = false
            
            messageLabel.snp.remakeConstraints { make in
                make.leading.equalToSuperview().offset(12)
                make.centerY.equalToSuperview()
            }
            
            handleButton.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalTo(messageLabel.snp.trailing).offset(3)
                make.height.equalTo(14)
            }
        } else {
            messageLabel.snp.remakeConstraints { make in
                make.top.leading.equalToSuperview().offset(12)
                make.trailing.equalToSuperview().offset(-12)
            }
            
            handleButton.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview().offset(-12)
                make.height.equalTo(14)
            }
            
            if messageVM.schemaName.count > 0 {
                handleButton.isHidden = false
                
            } else {
                handleButton.isHidden = true
            }
        }
        
        messageLabel.text = messageVM.content
        timeLabel.isHidden = !messageVM.isShowTime
        if messageVM.isShowTime {
            timeLabel.text = timestampToMessageDateStr(messageVM.message.info.timestamp)
        }
                
    }
    
    @objc func btnAction() {
        guard let messageVM = messageVM as? SystemMessageViewModel else { return }
        guard let router = MCRouterType(rawValue: messageVM.schema) else { return }
        MCRouter.toPage(router.rawValue)
    }
}
