//
//  ZIMKitMessage.swift
//  ZIMKit
//
//  Created by Kael Ding on 2023/1/6.
//

import Foundation
import ZIM

public class MessageBaseInfo {
    public var messageID: Int64 = 0
    public var localMessageID: Int64 = 0
    public var senderUserID: String = ""
    public var conversationID: String = ""
    public var conversationType: ZIMConversationType = .peer
    public var direction: ZIMMessageDirection = .send
    public var sentStatus: ZIMMessageSentStatus = .sending
    public var timestamp: UInt64 = 0
    public var conversationSeq: Int64 = 0
    public var orderKey: Int64 = 0
    public var isUserInserted: Bool = false
    public var senderUserName: String?
    public var senderUserAvatarUrl: String?
}

public struct MediaTransferProgress {
    public let currentSize: UInt64
    public let totalSize: UInt64
    
    init(_ currentSize: UInt64, _ totalSize: UInt64) {
        self.currentSize = currentSize
        self.totalSize = totalSize
    }
    
    static let `default`: MediaTransferProgress = MediaTransferProgress(0, 1)
}

// {"msgType":""}，1：系统消息，2：视频通话结束时长消息，3：音频通话结束时长，4：关注
// 100: 邀请者主动取消   101： “被邀请者”拒绝
public enum MCMessageType: String {
    case mcSystem
    case videoCall
    case voiceCall
    case follow = "4"
    case visitor = "5"
    
    case callCancel = "100"
    case callReject = "101"
    case gift
    
    case zegoSystem = "200"
    case none
}

public class TextMessageContent {
    public var content: String = ""
    
    var isGiftMessage: Bool {
        if let _ = content.dictionaryValue["giftId"] as? String {
            return true
        }
        return false
    }
    
    var isFollowMessage: Bool {
        return des.msgType == .follow
    }
    
    public var isCustomMessage: Bool {
        return des.msgType == .gift ||
        des.msgType == .videoCall ||
        des.msgType == .voiceCall ||
        des.msgType == .callCancel ||
        des.msgType == .callReject ||
        des.msgType == .follow
    }
    
    public var isMCSystemMessage: Bool {
        return des.msgType == .mcSystem
    }
    
    public var isZegoSystemMessage: Bool {
        return des.msgType == .zegoSystem
    }
    
    
    public var des: (msgType: MCMessageType,
                     conversationListDes: String,
                     conversationDes: String) {
                        
        if let typeAny = content.dictionaryValue["msgType"] {
            
            var type: Int?
            if typeAny is String {
                type = (typeAny as? String)?.intValue
            } else if typeAny is Int {
                type = typeAny as? Int
            }
            if type == 1 {
                let message = content.dictionaryValue["message"] as? String
                let decodeStr = message?.removingPercentEncoding ?? ""
                
                return (MCMessageType.mcSystem, decodeStr~, decodeStr~)
            } else if type == 2 {
                
                let duration = (content.dictionaryValue["message"] as? String ?? "").intValue
                return (MCMessageType.videoCall,
                        "[video call] \(duration.formatSecondsToTime())",
                        "call ended \(duration.formatSecondsToTime())")
            } else if type == 3 {
                let duration = (content.dictionaryValue["message"] as? String ?? "").intValue
                return (MCMessageType.voiceCall,
                        "[voice call] \(duration.formatSecondsToTime())",
                        "call ended \(duration.formatSecondsToTime())")
            } else if type == 100 {
                return (MCMessageType.callCancel,
                        "[call cancel]",
                        "call cancel")
            } else if type == 101 {
                return (MCMessageType.callReject,
                        "[call reject]",
                        "call reject")
            } else if type == 4 {
                
                var listDes = ""
                let json = content.dictionaryValue["message"]
                var dic: [String: Any]?
                if json is [String: Any] {
                    dic = json as? [String: Any]
                } else if json is String {
                    dic = (json as? String)?.dictionaryValue
                }
                
                let beFollowId = dic?["beFollowId"] as? String
                let beFollowName = dic?["beFollowName"] as? String ?? ""
                let followName = dic?["followName"] as? String ?? ""
                if beFollowId == UserManager.user?.id {
                    listDes = R.string.localizable.followedYou(followName)
                } else {
                    listDes = R.string.localizable.youFollowed(beFollowName)
                }

                return (MCMessageType.follow,
                        listDes,
                        "")
            } else if type == 200 {
                let msg = content.dictionaryValue["message"] as? String ?? ""
                return (MCMessageType.zegoSystem,
                        msg,
                        "")
            } else if type == 5 {
                
                let messageJson = (content.dictionaryValue["message"] as? String)?.removingPercentEncoding?.dictionaryValue
                let userName = messageJson?["userName"] as? String ?? ""
                let vistor = "\(userName) came to visitor you"
                return (MCMessageType.visitor, vistor, "")
            }
        } else {
            
            if isGiftMessage {
                return (MCMessageType.gift,
                        "[Gift]",
                        "")
            }
        }
        
        return (MCMessageType.none,
                content,
                content)
    }
}

