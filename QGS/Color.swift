import SwiftUI

// NO usar extensions duplicadas o múltiples declaraciones
// Usar un único namespace con propiedades computadas
public extension Color {
    static var myPrimary: Color {
        #if QGS_TARGET
        return Color("myPrimaries")
        #elseif FRIENDLY_TARGET
        return Color("myPrimaries")
        #elseif MCS_TARGET
        return Color(UIColor(red: 240/255, green: 90/255, blue: 41/255, alpha: 1))
        #else
        return Color("myPrimaries")
        #endif
    }
    
    static var Secodary: Color {
        return Color("secondaryColor")
    }
}
