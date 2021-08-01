//
//  PhotoResponse.swift
//  VirtualTourist
//
//  Created by Paul Smith on 7/11/21.
//

import Foundation

struct PhotoResponse : Codable {
    
    let id, owner, secret, server: String
    let farm: Int
    let title: String
    let ispublic, isfriend, isfamily: Int
        
    var urlStringValue: String {
        return "https://live.staticflickr.com/\(server)/\(id)_\(secret)_q.jpg"
    }
    
}
