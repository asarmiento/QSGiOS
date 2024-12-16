@ViewBuilder
func adaptiveLayout(_ geometry: GeometryProxy) -> some View {
    if geometry.size.width > 700 {
        HStack { /* Layout para iPad */ }
    } else {
        VStack { /* Layout para iPhone */ }
    }
} 