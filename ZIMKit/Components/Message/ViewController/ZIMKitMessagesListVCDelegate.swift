//
//  ZIMKitMessagesListVCDelegate.swift
//  ZIMKit
//
//  Created by Kael Ding on 2023/2/15.
//

import Foundation

@objc protocol ZIMKitMessagesListVCDelegate: AnyObject {
    @objc optional
    func getMessageListHeaderBar(_ messageListVC: ZIMKitMessagesListVC) -> ZIMKitHeaderBar?
}
