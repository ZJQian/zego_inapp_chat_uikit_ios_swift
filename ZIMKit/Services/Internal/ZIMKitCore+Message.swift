//
//  ZIMKitCore+Message.swift
//  ZIMKit
//
//  Created by Kael Ding on 2023/1/9.
//

import Foundation
import ZIM
import SwiftyUserDefaults

let queryMessagePageCount = 30

extension ZIMKitCore {
    func getMessageList(with conversationID: String,
                        type: ZIMConversationType,
                        callback: GetMessageListCallback? = nil) {
//        var messages = messageList.get(conversationID, type: type)
//        messages.removeAll()
//        if messages.count >= queryMessagePageCount {
//            let error = ZIMError()
//            error.code = .success
//            callback?(messages, true, error)
//        } else {
//            loadMoreMessage(with: conversationID, type: type, isCallbackListChanged: false, nextMessage: nil) { [weak self] error in
//                let messages = self?.messageList.get(conversationID, type: type) ?? []
//                let hasMore: Bool = messages.count >= queryMessagePageCount
//                callback?(messages, hasMore, error)
//            }
//        }
        

        let config = ZIMMessageQueryConfig()
        config.count = UInt32(queryMessagePageCount)
        config.reverse = true

        zim?.queryHistoryMessage(by: conversationID, conversationType: type, config: config, callback: { [weak self] _, _, zimMessages, error in

            let kitMessages = zimMessages.compactMap({ ZIMKitMessage(with: $0) })
            for kitMessage in kitMessages {
                self?.updateKitMessageProperties(kitMessage)
                self?.updateKitMessageMediaProperties(kitMessage)
            }
            let hasMore: Bool = kitMessages.count >= queryMessagePageCount
            callback?(kitMessages, hasMore, error)
        })

    }
    
    func loadMoreMessage(with conversationID: String,
                         type: ZIMConversationType,
                         isCallbackListChanged: Bool = true,
                         nextMessage: ZIMMessage?,
                         callback: LoadMoreMessageCallback? = nil) {
        let config = ZIMMessageQueryConfig()
        config.count = UInt32(queryMessagePageCount)
        config.nextMessage = nextMessage
        config.reverse = true
        
        zim?.queryHistoryMessage(by: conversationID, conversationType: type, config: config, callback: { [weak self] _, _, zimMessages, error in
            let kitMessages = zimMessages.compactMap({ ZIMKitMessage(with: $0) })
            for kitMessage in kitMessages {
                self?.updateKitMessageProperties(kitMessage)
                self?.updateKitMessageMediaProperties(kitMessage)
            }
//            self?.messageList.add(kitMessages, isNewMessage: false)
            
            callback?(error)
            if isCallbackListChanged == false { return }
            for delegate in self?.delegates.allObjects ?? [] {
                delegate.onHistoryMessageLoaded?(conversationID, type: type, messages: kitMessages)
            }
        })
    }
    
    
    func sendMCSystemMessage(_ text: String,
                           router: MCRouterType? = nil,
                           to conversationID: String,
                           callback: MessageSentCallback? = nil) {
        
        
        var params = ["message": text,
                      "msgType": MCMessageType.zegoSystem.rawValue]
        if let router {
            params["schema"] = router.rawValue
            params["schemaName"] = router.btnTitle
        }
        
        let message = ZIMTextMessage(message: params.jsonString)
        
        var kitMessage = ZIMKitMessage(with: message)
        for delegate in delegates.allObjects {
            if let method = delegate.onMessagePreSending {
                guard let msg = method(kitMessage) else { return }
                kitMessage = msg
            }
        }
        kitMessage.info.senderUserName = localUser?.name
        kitMessage.info.senderUserAvatarUrl = localUser?.avatarUrl
        
        let mMsg = ZIMKitMessage(with: message)
//        mMsg.info.conversationID = conversationID
//        self.messageList.add([mMsg])
        for delegate in self.delegates.allObjects {
            delegate.onMessageSentStatusChanged?(mMsg)
        }
        
        if router == .sendGift {
            var params = Defaults.haveSendGiftReplyMessageDic
            if let timestamp = params[conversationID] ?? 0, timestamp.isToday() {

                return
            } else {
                params[conversationID] = Date.currentSecondTimeStamp
                Defaults.haveSendGiftReplyMessageDic = params
            }
        }
        
        zim?.insertMessageToLocalDB(message, conversationID: conversationID, conversationType: .peer, senderUserID: localUser?.id ?? "", callback: { zimMessage, error in
            let msg = self.messageList.get(with: zimMessage)
            msg.update(with: zimMessage)
            for delegate in self.delegates.allObjects {
                delegate.onMessageSentStatusChanged?(msg)
            }
            callback?(error)
        })
    }
    
    
    func sendTextMessage(_ text: String,
                         to conversationID: String,
                         type: ZIMConversationType,
                         callback: MessageSentCallback? = nil) {
        let message = ZIMTextMessage(message: text)
        
        var kitMessage = ZIMKitMessage(with: message)
        for delegate in delegates.allObjects {
            if let method = delegate.onMessagePreSending {
                guard let msg = method(kitMessage) else { return }
                kitMessage = msg
            }
        }
        kitMessage.info.senderUserName = localUser?.name
        kitMessage.info.senderUserAvatarUrl = localUser?.avatarUrl
        
        let pushConfig = ZIMPushConfig()
        pushConfig.title = localUser?.name ?? ""
        pushConfig.content = text
        let config = ZIMMessageSendConfig()
        let notification = ZIMMessageSendNotification()
        config.pushConfig = pushConfig
        notification.onMessageAttached = { message in
            let message = ZIMKitMessage(with: message)
            self.messageList.add([message])
            for delegate in self.delegates.allObjects {
                delegate.onMessageSentStatusChanged?(message)
            }
        }
        MCTrackManager.shared.track(body: ["data": "im_send",
                                           "type": "text"])
        zim?.sendMessage(message, toConversationID: conversationID, conversationType: type, config: config, notification: notification, callback: { message, error in
            let msg = self.messageList.get(with: message)
            msg.update(with: message)
            for delegate in self.delegates.allObjects {
                delegate.onMessageSentStatusChanged?(msg)
            }
            callback?(error)
        })
    }
    
