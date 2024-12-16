struct OptimizedImageView: View {
    let imageName: String
    
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit) // Mantiene proporción
            .frame(maxWidth: .infinity)
    }
} 