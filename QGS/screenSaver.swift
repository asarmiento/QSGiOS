
import Foundation
import SwiftUI

struct screenSaver: View {
    
    let login = Login()
    
    var body: some View{
        NavigationView{
            self.login
        }
        
    }
}

#Preview {
    screenSaver()
}
