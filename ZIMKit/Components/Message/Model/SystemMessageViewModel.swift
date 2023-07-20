//
//  SystemMessage.swift
//  ZIMKit
//
//  Created by Kael Ding on 2022/8/16.
//

import Foundation
import ZIM

let MessageCell_System_Max_Width = UIScreen.main.bounds.width - 60.0

class SystemMessageViewModel: MessageViewModel {

    convenience init(with content: String) {
        let msg = ZIMKitMessage()
        msg.textContent.content = content
        self.init(with: msg)
        msg.type = .system
        cellConfig.contentInsets = .zero
        self.content = content
        setContent(content)
    }
    
    override init(with msg: ZIMKitMessage) {
        super.init(with: msg)
        setContent(msg.textContent.content)
    }

//    var content: String = "" {
//        didSet {
//            setContent(content)
//        }
//    }
    var content = ""
    var schemaName = ""
    var schema = ""


    override var contentSize: CGSize {
        if _contentSize == .zero {
            var str = content
            if schema == MCRouterType.sendGift.rawValue {
                
                if schemaName.count > 0 {
                    str += schemaName
                }
                
                var size = (str as NSString).boundingRect(with: CGSize(width: CGFLOAT_MAX, height: 17), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.avenirMediumFont(ofSize: 12)], context: nil).size
                size.width += 24
                size.height = 40
                _contentSize = size
                
            } else {
                
                if schemaName.count > 0 {
                    str += "\n\(schemaName)"
                }
                
                var size = (str as NSString).boundingRect(with: CGSize(width: UIScreen.width-30-24, height: CGFloat(MAXFLOAT)), options: .usesLineFragmentOrigin, attributes: [.font: UIFont.avenirMediumFont(ofSize: 12)], context: nil).size
                if size.height < MessageCell_Default_Content_Height {
                    size.height = MessageCell_Default_Content_Height
                }
                size.width = UIScreen.width-30
                size.height += 24
                _contentSize = size
            }
            
            
            
        }
        return _contentSize
    }
}

extension SystemMessageViewModel {
    func setContent(_ message: String) {
//        let attributedStr = NSMutableAttributedString(string: message)
//
//        let paragraphStyle = NSMutableParagraphStyle()
//        paragraphStyle.lineBreakMode = .byCharWrapping
//        paragraphStyle.minimumLineHeight = 21.0
//        paragraphStyle.alignment = .center
//
//        let attributes: [NSAttributedString.Key : Any] = [.font : UIFont.systemFont(ofSize: 13, weight: .medium),
//                                                          .paragraphStyle : paragraphStyle,
//                                                          .foregroundColor: UIColor.zim_textGray2]
//
//        attributedStr.setAttributes(attributes, range: NSRange(location: 0, length: attributedStr.length))

        let dic = message.dictionaryValue
        let messageText = dic["message"] as? String
        let btnTitle = dic["schemaName"] as? String
        let mySchema = dic["schema"] as? String
        schemaName = btnTitle~
        schema = mySchema~
        content = messageText~
    }
}
