//
//  SideMenuRowView.swift
//  NorteGo
//
//  Created by Jonathan  Moran on 22/8/24.
//

import SwiftUI

struct SideMenuRowView: View {
    var title: String
    var imagen: String
    var isSelected: Bool // Añadido para indicar si está seleccionado
    
    var body: some View {
        HStack(spacing: 15) { // Ajuste del spacing
            Image(systemName: imagen)
                .resizable()
                .renderingMode(.template)
                .frame(width: 24, height: 24)
                //.foregroundColor(isSelected ? .blue : .gray) // Color azul si está seleccionado
                .foregroundColor(.gray)
            
            Text(title)
               // .foregroundColor(isSelected ? .blue : .black) // Color azul si está seleccionad
                .foregroundColor(.black)
                .font(.custom("Montserrat-Medium", size: 15))
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 12) // Separación vertical
        .padding(.horizontal, 12) // Separación horizontal
        //.background(isSelected ? Color.blue.opacity(0.1) : Color.clear) // Fondo si está seleccionado
        .background(Color.clear)
        .cornerRadius(8) // Bordes redondeados
    }
}

#Preview {
    SideMenuRowView(title: "ejemplo", imagen: "info.circle", isSelected: true)
}
