//
//  TextMessage.swift
//  ZIMKit
//
//  Created by Kael Ding on 2022/8/15.
//

import Foundation
import ZIM
import UIKit

let MessageCell_Text_Max_Width = UIScreen.main.bounds.width - 150.0

class TextMessageViewModel: MessageViewModel {

    /// The attributed text of the text message.
    var attributedContent = NSAttributedString(string: "")
    
    private var content: String?

    override init(with msg: ZIMKitMessage) {
        super.init(with: msg)
        setContent(msg.textContent)
    }

    convenience init(with content: String) {
        let msg = ZIMKitMessage()
        msg.textContent.content = content
        self.init(with: msg)
    }

    override var contentSize: CGSize {
        if _contentSize == .zero {
            
            
//            var size = attributedContent.boundingRect(with: CGSize(width: MessageCell_Text_Max_Width,
//                                                                   height: CGFloat(MAXFLOAT)),
//                                                      options: .usesLineFragmentOrigin, context: nil).size
            var size = (content as? NSString ?? "").boundingRect(with: CGSize(width: MessageCell_Text_Max_Width, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [.font: cellConfig.messageTextFont], context: nil).size
//            if size.height < MessageCell_Default_Content_Height {
//                size.height = MessageCell_Default_Content_Height
//            }
            size.width += 1.0
            size.height += 2
            _contentSize = size
        }
        return _contentSize
    }
}

extension TextMessageViewModel {
    func setContent(_ textContent: TextMessageContent) {
        
        if textContent.isMCSystemMessage {
            
            // ["schema": matchatxxxxxx, "schemaName": %E7%82%B9%E6%88%91, "message": %E4%B8%8D%E9%80%9A%E8%BF%87, "msgType": 1]
            let message = textContent.des.conversationDes
            let schema = (textContent.content.dictionaryValue["schemaName"] as? String)?.removingPercentEncoding ?? ""
            var btnName = schema
            if schema.count > 0 {
                btnName = "\n\n\(schema)"
            }
            let str = message+btnName
            
            printLog(str)
            let attributedStr = NSMutableAttributedString(string: str)
            
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
//            paragraphStyle.minimumLineHeight = 21.0

            let attributes: [NSAttributedString.Key : Any] = [.font : cellConfig.messageTextFont,
                                                              .paragraphStyle : paragraphStyle,
                                                              .foregroundColor : cellConfig.messageTextColor]

            attributedStr.setAttributes(attributes, range: NSRange(location: 0, length: message.count))
            attributedStr.setAttributes([.font : cellConfig.messageTextFont,
                                         .paragraphStyle : paragraphStyle,
                                         .foregroundColor: UIColor.hexColor("#A569F5"),
                                         .underlineStyle: NSNumber(value: NSUnderlineStyle.single.rawValue),
                                         .underlineColor: UIColor.hexColor("#A569F5")],
                                        range: NSRange(location: message.count, length: btnName.count))
            
            attributedContent = attributedStr
            
            content = str
            
        } else {
            
            let message = textContent.content
            
            content = message

            let attributedStr = NSMutableAttributedString(string: message)

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
//            paragraphStyle.minimumLineHeight = 21.0

            let attributes: [NSAttributedString.Key : Any] = [.font : cellConfig.messageTextFont,
                                                              .paragraphStyle : paragraphStyle,
                                                              .foregroundColor : cellConfig.messageTextColor]

            attributedStr.setAttributes(attributes, range: NSRange(location: 0, length: attributedStr.length))

            attributedContent = attributedStr
            
        }
        
    }
}
