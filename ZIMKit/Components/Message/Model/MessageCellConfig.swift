//
//  MessageCellConfig.swift
//  ZIMKit
//
//  Created by Kael Ding on 2022/8/18.
//

import Foundation

struct MessageCellConfig {
    var avatarSize: CGSize = CGSize(width: 50, height: 50)
    var messageTextFont: UIFont = UIFont.avenirNextMediumFont(ofSize: 16)
    var userNameFont: UIFont = UIFont.systemFont(ofSize: 11, weight: .medium)
    var messageTextColor: UIColor = .black
    var userNameColor: UIColor = .zim_textGray5
    var contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
}
