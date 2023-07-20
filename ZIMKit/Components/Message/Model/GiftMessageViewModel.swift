//
//  GiftMessageViewModel.swift
//  MatChat
//
//  Created by admin on 2023/5/24.
//

import UIKit

class GiftMessageViewModel: MessageViewModel {

    var giftMessageModel: ZIMCustomMessage?
    
    override init(with msg: ZIMKitMessage) {
        super.init(with: msg)
        setContent(msg.textContent.content)
    }
    
    convenience init(with content: String) {
        let msg = ZIMKitMessage()
        msg.textContent.content = content
        self.init(with: msg)
    }
    
    
    override var contentSize: CGSize {
        
        if UserManager.user?.genderEnum == .female {
            
            if self.message.info.direction == .send {
                return CGSize(width: 230, height: 76)
            }
            return CGSize(width: 230, height: 116)
            
        } else {
            if self.message.info.direction == .send {
                return CGSize(width: 230, height: 116)
            }
            return CGSize(width: 230, height: 76)
        }
        
    }
    
    func setContent(_ message: String) {
        
        if let data = try? JSONSerialization.data(withJSONObject: message.dictionaryValue) {
            let customMsg = try? JSONDecoder().decode(ZIMCustomMessage.self, from: data)
            giftMessageModel = customMsg
        }
    }
}
