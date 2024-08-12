//
//  ResponsiveView.swift
//  QGS
//
//  Created by Edin Martinez on 8/12/24.
//

import SwiftUI

struct ResponsiveView: View {
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
//    var content: (Properties)-> Content
//    
//    init(@ViewBuilder content: @escaping (Properties)->Content){
//        self.content = content
//    }
    var body: some View {
        Text("Hola Mundo")
    }
//        GeometryReader{proxy in
//        let size = proxy.size
//            let isLandscape = size.width > size.height
//            let isIpad = UIDevice.current.userInterfaceIdiom == .pad
//            let isMaxSplit = isSplit() && size.width < 400
//            let properties = Properties(isLandscape: isLandscape, isIpad:isIpad, isSplit: isSplit(), isMaxSplit: isMaxSplit, size: size)
//            content(properties)
//                .frame(width: size.width, height: size.height)
//            
//        }
//    }
//    func isSplit() ->Bool{
//        guard let screen = UIApplication.shared.connectedScenes.first as? UIWindowScene
//        else{return false}
//        return screen.windows.first?.frame.size != screen.screen.bounds.size
  //  }
}