    func sendCallMessage(_ msgType: MCMessageType,
                         to conversationID: String) {
        
        let params = ["msgType": msgType.rawValue]
        let textMessage = ZIMTextMessage(message: params.jsonString)
        var kitMessage = ZIMKitMessage(with: textMessage)
        for delegate in delegates.allObjects {
            if let method = delegate.onMessagePreSending {
                guard let msg = method(kitMessage) else { return }
                kitMessage = msg
            }
        }
        kitMessage.info.senderUserName = localUser?.name
        kitMessage.info.senderUserAvatarUrl = localUser?.avatarUrl
        
        let config = ZIMMessageSendConfig()
        config.priority = .medium
        let notification = ZIMMessageSendNotification()
        notification.onMessageAttached = { [weak self] message in
            guard let self else { return }
            let message = ZIMKitMessage(with: message)
            self.messageList.add([message])
            for delegate in self.delegates.allObjects {
                delegate.onMessageSentStatusChanged?(message)
            }
        }
        
        zim?.sendMessage(textMessage, toConversationID: conversationID, conversationType: .peer, config: config, notification: notification, callback: { [weak self] message, error in
            guard let self else { return }
            let msg = self.messageList.get(with: message)
            msg.update(with: message)
            for delegate in self.delegates.allObjects {
                delegate.onMessageSentStatusChanged?(msg)
            }
        })
    }
    
