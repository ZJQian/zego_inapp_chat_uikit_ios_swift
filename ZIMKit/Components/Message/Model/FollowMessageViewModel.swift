//
//  FollowMessageViewModel.swift
//  MatChat
//
//  Created by admin on 2023/7/3.
//

import UIKit

class FollowMessageViewModel: MessageViewModel {

    public var followContent: String?
    private var followMessage: ZIMKitMessage?
    
    override init(with msg: ZIMKitMessage) {
        super.init(with: msg)
        setContent(msg.textContent)
        followMessage = msg
    }
    
    convenience init(with content: String) {
        let msg = ZIMKitMessage()
        msg.textContent.content = content
        self.init(with: msg)
    }
    
    
    override var contentSize: CGSize {
        let size = (followContent as? NSString)?.boundingRect(with: CGSize(width: CGFloat(CGFLOAT_MAX), height: 17), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.avenirMediumFont(ofSize: 12)], context: nil).size
        return CGSize(width: (size?.width ?? 0)+30, height: 40)
    }
    
    func setContent(_ message: TextMessageContent) {
        
        var json = message.content.dictionaryValue["message"]
        var dic: [String: Any]?
        if json is [String: Any] {
            dic = json as? [String: Any]
        } else if json is String {
            dic = (json as? String)?.dictionaryValue
        }
        let beFollowName = dic?["beFollowName"] as? String ?? ""
        let followName = dic?["followName"] as? String ?? ""
        if self.message.info.direction == .send {
            followContent = "You have followed \(beFollowName)"
        } else {
            followContent = "\(followName) is following you now"
        }

    }
}
