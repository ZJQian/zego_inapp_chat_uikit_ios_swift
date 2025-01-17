//
//  ZIMKitCore+User.swift
//  ZIMKit
//
//  Created by Kael Ding on 2023/1/9.
//

import Foundation
import ZIM

extension ZIMKitCore {
    func connectUser(userID: String,
                     userName: String? = nil,
                     avatarUrl: String? = nil,
                     token: String?,
                     callback: ConnectUserCallback? = nil) {
        assert(zim != nil, "Must create ZIM first!!!")
        let zimUserInfo = ZIMUserInfo()
        zimUserInfo.userID = userID
        zimUserInfo.userName = userName ?? ""
        zim?.login(with: zimUserInfo, token: token~, callback: { [weak self] error in
            if error.code == .networkModuleUserHasAlreadyLogged {
                error.code = .success
                error.message = ""
            }
            if error.code == .success {
                self?.localUser = ZIMKitUser(userID: userID, userName: userName ?? "", avatarUrl: avatarUrl)
                self?.userDict[userID] = self?.localUser
            }
            if let userAvatarUrl = avatarUrl {
                self?.updateUserAvatarUrl(userAvatarUrl, callback: nil)
            }
            callback?(error)
        })
    }
    
    func disconnectUser() {
        zim?.logout()
        clearData()
    }
    
    func queryUserInfo(by userID: String, callback: QueryUserCallback? = nil) {
        let config = ZIMUsersInfoQueryConfig()
        config.isQueryFromServer = true
        zim?.queryUsersInfo(by: [userID], config: config, callback: { [weak self] fullInfos, errorUserInfos, error in
            var userInfo: ZIMKitUser?
            if let fullUserInfo = fullInfos.first {
                userInfo = ZIMKitUser(fullUserInfo)
            }
            self?.userDict[userID] = userInfo
            callback?(userInfo, error)
        })
    }
    
    func updateUserAvatarUrl(_ avatarUrl: String,
                             callback: UserAvatarUrlUpdateCallback? = nil) {
        zim?.updateUserAvatarUrl(avatarUrl, callback: { url, error in
            self.localUser?.avatarUrl = url
            callback?(url, error)
        })
    }
}
