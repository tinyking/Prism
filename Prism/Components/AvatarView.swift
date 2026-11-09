//
//  AvatarView.swift
//  Prism
//
//  Created by 王建朝 on 2026/10/27.
//

import SwiftUI

struct AvatarView: View {
    let initials: String
    var size: CGFloat = 21

    var body: some View {
        Text(initials)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: size, height: size)
            .background(Color(nsColor: .quaternaryLabelColor), in: Circle())
    }
}
