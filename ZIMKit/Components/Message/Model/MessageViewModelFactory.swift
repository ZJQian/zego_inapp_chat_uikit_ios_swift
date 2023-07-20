//
//  MessageFactory.swift
//  ZIMKit
//
//  Created by Kael Ding on 2022/8/17.
//

import Foundation
import ZIM

class MessageViewModelFactory {
    static func createMessage(with msg: ZIMKitMessage) -> MessageViewModel {
        switch msg.type {
        case .text:
            
            switch msg.textContent.des.msgType {
            case .gift:
                return GiftMessageViewModel(with: msg)
            case .callReject,
                    .callCancel,
                    .voiceCall,
                    .videoCall:
                return CallMessageViewModel(with: msg)
            case .follow:
                return FollowMessageViewModel(with: msg)
            case .zegoSystem:
                return SystemMessageViewModel(with: msg)
            default:
                return TextMessageViewModel(with: msg)
            }
        case .image:
            return ImageMessageViewModel(with: msg)
        case .audio:
            return AudioMessageViewModel(with: msg)
        case .video:
            return VideoMessageViewModel(with: msg)
        case .file:
            return FileMessageViewModel(with: msg)
        case .system:
            return SystemMessageViewModel(with: msg)
        default:
            return UnknownMessageViewModel(with: msg)
        }
    }
}
