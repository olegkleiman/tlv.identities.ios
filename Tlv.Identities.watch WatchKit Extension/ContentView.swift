//
//  ContentView.swift
//  Tlv.Identities.watch WatchKit Extension
//
//  Created by Oleg Kleiman on 02/07/2022.
//

import SwiftUI
//import Alamofire

struct ContentView: View {
    
    @State private var userId: String = "313069486"
    @State var phoneNumber: String = "0543307026"
    
    var body: some View {
        VStack {
            HStack {
                Text("User Id")
                    .padding()
                    .font(.body)
                TextField("User Id", text: $userId, prompt: Text("Required"))
                    
            }.padding()
            HStack {
                Text("Phone Number")
                    .padding()
                    .font(.body)
                TextField("Phone Number", text: $phoneNumber, prompt: Text("Required"))
                    //.keyboardType(.numberPad)
            }.padding()
            Button {
                Task {
                    print("Login invoked")
                    Task {
                        
                        let url = URL(string:"https://tlvidentity.azurewebsites.net/api/generate_otp")!
                        
                        let parameters: [String: String] = [
                            "userId": userId,
                            "phoneNumber": phoneNumber
                        ]
                        
//                        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
//                            .responseDecodable(of: SendOTPResponse.self) { response in
//                                if !response.value!.isError as Bool {
//                                    self.stage = 1
//                                } else
//                                {
//                                    self.errorMessage = (response.value?.errorDesc as? String)!
//                                    self.showError = true
//                                }
//                        }

                    }
                }
            } label: {
                Text("Continue")
                        .padding(2)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
