# Especificar la plataforma iOS y la versión mínima requerida
platform :ios, '17.6'

# Si estás utilizando frameworks dinámicos, habilítalo
use_frameworks!

# Definir los targets de tu proyecto
target 'QGS' do
  # Aquí puedes agregar los pods necesarios para tu aplicación
  pod 'Firebase/Messaging'
  # Otros pods pueden ir aquí si los necesitas, por ejemplo:
  # pod 'Firebase/Core'
   pod 'Firebase/Analytics'

  # Definir los targets de pruebas
  target 'QGSTests' do
    inherit! :search_paths
    # Agrega pods necesarios para las pruebas si los tienes
  end

  target 'QGSUITests' do
    # Agrega pods necesarios para las pruebas UI si los tienes
  end
end

