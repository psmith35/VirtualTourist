//
//  ErrorResponse.swift
//  VirtualTourist
//
//  Created by Paul Smith on 7/11/21.
//

import Foundation

struct ErrorResponse : Codable {
    let error: String
    let status: Int
}

extension ErrorResponse : LocalizedError {
    var errorDescription: String? {
        return error
    }
}
