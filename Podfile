# Especificar la plataforma iOS y la versión mínima requerida
platform :ios, '17.6'

# Habilitar frameworks dinámicos si es necesario
use_frameworks!

# Definir una instalación global de CocoaPods
install! 'cocoapods', :disable_input_output_paths => true

# Lista de dependencias compartidas
def common_pods
  pod 'Firebase/Messaging'
  pod 'Firebase/Analytics'
  pod 'Firebase/Database'
end

target 'QGS' do
  common_pods

  target 'QGSTests' do
    inherit! :search_paths
  end

  target 'QGSUITests' do
  end
end

target 'FriendlyCheckInOut' do
  common_pods
end
