//
//  ChatHandleBar.swift
//  MatChat
//
//  Created by admin on 2023/5/5.
//

import UIKit

public enum ChatHandleType: Int {
    case voiceCall = 100
    case videoCall = 101
    case sendGift = 102
}

class ChatHandleBar: _View {
    
    public var onClickBarItem: ((_ type: ChatHandleType) -> Void)?

    override func setUp() {
        super.setUp()
        
        backgroundColor = .zim_backgroundGray5
    }

    override func setUpLayout() {
        super.setUpLayout()
        
        var titles = ["Chat Voice Call".localized,
                      "Chat Video Call".localized,
                      "Chat Gift".localized]
        if UserManager.user?.genderEnum == .female {
            titles = ["Chat Voice Call".localized,
                      "Chat Video Call".localized]
        }
        let images = ["icon_chat_voice_call",
                      "icon_chat_video_call",
                      "icon_chat_send_gift"]
        let btnWidth = UIScreen.width/CGFloat(titles.count)
        for (index, title) in titles.enumerated() {
            let btn = MCButton(spacing: 4)
            btn.setTitle(title)
            btn.tag = 100+index
            btn.setImage(UIImage(named: images[index]))
            btn.titleLabel.font = UIFont.avenirNextMediumFont(ofSize: 15)
            btn.titleLabel.textColor = UIColor.black
            addSubview(btn)
            btn.snp.makeConstraints { make in
                make.width.equalTo(btnWidth)
                make.height.equalTo(44)
                make.left.equalToSuperview().offset(CGFloat(index)*btnWidth)
                make.top.equalToSuperview()
            }
            btn.setOnClickCallback { [weak self] sender in

                guard let self,
                      let type = ChatHandleType(rawValue: sender.tag) else {
                    return
                }
                self.onClickBarItem?(type)
            }
        }
    }
}
