import SwiftUI
import UIKit
import CoreLocation
import MapKit

// La clase AddressSearchHandler ya está definida en AddProjectView.swift

// Para solucionar problemas de constraints con el teclado
extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#if FRIENDLY_TARGET
struct KeyboardAdaptive: ViewModifier {
    @State private var keyboardHeight: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardHeight)
            .onAppear(perform: {
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                    let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect ?? .zero
                    withAnimation(.easeOut(duration: 0.16)) {
                        self.keyboardHeight = keyboardFrame.height
                    }
                }
                
                NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                    withAnimation(.easeOut(duration: 0.16)) {
                        self.keyboardHeight = 0
                    }
                }
                
                // Esto ayuda a prevenir los errores de "Can't find or decode reasons"
                _ = UITextInputMode.activeInputModes
            })
            .onDisappear(perform: {
                NotificationCenter.default.removeObserver(self)
            })
    }
}

extension View {
    func keyboardAdaptive() -> some View {
        modifier(KeyboardAdaptive())
    }
}

struct SignupView: View {
    // Variables para el formulario
    @State private var companyName: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var card: String = ""
    @State private var workType: String = "Cleaning"
    @State private var password: String = ""
    @State private var passwordConfirm: String = ""
    @State private var projectName: String = ""
    @State private var budget: String = ""
    @State private var address: String = ""
    
    // Variables para el estado de la vista
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false
    @State private var keyboardHeight: CGFloat = 0
    
    // Para la geolocalización
    @StateObject private var locationManager = LocationManager.shared
    
    // Para la búsqueda de direcciones
    @StateObject private var addressSearchHandler = AddressSearchHandler()
    @State private var showingAddressResults = false
    @FocusState private var isAddressSearchFocused: Bool
    
