import SwiftUI
import CoreLocation
import MapKit

// MARK: - Modern SwiftUI Keyboard Handling
// Replaces UIKit-based keyboard management with SwiftUI native approaches

struct SignupView: View {
    // MARK: - Form State Management
    @State private var formData = RegistrationFormData()
    @State private var formState = FormState()

    // MARK: - Focus Management
    @FocusState private var isBudgetFocused: Bool
    @FocusState private var isAddressFocused: Bool

    // MARK: - Dependencies
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var addressSearchHandler = AddressSearchHandler()
    @Environment(\.dismiss) private var dismiss

    // MARK: - Form Validation
    private var isFormValid: Bool {
        formData.isValid && !formState.isLoading
    }
    
    var body: some View {
        ScrollViewReader { scrollProxy in
            mainContent(scrollProxy: scrollProxy)
        }
        .alert(isPresented: $formState.showAlert) {
            alertContent
        }
        .navigationBarHidden(true)
        .onAppear(perform: setupView)
        .edgesIgnoringSafeArea(.bottom)
    }

    // MARK: - Main Content
    @ViewBuilder
    private func mainContent(scrollProxy: ScrollViewProxy) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                formContainer(scrollProxy: scrollProxy)
            }
        }
        .background(backgroundGradient)
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    // MARK: - Header View
    private var headerView: some View {
        HStack {
            Button(action: { dismiss() }) {
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
    }

    // MARK: - Form Container
    @ViewBuilder
    private func formContainer(scrollProxy: ScrollViewProxy) -> some View {
        VStack(spacing: 15) {
            basicInfoFields
            passwordAndProjectFields(scrollProxy: scrollProxy)
            submitButton
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(15)
        .shadow(radius: 5)
        .padding()
    }

    // MARK: - Basic Info Fields
    private var basicInfoFields: some View {
        Group {
            formTextField("Nombre de la Empresa", text: $formData.companyName, id: "company")
                .autocapitalization(.words)

            formTextField("Correo Electrónico", text: $formData.email, id: "email")
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textContentType(.emailAddress)

            formTextField("Teléfono", text: $formData.phone, id: "phone")
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)

            formTextField("Tarjeta de Identificación", text: $formData.card, id: "card")

            formTextField("Tipo de Trabajo", text: $formData.workType, id: "workType")
                .autocapitalization(.words)
        }
    }

    // MARK: - Password and Project Fields
    @ViewBuilder
    private func passwordAndProjectFields(scrollProxy: ScrollViewProxy) -> some View {
        Group {
            formSecureField("Contraseña", text: $formData.password, id: "password")
            formSecureField("Confirmar Contraseña", text: $formData.passwordConfirm, id: "passwordConfirm")
            formTextField("Nombre del Proyecto", text: $formData.projectName, id: "projectName")
                .autocapitalization(.words)
            budgetField(scrollProxy: scrollProxy)
            addressField(scrollProxy: scrollProxy)
        }
    }

    // MARK: - Budget Field
    @ViewBuilder
    private func budgetField(scrollProxy: ScrollViewProxy) -> some View {
        TextField("Presupuesto", text: $formData.budget)
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
                    withAnimation { scrollProxy.scrollTo("budget", anchor: .top) }
                }
            }
    }

    // MARK: - Address Field
    @ViewBuilder
    private func addressField(scrollProxy: ScrollViewProxy) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            addressInputRow(scrollProxy: scrollProxy)
            addressSearchResults
        }
    }

    @ViewBuilder
    private func addressInputRow(scrollProxy: ScrollViewProxy) -> some View {
        HStack {
            TextField("Dirección", text: $formData.address)
                .padding()
                .background(Color.white.opacity(0.9))
                .cornerRadius(10)
                .shadow(radius: 2)
                .submitLabel(.search)
                .textContentType(.fullStreetAddress)
                .autocapitalization(.words)
                .id("address")
                .focused($isAddressFocused)
                .onChange(of: formData.address) { newValue in
                    addressSearchHandler.search(query: newValue)
                    formState.showingAddressResults = !newValue.isEmpty
                }
                .onChange(of: isAddressFocused) { focused in
                    if focused {
                        withAnimation { scrollProxy.scrollTo("address", anchor: .top) }
                        formState.showingAddressResults = !formData.address.isEmpty
                    }
                }

            addressFieldTrailingView
        }
    }

    @ViewBuilder
    private var addressFieldTrailingView: some View {
        if addressSearchHandler.isSearching {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .padding(.trailing, 8)
        } else if !formData.address.isEmpty {
            Button(action: {
                formData.address = ""
                formState.showingAddressResults = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
            .padding(.trailing, 8)
        }
    }

    @ViewBuilder
    private var addressSearchResults: some View {
        if formState.showingAddressResults && !addressSearchHandler.searchResults.isEmpty {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(addressSearchHandler.searchResults, id: \.self) { result in
                        addressResultRow(result)
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

    private func addressResultRow(_ result: MKLocalSearchCompletion) -> some View {
        Button(action: { selectAddressResult(result) }) {
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
    }

    // MARK: - Submit Button
    private var submitButton: some View {
        Button(action: { validateAndSubmit() }) {
            submitButtonContent
        }
        .disabled(formState.isLoading)
        .padding(.top)
        .id("button")
    }

    @ViewBuilder
    private var submitButtonContent: some View {
        if formState.isLoading {
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

    // MARK: - Helper Views
    private func formTextField(_ placeholder: String, text: Binding<String>, id: String) -> some View {
        TextField(placeholder, text: text)
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(10)
            .shadow(radius: 2)
            .submitLabel(.next)
            .id(id)
    }

    private func formSecureField(_ placeholder: String, text: Binding<String>, id: String) -> some View {
        SecureField(placeholder, text: text)
            .padding()
            .background(Color.white.opacity(0.9))
            .cornerRadius(10)
            .shadow(radius: 2)
            .submitLabel(.next)
            .textContentType(.newPassword)
            .id(id)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color.myPrimary, Color.myPrimary.opacity(0.7)]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }

    private var alertContent: Alert {
        Alert(
            title: Text(formState.alertTitle),
            message: Text(formState.alertMessage),
            dismissButton: .default(Text("OK")) {
                if formState.isSuccess {
                    dismiss()
                    if UserManager.shared.getAuthToken != nil {
                        NotificationCenter.default.post(name: NSNotification.Name("LoginSuccessful"), object: nil)
                    }
                }
            }
        )
    }

    private func setupView() {
        locationManager.checkAuthorizationStatus()
        DispatchQueue.main.async {
            UITextField.appearance().adjustsFontSizeToFitWidth = true
            _ = UITextInputMode.activeInputModes
            let selector = NSSelectorFromString("_installRemoteTextInputResponderWithAssertionIdentifier:")
            if UIApplication.shared.responds(to: selector) {
                _ = UIApplication.shared.perform(selector, with: "com.apple.UIKit.textinput.identifier")
            }
            NotificationCenter.default.post(name: NSNotification.Name("UIKeyboardDidChangeFrameNotification"), object: nil)
        }
    }

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
                    self.formData.address = addressComponents.joined(separator: ", ")
                } else {
                    // Si no hay componentes de dirección, usar el título del resultado
                    self.formData.address = result.title
                }
                self.formState.showingAddressResults = false
                self.isAddressFocused = false
            }
        }
    }
    
    // Validación y envío del formulario
    private func validateAndSubmit() {
        // Resetear mensajes de error
        formState.alertTitle = ""
        formState.alertMessage = ""
        
        // Validaciones
        guard !formData.companyName.isEmpty else {
            formState.alertTitle = "Error"
            formState.alertMessage = "Por favor ingresa el nombre de la empresa"
            formState.showAlert = true
            return
        }
        
        guard !formData.email.isEmpty, isValidEmail(formData.email) else {
            formState.alertTitle = "Error"
            formState.alertMessage = "Por favor ingresa un correo electrónico válido"
            formState.showAlert = true
            return
        }
        
        guard !formData.phone.isEmpty, isValidPhone(formData.phone) else {
            formState.alertTitle = "Error"
            formState.alertMessage = "Por favor ingresa un número de teléfono válido"
            formState.showAlert = true
            return
        }
        
        guard !formData.card.isEmpty else {
            formState.alertTitle = "Error"
            formState.alertMessage = "Por favor ingresa el número de tarjeta de identificación"
            formState.showAlert = true
            return
        }
        
        guard !formData.password.isEmpty, formData.password.count >= 6 else {
            formState.alertTitle = "Error"
            formState.alertMessage = "La contraseña debe tener al menos 6 caracteres"
            formState.showAlert = true
            return
        }
        
        guard formData.password == formData.passwordConfirm else {
            formState.alertTitle = "Error"
            formState.alertMessage = "Las contraseñas no coinciden"
            formState.showAlert = true
            return
        }
        
        guard !formData.projectName.isEmpty else {
            formState.alertTitle = "Error"
            formState.alertMessage = "Por favor ingresa el nombre del proyecto"
            formState.showAlert = true
            return
        }
        
        guard !formData.budget.isEmpty, let _ = Double(formData.budget) else {
            formState.alertTitle = "Error"
            formState.alertMessage = "Por favor ingresa un presupuesto válido"
            formState.showAlert = true
            return
        }
        
        guard !formData.address.isEmpty else {
            formState.alertTitle = "Error"
            formState.alertMessage = "Por favor ingresa la dirección"
            formState.showAlert = true
            return
        }
        
        // Si llegamos aquí, todo está validado
        submitForm()
    }
    
    private func submitForm() {
        formState.isLoading = true
        
        // Usar la ubicación del dispositivo o valores por defecto, asegurando que no sean NaN o infinitos
        var latitude = locationManager.lastLocation?.coordinate.latitude ?? 0.0
        var longitude = locationManager.lastLocation?.coordinate.longitude ?? 0.0
        let budgetValue = Double(formData.budget) ?? 0.0
        
        // Validar que las coordenadas no sean NaN o infinitas
        if latitude.isNaN || latitude.isInfinite {
            latitude = 0.0
        }
        
        if longitude.isNaN || longitude.isInfinite {
            longitude = 0.0
        }
        
        APIService.shared.register(
            name: formData.companyName,
            email: formData.email,
            phone: formData.phone,
            card: formData.card,
            altitude: latitude,
            longitude: longitude,
            nameWorkType: formData.workType,
            password: formData.password,
            nameProject: formData.projectName,
            budget: budgetValue,
            address: formData.address
        ) { result in
            formState.isLoading = false
            
            switch result {
            case .success(let response):
                formState.alertTitle = response.success ? "Éxito" : "Error"
                formState.alertMessage = response.message
                formState.isSuccess = response.success
                
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
                
                formState.showAlert = true
                
            case .failure(let error):
                formState.alertTitle = "Error"
                if case NetworkError.apiError(let message) = error {
                    formState.alertMessage = message
                } else {
                    formState.alertMessage = error.localizedDescription
                }
                formState.showAlert = true
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

// MARK: - Supporting Data Structures for Performance Optimization

/// Optimized form data structure to reduce state variables and improve performance
struct RegistrationFormData {
    var companyName: String = ""
    var email: String = ""
    var phone: String = ""
    var card: String = ""
    var workType: String = "Cleaning"
    var password: String = ""
    var passwordConfirm: String = ""
    var projectName: String = ""
    var budget: String = ""
    var address: String = ""
    
    /// Computed property for form validation
    var isValid: Bool {
        !companyName.isEmpty &&
        isValidEmail(email) &&
        isValidPhone(phone) &&
        !card.isEmpty &&
        password.count >= 6 &&
        password == passwordConfirm &&
        !projectName.isEmpty &&
        Double(budget) != nil &&
        !address.isEmpty
    }
    
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

/// Optimized form UI state management
struct FormState {
    var isLoading = false
    var showAlert = false
    var alertTitle = ""
    var alertMessage = ""
    var isSuccess = false
    var showingAddressResults = false
}

/// Modern focus field enumeration for @FocusState
enum FormField: CaseIterable {
    case companyName
    case email
    case phone
    case card
    case workType
    case password
    case passwordConfirm
    case projectName
    case budget
    case address
    
    /// Navigate to next field in logical order
    var next: FormField? {
        let allCases = FormField.allCases
        guard let currentIndex = allCases.firstIndex(of: self),
              currentIndex + 1 < allCases.count else {
            return nil
        }
        return allCases[currentIndex + 1]
    }
}
