//
//  TextMessageCell.swift
//  ZIMKit
//
//  Created by Kael Ding on 2022/8/18.
//

import Foundation

class TextMessageCell: BubbleMessageCell {
    override class var reuseId: String {
        String(describing: TextMessageCell.self)
    }

    lazy var messageLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 15)
        label.numberOfLines = 0
        return label
    }()

    override func setUp() {
        super.setUp()
        

    }

    override func setUpLayout() {
        super.setUpLayout()
        updateMessageLabelConstraint()
        
        bubbleView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapLinkAction(_ :)))
        bubbleView.addGestureRecognizer(tap)
    }

    private func updateMessageLabelConstraint() {
        let insets = messageVM?.cellConfig.contentInsets ?? UIEdgeInsets()
        let directionInsets = NSDirectionalEdgeInsets(
            top: insets.top,
            leading: insets.left,
            bottom: insets.bottom,
            trailing: insets.right)
        messageLabel.removeFromSuperview()
        bubbleView.embed(messageLabel, insets: directionInsets)
        
    }

    override func updateContent() {
        super.updateContent()

        guard let messageVM = messageVM as? TextMessageViewModel else { return }
        updateMessageLabelConstraint()

        messageLabel.attributedText = messageVM.attributedContent
//        messageLabel.textColor = messageVM.cellConfig.messageTextColor
        messageLabel.font = messageVM.cellConfig.messageTextFont
    }
    
    @objc func tapLinkAction(_ sender: UITapGestureRecognizer) {
        guard let messageVM = messageVM as? TextMessageViewModel else { return }
        if let schema = messageVM.message.textContent.content.dictionaryValue["schema"] as? String, let decodeStr = schema.removingPercentEncoding {
            MCRouter.toPage(decodeStr)
        }
    }
}
