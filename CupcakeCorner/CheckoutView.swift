//
//  CheckoutView.swift
//  CupcakeCorner
//
//  Created by Yes on 12.11.2019.
//  Copyright © 2019 Yes. All rights reserved.
//

import SwiftUI

struct CheckoutView: View {
    @ObservedObject var order: Order
    
    @State private var confirmationMessage = ""
    @State private var showingConfirmation = false
    
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack {
                    Image("cupcakes")
                        .resizable()
                        .scaledToFit()
                        .frame(width: geo.size.width)

                    Text("Your total is $\(self.order.data.cost, specifier: "%.2f")")
                        .font(.title)

                    Button("Place Order") {
                        self.placeOrder()
                    }
                    .alert(isPresented: self.$showingError) {
                        Alert(title: Text(self.errorMessage), dismissButton: .default(Text("OK")))
                    }
                    .padding()
                }
            }
        }
        .alert(isPresented: $showingConfirmation) {
            Alert(title: Text("Thank you!"), message: Text(confirmationMessage), dismissButton: .default(Text("OK")))
        }
        .navigationBarTitle("Check out", displayMode: .inline)
    }
    
    func placeOrder() {
        guard let encoded = try? JSONEncoder().encode(order.data) else {
            print("Failed to encode order")
            return
        }
        
        let url = URL(string: "https://reqres.in/api/cupcakes")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = encoded
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil || data == nil {
                let code = (error! as NSError).code
                self.showingError = true
                self.errorMessage = self.errorMessage(code)
                return
            }

            guard let data = data else {
                print("No data in response: \(error?.localizedDescription ?? "Unknown error").")
                return
            }
            
            if let decodedOrder = try? JSONDecoder().decode(OrderItem.self, from: data) {
                print(decodedOrder)
                self.confirmationMessage = "Your order for \(decodedOrder.quantity)x \(OrderItem.types[decodedOrder.type].lowercased()) cupcakes is on its way!"
                self.showingConfirmation = true
            } else {
                print("Invalid response from server")
            }
            
        }.resume()
    }
    
    func errorMessage(_ code: Int) -> String {
        switch code {
        case -1009: return "No internet connection"
        default: return "Client error"
        }
    }
}

struct CheckoutView_Previews: PreviewProvider {
    static var previews: some View {
        CheckoutView(order: Order())
    }
}