    func sendFollowMessage(_ beFollowId: String,
                           beFollowName: String,
                           followId: String,
                           followName: String,
                           conversationID: String,
                           callback: MessageSentCallback? = nil) {
        
        let params = ["message": ["beFollowId": beFollowId,
                                  "beFollowName": beFollowName,
                                  "followId": followId,
                                  "followName": followName],
                      "msgType": MCMessageType.follow.rawValue] as [String : Any]
        
        let textMessage = ZIMTextMessage(message: params.jsonString)
        var kitMessage = ZIMKitMessage(with: textMessage)
        for delegate in delegates.allObjects {
            if let method = delegate.onMessagePreSending {
                guard let msg = method(kitMessage) else { return }
                kitMessage = msg
            }
        }
        kitMessage.info.senderUserName = localUser?.name
        kitMessage.info.senderUserAvatarUrl = localUser?.avatarUrl
        
        let config = ZIMMessageSendConfig()
        config.priority = .medium
        let notification = ZIMMessageSendNotification()
        notification.onMessageAttached = { [weak self] message in
            guard let self else { return }
            let message = ZIMKitMessage(with: message)
            self.messageList.add([message])
            for delegate in self.delegates.allObjects {
                delegate.onMessageSentStatusChanged?(message)
            }
        }
        
        zim?.sendMessage(textMessage, toConversationID: conversationID, conversationType: .peer, config: config, notification: notification, callback: { [weak self] message, error in
            guard let self else { return }
            let msg = self.messageList.get(with: message)
            msg.update(with: message)
            for delegate in self.delegates.allObjects {
                delegate.onMessageSentStatusChanged?(msg)
            }
            callback?(error)
        })
    }
    
    func sendCustomMessage(_ giftName: String,
                           giftId: String,
                           giftNum: Int,
                           giftImage: String,
                           giftPrice: Int,
                         to conversationID: String,
                         callback: MessageSentCallback? = nil) {
        
        let params = ["giftId": giftId,
                      "giftName": giftName,
                      "giftPrice": giftPrice,
                      "giftNum": giftNum,
                      "giftImage": giftImage,
                      "fromName": UserManager.user?.nickName ?? ""] as [String : Any]
        
        let textMessage = ZIMTextMessage(message: params.jsonString)
        var kitMessage = ZIMKitMessage(with: textMessage)
        for delegate in delegates.allObjects {
            if let method = delegate.onMessagePreSending {
                guard let msg = method(kitMessage) else { return }
                kitMessage = msg
            }
        }
        kitMessage.info.senderUserName = localUser?.name
        kitMessage.info.senderUserAvatarUrl = localUser?.avatarUrl
        
        let config = ZIMMessageSendConfig()
        config.priority = .medium
        let notification = ZIMMessageSendNotification()
        notification.onMessageAttached = { [weak self] message in
            guard let self else { return }
            let message = ZIMKitMessage(with: message)
            self.messageList.add([message])
            for delegate in self.delegates.allObjects {
                delegate.onMessageSentStatusChanged?(message)
            }
        }
        MCTrackManager.shared.track(body: ["data": "im_send",
                                           "type": "gift"])
        zim?.sendMessage(textMessage, toConversationID: conversationID, conversationType: .peer, config: config, notification: notification, callback: { [weak self] message, error in
            guard let self else { return }
            let msg = self.messageList.get(with: message)
            msg.update(with: message)
            for delegate in self.delegates.allObjects {
                delegate.onMessageSentStatusChanged?(msg)
            }
            callback?(error)
        })
    }
    
    func sendImageMessage(_ imagePath: String,
                          to conversationID: String,
                          type: ZIMConversationType,
                          callback: MessageSentCallback? = nil) {
        
        if !FileManager.default.fileExists(atPath: imagePath) {
            assert(false, "Path doesn't exist.")
            return
        }
        
        // transform heic to jpg.
        var imagePath = imagePath
        let url = URL(fileURLWithPath: imagePath)
        if url.pathExtension == "heic",
            let data = try? Data(contentsOf: url) {
            let image = UIImage(data: data)
            let imageData = image?.jpegData(compressionQuality: 0.8)
            imagePath = url.deletingPathExtension().path + ".jpg"
            FileManager.default.createFile(atPath: imagePath, contents: imageData)
        }
        
        let filePath = generateFilePath(imagePath, conversationID, type, .image)
        try? FileManager.default.copyItem(atPath: imagePath, toPath: filePath)
        
        MCTrackManager.shared.track(body: ["data": "im_send",
                                           "type": "image"])
        let imageMessage = ZIMImageMessage(fileLocalPath: filePath)
        sendMediaMessage(imageMessage,
                         to: conversationID,
                         type: type,
                         callback: callback)
    }
    
