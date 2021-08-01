//
//  PhotoResponseList.swift
//  VirtualTourist
//
//  Created by Paul Smith on 7/25/21.
//

struct PhotoResponseList: Codable {
    let page, pages, perpage, total: Int
    let photo: [PhotoResponse]
}
