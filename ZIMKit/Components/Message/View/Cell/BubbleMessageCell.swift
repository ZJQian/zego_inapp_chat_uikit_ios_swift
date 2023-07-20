//
//  BubbleMessageCell.swift
//  ZIMKit
//
//  Created by Kael Ding on 2022/8/18.
//

import Foundation

class BubbleMessageCell: MessageCell {

    override class var reuseId: String {
        String(describing: BubbleMessageCell.self)
    }

    lazy var bubbleView = UIImageView().withoutAutoresizingMaskConstraints
    
    lazy var arrowImgview: UIImageView = {
        let imgView = UIImageView()
        return imgView
    }()

    override func setUp() {
        super.setUp()

        bubbleView.layer.cornerRadius = 12.0
        bubbleView.layer.masksToBounds = true
        
        contentView.addSubview(arrowImgview)
        
    }

    override func setUpLayout() {
        super.setUpLayout()
        containerView.embed(bubbleView)
        
    }

    override func updateContent() {
        super.updateContent()

        guard let messageVM = messageVM else { return }
        let message = messageVM.message
        
        let insets = UIEdgeInsets(top: 11, left: 12, bottom: 11, right: 12)
        if message.info.direction == .send {
            bubbleView.image = loadImageSafely(with: "send_bubble").resizableImage(withCapInsets: insets, resizingMode: .stretch)
            
            arrowImgview.image = UIImage(named: "icon_arrow_send")
            arrowImgview.snp.remakeConstraints { make in
                make.centerY.equalTo(avatarImageView)
                make.width.equalTo(7)
                make.height.equalTo(13)
                make.leading.equalTo(bubbleView.snp.trailing)
            }
        } else {
            bubbleView.image = loadImageSafely(with: "receve_bubble").resizableImage(withCapInsets: insets, resizingMode: .stretch)
            arrowImgview.image = UIImage(named: "icon_arrow_receive")
            arrowImgview.snp.remakeConstraints { make in
                make.centerY.equalTo(avatarImageView)
                make.width.equalTo(7)
                make.height.equalTo(13)
                make.trailing.equalTo(bubbleView.snp.leading)
            }
        }
    }
}