    func sendAudioMessage(_ audioPath: String,
                          duration: UInt32 = 0,
                          to conversationID: String,
                          type: ZIMConversationType,
                          callback: MessageSentCallback? = nil) {
        
        if !FileManager.default.fileExists(atPath: audioPath) {
            assert(false, "Path doesn't exist.")
            return
        }
        
        let filePath = generateFilePath(audioPath, conversationID, type, .audio)
        try? FileManager.default.copyItem(atPath: audioPath, toPath: filePath)
        
        var audioDuration: UInt32 = duration
        if audioDuration == 0 {
            audioDuration = UInt32(AVTool.getDurationOfMediaFile(audioPath))
        }
        
        MCTrackManager.shared.track(body: ["data": "im_send",
                                           "type": "voice"])
        
        let audioMessage = ZIMAudioMessage(fileLocalPath: filePath, audioDuration: audioDuration)
        sendMediaMessage(audioMessage, to: conversationID, type: type, callback: callback)
    }
    
    func sendVideoMessage(_ videoPath: String,
                          duration: UInt32 = 0,
                          to conversationID: String,
                          type: ZIMConversationType,
                          callback: MessageSentCallback? = nil) {
        if !FileManager.default.fileExists(atPath: videoPath) {
            assert(false, "Path doesn't exist.")
            return
        }
        
        let filePath = generateFilePath(videoPath, conversationID, type, .video)
        try? FileManager.default.copyItem(atPath: videoPath, toPath: filePath)
        
        var videoDuration: UInt32 = duration
        if videoDuration == 0 {
            videoDuration = UInt32(AVTool.getDurationOfMediaFile(videoPath))
        }
                
        let videoMessage = ZIMVideoMessage(fileLocalPath: filePath, videoDuration: videoDuration)
        sendMediaMessage(videoMessage, to: conversationID, type: type, callback: callback)
    }
    
    func sendFileMessage(_ filePath: String,
                         to conversationID: String,
                         type: ZIMConversationType,
                         callback: MessageSentCallback? = nil) {
        
        if !FileManager.default.fileExists(atPath: filePath) {
            assert(false, "Path doesn't exist.")
            return
        }
        
        let newFilePath = generateFilePath(filePath, conversationID, type, .file)
        try? FileManager.default.copyItem(atPath: filePath, toPath: newFilePath)
        
        let fileMessage = ZIMFileMessage(fileLocalPath: newFilePath)
        sendMediaMessage(fileMessage, to: conversationID, type: type, callback: callback)
    }
    
    private func sendMediaMessage(_ message: ZIMMediaMessage,
                                  to conversationID: String,
                                  type: ZIMConversationType,
                                  callback: MessageSentCallback? = nil) {
        
        var kitMessage = ZIMKitMessage(with: message)
        kitMessage.info.senderUserName = localUser?.name
        kitMessage.info.senderUserAvatarUrl = localUser?.avatarUrl
        
        for delegate in delegates.allObjects {
            if let method = delegate.onMessagePreSending {
                guard let msg = method(kitMessage) else { return }
                kitMessage = msg
            }
        }
        
        let config = ZIMMessageSendConfig()
        let notification = ZIMMediaMessageSendNotification()
        notification.onMessageAttached = { [weak self] message in
            guard let self else { return }
            let message = ZIMKitMessage(with: message)
            self.updateKitMessageMediaProperties(message)
            self.messageList.add([message])
            for delegate in self.delegates.allObjects {
                delegate.onMessageSentStatusChanged?(message)
            }
        }
        notification.onMediaUploadingProgress = { [weak self] message, currentSize, totalSize in
            guard let self else { return }
            let message = self.messageList.get(with: message)
            message.updateUploadProgress(currentSize: currentSize, totalSize: totalSize)
            let isFinished: Bool = currentSize == totalSize
            for delegate in self.delegates.allObjects {
                delegate.onMediaMessageUploadingProgressUpdated?(message, isFinished: isFinished)
            }
        }
        zim?.sendMediaMessage(message,
                              toConversationID: conversationID,
                              conversationType: type,
                              config: config,
                              notification: notification,
                              callback: { [weak self] message, error in
            guard let self else { return }
            let msg = self.messageList.get(with: message)
            msg.update(with: message)
            for delegate in self.delegates.allObjects {
                delegate.onMessageSentStatusChanged?(msg)
            }
            callback?(error)
            
            if error.code != .success { return }
            if let message = msg.zim as? ZIMImageMessage {
                try? FileManager.default.removeItem(atPath: message.fileLocalPath)
            }
        })
    }
    
