//
//  AgendaView.swift
//  NorteGo
//
//  Created by North on 18/3/25.
//  Copyright © 2025 Alcaldia de Santa Ana Norte. All rights reserved.
//


import SwiftUI
import SwiftyJSON
import Alamofire
import RxSwift
import AlertToast
import SDWebImageSwiftUI

struct AgendaView: View {
    @Environment(\.presentationMode) var presentationMode
    
    @State private var openLoadingSpinner:Bool = true
    @State private var showToastBool:Bool = false
    @State var itemsListado: [ModeloListadoAgenda] = []
    @State private var pantallaCargada: Bool = false
   
    @StateObject private var toastViewModel = ToastViewModel()
    @StateObject var viewModel = ListadoAgendaViewModel()
    
    let disposeBag = DisposeBag()
   
    var body: some View {
        VStack {
            ZStack(alignment: Alignment(horizontal: .leading, vertical: .center)) {
                
                    VStack(spacing: 0) {
                        
                        if pantallaCargada {
                            
                            
                            
                            ScrollView {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 2), spacing: 10) {
                                    ForEach(itemsListado.indices, id: \..self) { index in
                                        CardViewAgenda(contacto: itemsListado[index])
                                    }
                                }
                                .padding()
                            }
                           
                            
                            
                            
                            /*List {
                                ForEach(itemsListado.indices, id: \.self) { index in
                                   
                                    
                                   
                                    
                                    
                                    
                                    
                                    
                                }
                                .listRowSeparator(.hidden)
                            }
                            .listStyle(PlainListStyle())
                            .refreshable {
                                // RECARGAR AL HACER SCROLL
                                serverListado()
                            }*/
                        }
                    }
                    .onAppear{
                        serverListado()
                    }
                if openLoadingSpinner {
                    LoadingSpinnerView()
                        .transition(.opacity) // Transición de opacidad
                        .zIndex(10)
                }
      
               
            }
        }
        .navigationTitle("Agenda")
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                            .foregroundColor(.black)
                        
                        Text("Atras")
                            .foregroundColor(.black)
                    }
                }
            }
        }
        .onReceive(viewModel.$loadingSpinner) { loading in
            openLoadingSpinner = loading
        }
        .toast(isPresenting: $toastViewModel.showToastBool, alert: {
            toastViewModel.customToast
        })
    }
      
    
   
    
    func serverListado(){
        itemsListado.removeAll()
        openLoadingSpinner = true
        pantallaCargada = false
        
        viewModel.misAgendaRX() { result in
            switch result {
            case .success(let json):
                let success = json["success"].int ?? 0
                switch success {
                case 1:
                                  
                     json["listado"].array?.forEach({ (dataArray) in
                         
                         let _id = dataArray["id"].int ?? 0
                         let _nombre = dataArray["nombre"].string ?? ""
                         let _telefono = dataArray["telefono"].string ?? ""
                         let _imagen = dataArray["imagen"].string ?? ""
                         
                         let _array = ModeloListadoAgenda(id: _id, nombre: _nombre, telefono: _telefono, imagen: _imagen)
                         
                         itemsListado.append(_array)
                     })
                       
                        pantallaCargada = true
                                        
                default:
                    mensajeError()
                }
                
            case .failure(_):
                mensajeError()
            }
        }
    }
    
    
    
    func mensajeError(){
        toastViewModel.showCustomToast(with: "Error, intentar de nuevo", tipoColor: .gris)
    }
}



struct CardViewAgenda: View {
    let contacto: ModeloListadoAgenda
    
    var body: some View {
        VStack(spacing: 0) { // Reduce el espacio entre los elementos
            WebImage(url: URL(string: baseUrlImagen + contacto.imagen))
                .resizable()
                .indicator(.activity)
                .scaledToFit()
                .frame(height: 175)
                .padding(.horizontal, 20) // Solo padding horizontal para que la imagen quede centrada
                .background(Color.clear) // Evita que se vea gris cuando la imagen carga
                .cornerRadius(5)
            
            Text(contacto.nombre)
                .font(.system(size: 18))
                .fontWeight(.bold) // Hace el texto más negrita
                .foregroundColor(.black)
                .padding(.top, 0)// Reduce aún más el espacio para que quede casi pegado a la imagen
            
            Text(contacto.telefono)
                .font(.system(size: 20))
                .fontWeight(.bold)
                .foregroundColor(.black)
                .padding(.bottom, 10)
        }
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 5)
        .padding(5)
    }
}