    // Para la navegación
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "arrow.left")
                                .foregroundColor(.white)
                                .font(.system(size: 22))
                                .padding()
                        }
                        
                        Spacer()
                        
                        Text("Registro de Nuevo Cliente")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    // Formulario
                    VStack(spacing: 15) {
                        Group {
                            TextField("Nombre de la Empresa", text: $companyName)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .submitLabel(.next)
                                .autocapitalization(.words)
                                .id("company")
                            
                            TextField("Correo Electrónico", text: $email)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .submitLabel(.next)
                                .textContentType(.emailAddress)
                                .id("email")
                            
                            TextField("Teléfono", text: $phone)
                                .keyboardType(.phonePad)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .submitLabel(.next)
                                .textContentType(.telephoneNumber)
                                .id("phone")
                            
                            TextField("Tarjeta de Identificación", text: $card)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .submitLabel(.next)
                                .id("card")
                            
                            TextField("Tipo de Trabajo", text: $workType)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .submitLabel(.next)
                                .autocapitalization(.words)
                                .id("workType")
                        }
                        
                        Group {
                            SecureField("Contraseña", text: $password)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .submitLabel(.next)
                                .textContentType(.newPassword)
                                .id("password")
                            
                            SecureField("Confirmar Contraseña", text: $passwordConfirm)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .submitLabel(.next)
                                .textContentType(.newPassword)
                                .id("passwordConfirm")
                            
                            TextField("Nombre del Proyecto", text: $projectName)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .submitLabel(.next)
                                .autocapitalization(.words)
                                .id("projectName")
                            
                            TextField("Presupuesto", text: $budget)
                                .keyboardType(.decimalPad)
                                .padding()
                                .background(Color.white.opacity(0.9))
                                .cornerRadius(10)
                                .shadow(radius: 2)
                                .submitLabel(.next)
                                .id("budget")
                                .focused($isBudgetFocused)
                                .onChange(of: isBudgetFocused) { focused in
                                    if focused {
                                        withAnimation {
                                            scrollProxy.scrollTo("budget", anchor: .top)
                                        }
                                    }
                                }
                            
                            // Campo de búsqueda de dirección mejorado
                            VStack(alignment: .leading, spacing: 5) {
                                HStack {
                                    TextField("Dirección", text: $address)
                                        .padding()
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(10)
                                        .shadow(radius: 2)
                                        .submitLabel(.search)
                                        .textContentType(.fullStreetAddress)
                                        .autocapitalization(.words)
                                        .id("address")
                                        .focused($isAddressSearchFocused)
                                        .onChange(of: address) { newValue in
                                            addressSearchHandler.search(query: newValue)
                                            showingAddressResults = !newValue.isEmpty
                                        }
                                        .onChange(of: isAddressSearchFocused) { focused in
                                            if focused {
                                                withAnimation {
                                                    scrollProxy.scrollTo("address", anchor: .top)
                                                }
                                                showingAddressResults = !address.isEmpty
                                            }
                                        }
                                    
                                    if addressSearchHandler.isSearching {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle())
                                            .padding(.trailing, 8)
                                    } else if !address.isEmpty {
                                        Button(action: {
                                            address = ""
                                            showingAddressResults = false
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.trailing, 8)
                                    }
                                }
                                
                                // Resultados de la búsqueda de direcciones
                                if showingAddressResults && !addressSearchHandler.searchResults.isEmpty {
                                    ScrollView(.vertical, showsIndicators: true) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            ForEach(addressSearchHandler.searchResults, id: \.self) { result in
                                                Button(action: {
                                                    selectAddressResult(result)
                                                }) {
                                                    VStack(alignment: .leading, spacing: 3) {
                                                        Text(result.title)
                                                            .font(.subheadline)
                                                            .foregroundColor(.primary)
                                                        if !result.subtitle.isEmpty {
                                                            Text(result.subtitle)
                                                                .font(.caption)
                                                                .foregroundColor(.secondary)
                                                        }
                                                    }
                                                    .padding(.vertical, 5)
                                                }
                                                .buttonStyle(PlainButtonStyle())
                                                Divider()
                                            }
                                        }
                                        .padding(8)
                                    }
                                    .frame(height: min(CGFloat(addressSearchHandler.searchResults.count * 50), 200))
                                    .background(Color.white.opacity(0.95))
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                                    .padding(.top, 5)
                                }
                            }
                        }
                        
                        Button(action: {
                            validateAndSubmit()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.myPrimary)
                                    .cornerRadius(10)
                                    .shadow(radius: 3)
                            } else {
                                Text("Registrarse")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.myPrimary)
                                    .cornerRadius(10)
                                    .shadow(radius: 3)
                            }
                        }
                        .disabled(isLoading)
                        .padding(.top)
                        .id("button")
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(15)
                    .shadow(radius: 5)
                    .padding()
                }
            }
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.myPrimary, Color.myPrimary.opacity(0.7)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
            )
            .keyboardAdaptive()
            .gesture(
                TapGesture().onEnded { _ in
                    UIApplication.shared.endEditing()
                }
            )
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        // En caso de éxito, cerramos la vista y el usuario estará automáticamente autenticado
                        dismiss()
                        
                        // Notificar a la vista de login que se ha iniciado sesión
                        if let userData = UserManager.shared.getAuthToken {
                            // Cerrar la vista actual y navegar a la pantalla principal
                            NotificationCenter.default.post(name: NSNotification.Name("LoginSuccessful"), object: nil)
                        }
                    }
                }
            )
        }
        .navigationBarHidden(true)
        .onAppear {
            // Solicitar permisos de ubicación al cargar la vista
            locationManager.checkAuthorizationStatus()
            
            // Ayuda a prevenir errores de teclado
            DispatchQueue.main.async {
                UITextField.appearance().adjustsFontSizeToFitWidth = true
                
                // Inicializar todos los sistemas de entrada para prevenir warnings
                _ = UITextInputMode.activeInputModes
                
                // Prevenir warnings específicos de "Can't find or decode reasons"
                let selector = NSSelectorFromString("_installRemoteTextInputResponderWithAssertionIdentifier:")
                if UIApplication.shared.responds(to: selector) {
                    // Necesario para prevenir warnings de decodificación
                    let _ = UIApplication.shared.perform(selector, with: "com.apple.UIKit.textinput.identifier")
                }
                
                // Prevenir warnings de teclado en emojis y autocompletado
                NotificationCenter.default.post(name: NSNotification.Name("UIKeyboardDidChangeFrameNotification"), object: nil)
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    // Estados para saber qué campo está enfocado
    @FocusState private var isBudgetFocused: Bool
    @FocusState private var isAddressFocused: Bool
    
    // Función para manejar la selección de una dirección
    private func selectAddressResult(_ result: MKLocalSearchCompletion) {
        let searchRequest = MKLocalSearch.Request(completion: result)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { response, error in
            guard let response = response, let item = response.mapItems.first else {
                // Liberar recursos incluso en caso de error
                search.cancel()
                return
            }
            
            // Usar la dirección formateada del placemark si está disponible
            let placemark = item.placemark
            let addressComponents = [
                placemark.thoroughfare,
                placemark.subThoroughfare,
                placemark.locality,
                placemark.administrativeArea,
                placemark.country
            ].compactMap { $0 }
            
            // Actualizar la dirección en el hilo principal
            DispatchQueue.main.async {
                if !addressComponents.isEmpty {
                    self.address = addressComponents.joined(separator: ", ")
                } else {
                    // Si no hay componentes de dirección, usar el título del resultado
                    self.address = result.title
                }
                self.showingAddressResults = false
                self.isAddressSearchFocused = false
            }
        }
    }
    
    // Validación y envío del formulario
    private func validateAndSubmit() {
        // Resetear mensajes de error
        alertTitle = ""
        alertMessage = ""
        
        // Validaciones
        guard !companyName.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Por favor ingresa el nombre de la empresa"
            showAlert = true
            return
        }
        
        guard !email.isEmpty, isValidEmail(email) else {
            alertTitle = "Error"
            alertMessage = "Por favor ingresa un correo electrónico válido"
            showAlert = true
            return
        }
        
        guard !phone.isEmpty, isValidPhone(phone) else {
            alertTitle = "Error"
            alertMessage = "Por favor ingresa un número de teléfono válido"
            showAlert = true
            return
        }
        
        guard !card.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Por favor ingresa el número de tarjeta de identificación"
            showAlert = true
            return
        }
        
        guard !password.isEmpty, password.count >= 6 else {
            alertTitle = "Error"
            alertMessage = "La contraseña debe tener al menos 6 caracteres"
            showAlert = true
            return
        }
        
        guard password == passwordConfirm else {
            alertTitle = "Error"
            alertMessage = "Las contraseñas no coinciden"
            showAlert = true
            return
        }
        
        guard !projectName.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Por favor ingresa el nombre del proyecto"
            showAlert = true
            return
        }
        
        guard !budget.isEmpty, let _ = Double(budget) else {
            alertTitle = "Error"
            alertMessage = "Por favor ingresa un presupuesto válido"
            showAlert = true
            return
        }
        
        guard !address.isEmpty else {
            alertTitle = "Error"
            alertMessage = "Por favor ingresa la dirección"
            showAlert = true
            return
        }
        
        // Si llegamos aquí, todo está validado
        submitForm()
    }
    
    private func submitForm() {
        isLoading = true
        
        // Usar la ubicación del dispositivo o valores por defecto, asegurando que no sean NaN o infinitos
        var latitude = locationManager.lastLocation?.coordinate.latitude ?? 0.0
        var longitude = locationManager.lastLocation?.coordinate.longitude ?? 0.0
        let budgetValue = Double(budget) ?? 0.0
        
        // Validar que las coordenadas no sean NaN o infinitas
        if latitude.isNaN || latitude.isInfinite {
            latitude = 0.0
        }
        
        if longitude.isNaN || longitude.isInfinite {
            longitude = 0.0
        }
        
        APIService.shared.register(
            name: companyName,
            email: email,
            phone: phone,
            card: card,
            altitude: latitude,
            longitude: longitude,
            nameWorkType: workType,
            password: password,
            nameProject: projectName,
            budget: budgetValue,
            address: address
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let response):
                alertTitle = response.success ? "Éxito" : "Error"
                alertMessage = response.message
                isSuccess = response.success
                
                // Si el registro fue exitoso, guardar sesión automáticamente
                if response.success {
                    print("Registro exitoso, procesando inicio de sesión automático")
                    
                    // Verificar si los datos del usuario están en la respuesta directa
                    if let user = response.user, let token = response.token {
                        print("Datos de usuario encontrados en la raíz de la respuesta")
                        
                        // Crear una respuesta de login con los datos de la raíz
                        let loginResponse = LoginResponse(
                            status: true,
                            message: response.message,
                            user: user,
                            name: response.name,
                            sysconf: response.sysconf,
                            email: response.email,
                            token: token
                        )
                        
                        // Guardar datos del usuario e iniciar sesión automáticamente
                        UserManager.shared.saveUser(from: loginResponse)
                        
                        // Notificar que el inicio de sesión fue exitoso
                        NotificationCenter.default.post(name: NSNotification.Name("LoginSuccessful"), object: nil)
                    }
                    // Mantener el caso anterior por compatibilidad
                    else if let userData = response.data, let user = userData.user, let token = userData.token {
                        print("Datos de usuario encontrados en el objeto data")
                        
                        let loginResponse = LoginResponse(
                            status: true,
                            message: response.message,
                            user: user,
                            name: userData.name,
                            sysconf: userData.sysconf,
                            email: userData.email,
                            token: token
                        )
                        
                        // Guardar datos del usuario
                        UserManager.shared.saveUser(from: loginResponse)
                        
                        // Notificar que el inicio de sesión fue exitoso
                        NotificationCenter.default.post(name: NSNotification.Name("LoginSuccessful"), object: nil)
                    } else {
                        print("No se pudieron encontrar los datos del usuario en la respuesta")
                    }
                }
                
                showAlert = true
                
            case .failure(let error):
                alertTitle = "Error"
                if case NetworkError.apiError(let message) = error {
                    alertMessage = message
                } else {
                    alertMessage = error.localizedDescription
                }
                showAlert = true
            }
        }
    }
    
    // Validadores
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidPhone(_ phone: String) -> Bool {
        let phoneRegex = "^[0-9+]{10,15}$"
        let phonePred = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePred.evaluate(with: phone)
    }
}
#endif 