public class SystemMessageContent {
    public var content: String = ""
}

public class ImageMessageContent {
    public var fileLocalPath: String = ""
    public var fileDownloadUrl: String = ""
    public var fileUID: String = ""
    public var fileName: String = ""
    public var fileSize: Int64 = 0
    
    public var thumbnailDownloadUrl: String = ""
    public var thumbnailLocalPath: String = ""
    public var largeImageDownloadUrl: String = ""
    public var largeImageLocalPath: String = ""
    public var originalSize: CGSize = .zero
    public var largeSize: CGSize = .zero
    public var thumbnailSize: CGSize = .zero
    
    public var uploadProgress: MediaTransferProgress = .default
    public var downloadProgress: MediaTransferProgress = .default
}

public class AudioMessageContent {
    public var fileLocalPath: String = ""
    public var fileDownloadUrl: String = ""
    public var fileUID: String = ""
    public var fileName: String = ""
    public var fileSize: Int64 = 0
    
    public var duration: UInt32 = 0
    
    public var uploadProgress: MediaTransferProgress = .default
    public var downloadProgress: MediaTransferProgress = .default
}

public class VideoMessageContent {
    public var fileLocalPath: String = ""
    public var fileDownloadUrl: String = ""
    public var fileUID: String = ""
    public var fileName: String = ""
    public var fileSize: Int64 = 0
    
    public var duration: UInt32 = 0
    public var firstFrameDownloadUrl: String = ""
    public var firstFrameLocalPath: String = ""
    public var firstFrameSize: CGSize = .zero
    
    public var uploadProgress: MediaTransferProgress = .default
    public var downloadProgress: MediaTransferProgress = .default
}

public class FileMessageContent {
    public var fileLocalPath: String = ""
    public var fileDownloadUrl: String = ""
    public var fileUID: String = ""
    public var fileName: String = ""
    public var fileSize: Int64 = 0
    
    public var uploadProgress: MediaTransferProgress = .default
    public var downloadProgress: MediaTransferProgress = .default
}

public class CustomMessageContent {
    public var giftId: String = ""
    public var giftName: String = ""
    public var giftNum: Int = 0
}

final public class ZIMKitMessage: NSObject {
    var zim: ZIMMessage? = nil
    
    public var type: ZIMMessageType = .unknown
    
    public let info: MessageBaseInfo = .init()
    public let textContent: TextMessageContent = .init()
    public let systemContent: SystemMessageContent = .init()
    public let imageContent: ImageMessageContent = .init()
    public let audioContent: AudioMessageContent = .init()
    public let videoContent: VideoMessageContent = .init()
    public let fileContent: FileMessageContent = .init()
    public let customContent: CustomMessageContent = .init()

    init(with zim: ZIMMessage) {
        self.zim = zim
        super.init()
        update(with: zim)
    }
    
    override init() {
        
    }
}

