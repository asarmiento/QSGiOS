//
//  CustomTF.swift
//  QGS
//
//  Created by Edin Martinez on 7/24/24.
//

import SwiftUI

struct CustomTF : View {
    var sfIcon: String
    var iconTint: Color = .gray
    var hint: String
    ///Hiden TextField
    var isPassword: Bool = false
    @Binding var value: String
    @State private var shoePassword = false 
    var body: some View {
        HStack(alignment: .top, spacing: 8, content: {
            Image(systemName: sfIcon)
                .foregroundStyle(iconTint)
                .frame(width: 30)
            VStack(alignment: .leading,spacing: 8, content: {
                if isPassword {
                    Group{
                        if shoePassword{
                            TextField(hint, text: $value)
                        }else{
                            SecureField(hint, text: $value)
                        }
                    }
                    
                }else{
                    TextField(hint, text: $value)
                }
                Divider()
            })
            .overlay(alignment: .trailing){
                if isPassword{
                    Button(action: {
                        withAnimation{
                            shoePassword.toggle()
                        }
                    }, label: {
                        Image(systemName: shoePassword ? "eye.slash" : "eye")
                            .foregroundStyle(.gray)
                            .padding(10)
                            .contentShape(.rect)
                    })
                }
            }
        })
    }
}


