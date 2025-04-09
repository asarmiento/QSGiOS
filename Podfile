# Especificar la plataforma iOS y la versión mínima requerida
platform :ios, '17.6'

# Habilitar frameworks dinámicos si es necesario
use_frameworks!

# Definir una instalación global de CocoaPods
install! 'cocoapods', :disable_input_output_paths => true
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Fuerza la generación de dSYM en Release
      if config.name == 'Release'
        config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf-with-dsym'
      end
    end
  end
end


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
