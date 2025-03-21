//
//  MapaRecolectorView.swift
//  NorteGoApp
//
//  Created by North on 20/3/25.
//

import SwiftUI
import FirebaseFirestore
import MapKit

struct DriverLocation: Identifiable {
    var id: String
    var name: String?
    var description: String?
    var type: Int?
    var latitude: Double
    var longitude: Double
}

struct MapaRecolectorView: View {
    @Environment(\.presentationMode) var presentationMode
    var tituloVista: String
    @StateObject var locationManager = LocationManager()
    
    @StateObject var viewModel = DriversViewModel()
    @State private var region = MKCoordinateRegion(
       center: CLLocationCoordinate2D(latitude: 14.331567037970174, longitude: -89.44806272228249),
       span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    @State private var showDriversModal = false
    @State private var selectedDriver: DriverLocation?  // Nuevo estado para el recolector seleccionado
    @State private var showPopup = false
    
    
   
    var body: some View {
        ZStack {
            // Mapa
            Map(coordinateRegion: $region, showsUserLocation: true, annotationItems: viewModel.drivers) { driver in
                MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: driver.latitude, longitude: driver.longitude)) {
                    ZStack {
                        // Icono del camión
                        Image("camion60")
                            .resizable()
                            .frame(width: 50, height: 40)
                            .onTapGesture {
                                selectedDriver = driver
                                withAnimation {
                                    showPopup = true
                                }
                            }

                        // Popup con detalles del recolector (solo para el driver seleccionado)
                        if showPopup, let selectedDriver = selectedDriver, selectedDriver.id == driver.id {
                            VStack {
                                Text(selectedDriver.name ?? "Sin nombre")
                                    .font(.headline)
                                    .padding(5)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                Text(selectedDriver.description ?? "Sin descripción")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(5)
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .background(Color.white)
                            .cornerRadius(8)
                            .shadow(radius: 4)
                            .frame(width: 150)
                            .offset(y: -50)
                            .onTapGesture {
                                withAnimation {
                                    showPopup = false
                                }
                            }
                            .zIndex(2)
                        }
                    }
                }
            }
            .onAppear {
                viewModel.listenForNearbyDrivers()
                locationManager.getLocation()
                if let userLocation = locationManager.location {
                    region.center = userLocation
                }
            }
            .onDisappear {
                viewModel.stopListening()
            }
            .onChange(of: locationManager.location) { newLocation in
                if let userLocation = newLocation {
                    region = MKCoordinateRegion(
                        center: userLocation,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                }
            }
            
            // Área transparente para detectar el toque fuera del popup
            if showPopup {
                Color.clear
                    .contentShape(Rectangle()) // Permite detectar toques en toda el área
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation {
                            showPopup = false
                        }
                    }
                    .zIndex(1)
            }
            
            // Botón en la esquina superior derecha (Lista de recolectores)
            showDriverListButton()
            
            // Botón en la esquina inferior derecha (Localización)
            locationButton()
            
            // Mostrar modal si showDriversModal es true
            if showDriversModal {
                createDriverModal()  // Este modal se muestra encima de los botones
            }
        }
        .navigationTitle("Recolectores")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
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
    }







    
    
    
    private func createDriverModal() -> some View {
        VStack {
            Spacer()  // Esto empuja la vista hacia arriba
            
            VStack {
                HStack {
                    Text("Recolectores Disponibles")
                        .font(.title)
                        .padding()
                    Spacer()
                    closeModalButton()
                }
                .background(Color.blue.opacity(0.1))
                
                List(viewModel.drivers) { driver in
                    driverListItem(driver)
                }
                
                // Botón de cerrar en la parte inferior
                closeButton()
            }
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 8)
            .padding()
        }
        .background(Color.black.opacity(0.3).edgesIgnoringSafeArea(.all)) // Fondo semi-transparente
    }

    private func closeButton() -> some View {
        Button(action: {
            showDriversModal.toggle()  // Cerrar el modal
        }) {
            Text("Cerrar")
                .foregroundColor(.white)
                .font(.title2)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
                .padding(.horizontal, 16)
        }
        .padding(.bottom, 16)  // Asegura que el botón esté bien alejado del borde
    }
    
    
    private func closeModalButton() -> some View {
           Button(action: {
               showDriversModal.toggle()  // Cerrar el modal
           }) {
               Image(systemName: "xmark.circle.fill")
                   .foregroundColor(.black)
                   .padding()
           }
       }

    private func driverListItem(_ driver: DriverLocation) -> some View {
            HStack {
                Image("camion60")
                    .resizable()
                    .frame(width: 40, height: 40)
                Text(driver.name ?? "Sin nombre")
                    .padding()
                Spacer()
            }
            .onTapGesture {
                let driverLocation = CLLocationCoordinate2D(latitude: driver.latitude, longitude: driver.longitude)
                withAnimation {
                    region.center = driverLocation
                }
                showDriversModal = false  // Cerrar el modal
            }
        }
    
    

    private func showDriverListButton() -> some View {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        showDriversModal.toggle()  // Mostrar el modal con la lista de recolectores
                    }) {
                        Image(systemName: "list.bullet") // Icono de lista
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.top, 16) // Margen desde la parte superior
                    .padding(.trailing, 16) // Margen desde la derecha
                }
                Spacer()
            }
        }
    
    
    private func locationButton() -> some View {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        if let location = locationManager.location {
                            withAnimation {
                                region.center = location
                            }
                        }
                    }) {
                        Image(systemName: "location.fill")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(radius: 4)
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 80) // Ajusta la distancia desde abajo
                }
            }
        }
    
    
}




















class DriversViewModel: ObservableObject {
    @Published var drivers: [DriverLocation] = []
    private var listener: ListenerRegistration?
    private let db = Firestore.firestore()

    func listenForNearbyDrivers() {
        listener = db.collection("Locations").addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            guard let documents = snapshot?.documents else { return }

            var updatedDrivers: [DriverLocation] = []
            let group = DispatchGroup()

            for document in documents {
                let driverID = document.documentID
                if let geoPoint = document.get("l") as? GeoPoint {
                    group.enter()
                    // Obtener info adicional del driver
                    self.db.collection("Drivers").document(driverID).getDocument { driverDoc, _ in
                        if let driverData = driverDoc?.data() {
                            let driver = DriverLocation(
                                id: driverID,
                                name: driverData["nombre"] as? String,
                                description: driverData["descripcion"] as? String,
                                type: Int(driverData["tipo"] as? String ?? "0"),
                                latitude: geoPoint.latitude,
                                longitude: geoPoint.longitude
                            )
                            updatedDrivers.append(driver)
                        }
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                self.drivers = updatedDrivers
            }
        }
    }

    func stopListening() {
        listener?.remove()
    }
}
