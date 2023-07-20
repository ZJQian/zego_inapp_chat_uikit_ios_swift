//
//  CallMessageViewModel.swift
//  MatChat
//
//  Created by admin on 2023/5/26.
//

import UIKit

class CallMessageViewModel: MessageViewModel {

    
    public var callDuration: String?
    public var callType: MCMessageType = .videoCall
    private var callMessage: ZIMKitMessage?
    
    override init(with msg: ZIMKitMessage) {
        super.init(with: msg)
        setContent(msg.textContent)
        callMessage = msg
    }
    
    convenience init(with content: String) {
        let msg = ZIMKitMessage()
        msg.textContent.content = content
        self.init(with: msg)
    }
    
    
    override var contentSize: CGSize {
        switch callMessage?.textContent.des.msgType {
        case .callCancel, .callReject:
            return CGSize(width: 140, height: 56)
        default:
            let size = (callDuration as? NSString)?.boundingRect(with: CGSize(width: CGFloat(CGFLOAT_MAX), height: 56), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.avenirNextMediumFont(ofSize: 16)], context: nil).size
            return CGSize(width: (size?.width ?? 0)+62, height: 56)
        }
    }
    
    func setContent(_ message: TextMessageContent) {
        
        callDuration = message.des.conversationDes
        callType = message.des.msgType

    }
}