    func downloadMediaFile(with message: ZIMKitMessage,
                           callback: DownloadMediaFileCallback? = nil) {
        guard let zimMessage = message.zim as? ZIMMediaMessage else {
            let error = ZIMError()
            error.code = .failed
            callback?(error)
            return
        }
        zim?.downloadMediaFile(with: zimMessage, fileType: .originalFile, progress: { [weak self] msg, currentSize, totalSize in
            
            guard let self else { return }
            let message = self.messageList.get(with: msg)
            message.updateDownloadProgress(currentSize: currentSize, totalSize: totalSize)
            
            for delegate in self.delegates.allObjects {
                delegate.onMediaMessageDownloadingProgressUpdated?(message, isFinished:false)
            }

        }, callback: {[weak self] message, error in
            guard let self else { return }
            let msg = self.messageList.get(with: message)
            msg.update(with: message)
            let isFinished: Bool = error.code == .success
            for delegate in self.delegates.allObjects {
                delegate.onMediaMessageDownloadingProgressUpdated?(msg, isFinished: isFinished)
            }
            callback?(error)
        })
    }
    
    func deleteMessage(_ messages: [ZIMKitMessage],
                       callback: DeleteMessageCallback? = nil) {
        
        if messages.count == 0 {
            let error = ZIMError()
            error.code = .failed
            callback?(error)
            return
        }
        
        let zimMessages = messages.compactMap({ $0.zim })
        let config = ZIMMessageDeleteConfig()
        let type = messages.first!.info.conversationType
        let conversationID = messages.first!.info.conversationID
        
        self.messageList.delete(messages)
        for delete in delegates.allObjects {
            delete.onMessageDeleted?(conversationID, type: type, messages: messages)
        }
        
        zim?.deleteMessages(zimMessages, conversationID: conversationID, conversationType: type, config: config, callback: { _, _, error in
            callback?(error)
            if error.code != .success { return }
            for message in messages {
                if FileManager.default.fileExists(atPath: message.fileLocalPath) {
                    try? FileManager.default.removeItem(atPath: message.fileLocalPath)
                }
                
                if message.type == .image {
                    // remove image from cache.
                    ImageCache.removeCache(for: message.imageContent.thumbnailDownloadUrl)
                    ImageCache.removeCache(for: message.imageContent.largeImageDownloadUrl)
                    ImageCache.removeCache(for: message.imageContent.fileLocalPath)
                } else if message.type == .video {
                    ImageCache.removeCache(for: message.videoContent.firstFrameDownloadUrl)
                    ImageCache.removeCache(for: message.videoContent.firstFrameLocalPath)
                    if FileManager.default.fileExists(atPath: message.videoContent.firstFrameLocalPath) {
                        try? FileManager.default.removeItem(atPath: message.videoContent.firstFrameLocalPath)
                    }
                }
            }
        })
    }
        
