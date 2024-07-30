//
//  View+extensions.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//

import SwiftUI

extension View {
    //// View Alignment
    @ViewBuilder
    func hSpacing (_ alignment: Alignment = .center) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: alignment)
    }
    
    @ViewBuilder
    func vSpacing (_ alignment: Alignment = .center) -> some View {
        self
            .frame(maxHeight: .infinity, alignment: alignment)
    }
    
    /// Disable with opacity
    @ViewBuilder
    func disableWithOpacity(_ condition: Bool) -> some View {
        self
            .disabled(condition)
            .opacity(condition ? 0.5 : 1)
    }
}
