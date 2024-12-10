//
//  PopUp.swift
//  QGS
//
//  Created by Edin Martinez on 11/25/24.
//

import SwiftUI
//
//struct ModalView: View {
//    @Binding var isShowing: Bool
//    @State var currentHeight: CGFloat = 400
//    
//    let minHeight: CGFloat = 400
//    let maxHeight: CGFloat = 700
//    var body: some View {
//        ZStack(alignment: .bottom) {
//            if isShowing {
//                Color.black.opacity(0.5)
//                    .ignoresSafeArea()
//                    .onTapGesture {
//                        isShowing = false
//                    }
//                mainView.transition(.move(edge: .bottom))
//                
//            }
//        }
//    }
//    
//    var mainView: some View {
//        GeometryReader { geometry in
//            VStack(alignment: .leading) {
//                Spacer()
//                Text("Es Obligatorio activar el GPS para regitrar su ingreso y salida del trabajo.!!!!").frame(alignment:.center)
//                    .font(.title)
//                    .padding()
//                Spacer()
//            }
//            .frame(height: min(max(currentHeight, minHeight), maxHeight))
//        }
//    }
//    
//    @State private var prevDragTranslation = CGSize.zero
//    
//    var dragGesture: some Gesture {
//        DragGesture(minimumDistance: 0, coordinateSpace: .global)
//            .onChanged { val in
//                let dragAmount = val.translation.height -  prevDragTranslation.height
//                if currentHeight > maxHeight || currentHeight < minHeight{
//                   currentHeight -= dragAmount/6
//                }else{
//                    currentHeight -= dragAmount
//                }
//                prevDragTranslation = val.translation
//            }
//            
//            .onEnded { val in
//                prevDragTranslation = .zero
//            }
//    }
//}

