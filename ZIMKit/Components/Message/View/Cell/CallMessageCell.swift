//
//  CallMessageCell.swift
//  MatChat
//
//  Created by admin on 2023/5/26.
//

import UIKit

class CallMessageCell: BubbleMessageCell {
    
    override class var reuseId: String {
        return String(describing: CallMessageCell.self)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    lazy var iconImgView: UIImageView = {
        let imgview = UIImageView()
        imgview.image = UIImage(named: "icon_call_end")
        return imgview
    }()
    
    lazy var callEndLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.avenirNextMediumFont(ofSize: 16)
        label.textColor = UIColor.black
        return label
    }()
    
    override func setUp() {
        super.setUp()
                
        bubbleView.addSubview(iconImgView)
        iconImgView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        
        bubbleView.addSubview(callEndLabel)
        callEndLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconImgView.snp.right).offset(10)
        }
        
        bubbleView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        bubbleView.addGestureRecognizer(tap)
    }
    
    @objc func tapAction() {
        
        guard let messageVM = messageVM as? CallMessageViewModel else { return }
        let id = messageVM.message.info.conversationID
        if messageVM.callType == .voiceCall {
            CallManager.shared.call(id, .voice, callSource: .im)
        } else {
            CallManager.shared.call(id, .video, callSource: .im)
        }
    }

    
    override func updateContent() {
        super.updateContent()
        
        guard let messageVM = messageVM as? CallMessageViewModel else { return }
        callEndLabel.text = messageVM.callDuration
        if messageVM.callType == .videoCall {
            iconImgView.image = UIImage(named: "icon_callend_video")
        } else {
            iconImgView.image = UIImage(named: "icon_call_end")
        }
    }
}
