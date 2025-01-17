//
//  ZIMKitCore.swift
//  Pods-ZegoPlugin
//
//  Created by Kael Ding on 2022/12/8.
//

import Foundation
import ZIM

class ZIMKitCore: NSObject {
    static let shared = ZIMKitCore()
    
    private(set) var zim: ZIM? = nil
    
    var localUser: ZIMKitUser?
    
    lazy var dataPath: String = {
        let path = NSHomeDirectory() + "/Documents/ZIMKitSDK/" + (localUser?.id ?? "temp")
        return path
    }()
    
    var conversations: [ZIMKitConversation] = []
    var messageList: MessageList = MessageList()
    var groupMemberDict: GroupMemberDict = .init()
    var userDict: ThreadSafeDictionary<String, ZIMKitUser> = .init()
    
    var isLoadedAllConversations = false
    var isConversationInit = false
    
    let delegates: NSHashTable<ZIMKitDelegate> = NSHashTable(options: .weakMemory)
    
    func initWith(appID: UInt32, appSign: String) {
        ZegoUIKitSignalingPlugin.shared.initWith(appID: appID, appSign: appSign)
        zim = ZIM.shared()
        ZegoUIKitSignalingPlugin.shared.registerZIMEventHandler(self)
    }
    
    func registerZIMKitDelegate(_ delegate: ZIMKitDelegate) {
        delegates.add(delegate)
    }
    
    func clearData() {
        conversations.removeAll()
        messageList.clear()
        groupMemberDict.clear()
        userDict.removeAll()
        
        isLoadedAllConversations = false
        isConversationInit = false
        localUser = nil
    }
}
