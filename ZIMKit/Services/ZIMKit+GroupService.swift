//
//  ZIMKit+GroupService.swift
//  ZIMKit
//
//  Created by Kael Ding on 2022/12/29.
//

import Foundation

extension ZIMKit {
    public static func createGroup(with groupName: String,
                                   groupID: String = "",
                                   inviteUserIDs: [String],
                                   callback: CreateGroupCallback? = nil) {
        ZIMKitCore.shared.createGroup(with: groupName,
                                      groupID: groupID,
                                      inviteUserIDs: inviteUserIDs,
                                      callback: callback)
    }
    
    public static func joinGroup(by groupID: String, callback: JoinGroupCallback? = nil) {
        ZIMKitCore.shared.joinGroup(by: groupID, callback: callback)
    }
    
    public static func leaveGroup(by groupID: String, callback: LeaveGroupCallback? = nil) {
        ZIMKitCore.shared.leaveGroup(by: groupID, callback: callback)
    }
    
    public static func inviteUsersToJoinGroup(with userIDs: [String],
                                              groupID: String,
                                              callback: InviteUsersToJoinGroupCallback? = nil) {
        ZIMKitCore.shared.inviteUsersToJoinGroup(with: userIDs,
                                                 groupID: groupID,
                                                 callback: callback)
    }
    
    public static func queryGroupInfo(by groupID: String,
                                      callback: QueryGroupInfoCallback? = nil) {
        ZIMKitCore.shared.queryGroupInfo(by: groupID, callback: callback)
    }
    
    public static func queryGroupMemberInfo(by userID: String,
                                            groupID: String,
                                            callback: QueryGroupMemberInfoCallback? = nil) {
        ZIMKitCore.shared.queryGroupMemberInfo(by: userID, groupID: groupID, callback: callback)
    }
}