    private func generateFilePath(_ oldPath: String,
                                  _ conversationID: String,
                                  _ conversationType: ZIMConversationType,
                                  _ messageType: ZIMMessageType) -> String {
        let oldUrl = URL(fileURLWithPath: oldPath)
        let fileName = oldUrl.lastPathComponent
        
        var filePathPrefix = ""
        switch messageType {
        case .image:
            filePathPrefix = ZIMKit.imagePath(conversationID, conversationType)
        case .audio:
            filePathPrefix = ZIMKit.audioPath(conversationID, conversationType)
        case .video:
            filePathPrefix = ZIMKit.videoPath(conversationID, conversationType)
        case .file:
            filePathPrefix = ZIMKit.filePath(conversationID, conversationType)
        default:
            break
        }
        
        var filePath = filePathPrefix + fileName
        
        /// if the file exist, rename the file.
        /// like `123.txt`, `123(1).txt`, `123(2).txt`
        var i = 0
        while FileManager.default.fileExists(atPath: filePath) {
            i += 1
            var newFileName = oldUrl.deletingPathExtension().lastPathComponent + "(\(i))"
            if oldUrl.pathExtension.count > 0 {
                newFileName += "." + oldUrl.pathExtension
            }
            filePath = filePathPrefix + newFileName
        }
        
        return filePath
    }
    
    func updateKitMessageProperties(_ message: ZIMKitMessage) {
        if message.info.conversationType == .peer {
            let user = userDict[message.info.senderUserID]
            message.info.senderUserName = user?.name
            message.info.senderUserAvatarUrl = user?.avatarUrl
        } else {
            let member = groupMemberDict.get(message.info.conversationID,
                                             message.info.senderUserID)
            message.info.senderUserName = member?.name
            message.info.senderUserAvatarUrl = member?.avatarUrl
        }
    }
    
    private func updateKitMessageMediaProperties(_ message: ZIMKitMessage) {
        if message.info.sentStatus == .sendSuccess { return }
        
        // media message
        var fileLocalPath = message.fileLocalPath
        if fileLocalPath.count > 0 &&
            !FileManager.default.fileExists(atPath: fileLocalPath) {
            
            let home = NSHomeDirectory()
            message.fileLocalPath = home + fileLocalPath[home.endIndex..<fileLocalPath.endIndex]
        }
        message.fileName = URL(fileURLWithPath: message.fileLocalPath).lastPathComponent
        let attributes = try? FileManager.default.attributesOfItem(atPath: message.fileLocalPath)
        message.fileSize = attributes?[.size] as? Int64 ?? 0
        
        fileLocalPath = message.fileLocalPath
        
        // image
        if message.type == .image &&
            fileLocalPath.count > 0 &&
            FileManager.default.fileExists(atPath: fileLocalPath) &&
            (message.imageContent.originalSize == .zero || message.imageContent.fileSize == 0) {
            
            let url = URL(fileURLWithPath: fileLocalPath)
            guard let data = try? Data(contentsOf: url) else { return }
            let image = UIImage(data: data)
            message.imageContent.originalSize = image?.size ?? .zero
            message.imageContent.fileSize = Int64(data.count)
        }
        
        // video
        if message.type == .video {
            var firstFrameLocalPath = message.videoContent.firstFrameLocalPath
            if firstFrameLocalPath.count > 0 &&
                !FileManager.default.fileExists(atPath: firstFrameLocalPath) {
                
                let home = NSHomeDirectory()
                message.videoContent.firstFrameLocalPath = home + firstFrameLocalPath[home.endIndex..<firstFrameLocalPath.endIndex]
            }
            
            firstFrameLocalPath = message.videoContent.firstFrameLocalPath
            if message.videoContent.firstFrameSize != .zero && FileManager.default.fileExists(atPath: firstFrameLocalPath) {
                return
            }
                        
            let url = URL(fileURLWithPath: message.videoContent.fileLocalPath)
            let videoInfo = AVTool.getFirstFrameImageAndDuration(with: url)
            message.videoContent.firstFrameSize = videoInfo.image?.size ?? .zero
            message.videoContent.firstFrameLocalPath = url.deletingPathExtension().path + ".png"
            if !FileManager.default.fileExists(atPath: message.videoContent.firstFrameLocalPath) {
                let data = videoInfo.image?.pngData()
                try? data?.write(to: URL(fileURLWithPath: message.videoContent.firstFrameLocalPath))
            }
        }
    }
}
