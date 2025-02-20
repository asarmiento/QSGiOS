//
//  LocationError.swift
//  QGS
//
//  Created by Anwar Sarmiento on 2/20/25.
//
import Foundation


enum LocationError: LocalizedError {
    case permisoDenegado
    case servicioDesactivado
    case ubicacionInvalida
    case ubicacionDesconocida
    case errorRed
    case errorDesconocido(Error?)
    
    var errorDescription: String? {
        switch self {
        case .permisoDenegado:
            return "No tienes permisos para acceder a la ubicación. Por favor, verifica la configuración de tu dispositivo."
        case .servicioDesactivado:
            return "Los servicios de localización están desactivados. Por favor, actívalos en la configuración de tu dispositivo."
        case .ubicacionInvalida:
            return "No se pudo obtener una ubicación válida. Por favor, inténtalo de nuevo."
        case .ubicacionDesconocida:
            return "No se puede determinar tu ubicación actual. Verifica tu conexión y que estés en un área con buena cobertura."
        case .errorRed:
            return "Error de red al obtener la ubicación. Verifica tu conexión a internet."
        case .errorDesconocido(let error):
            return "Error inesperado: \(error?.localizedDescription ?? "desconocido")"
        }
    }
}
