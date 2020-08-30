//
//  ProfileViewModel.swift
//  BasicChat
//
//  Created by Brian Zhu on 8/30/20.
//  Copyright © 2020 Brian Zhu. All rights reserved.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}
