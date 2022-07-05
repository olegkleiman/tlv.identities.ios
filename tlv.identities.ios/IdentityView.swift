//
//  IdentityView.swift
//  tlv.identities.ios
//
//  Created by Oleg Kleiman on 05/07/2022.
//

import SwiftUI
import Foundation
import Alamofire

struct IdentityView: View {
    
    @State private var userId: String = "313069486"
    
    @Binding var stage: Int
    @Binding var phoneNumber: String
    
    @State private var showError = false
    @State private var errorMessage: String = ""
    
    @State private var isLoading = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 22) {

            VStack {
                HStack {
                    Text("User Id")
                        .padding()
                        .font(.body)
                    TextField("User Id", text: $userId, prompt: Text("Required"))
                        .keyboardType(.numberPad)
                }.padding()
                HStack {
                    Text("Phone Number")
                        .padding()
                        .font(.body)
                    TextField("Phone Number", text: $phoneNumber, prompt: Text("Required"))
                        .keyboardType(.numberPad)
                }.padding()
                Button {
                    print("Login invoked")
                    Task {
                        
                        let url = URL(string:"https://tlvidentity.azurewebsites.net/api/generate_otp")!
                        
                        let parameters: [String: String] = [
                            "userId": userId,
                            "phoneNumber": phoneNumber
                        ]
                        
                        self.isLoading = true
                        AF.request(url, method: .post, parameters: parameters, encoder: JSONParameterEncoder.default)
                            .responseDecodable(of: SendOTPResponse.self) { response in
                                if !response.value!.isError as Bool {
                                    self.stage = 1
                                } else
                                {
                                    self.errorMessage = (response.value?.errorDesc as? String)!
                                    self.showError = true
                                }
                        }

                    }

                } label: {
                    Text("Continue")
                            .padding(2)
                }
                .disabled(self.isLoading)
                
                if showError {
                    VStack {
                        TextField("", text: $errorMessage)
                            .padding()
                            .foregroundColor(.red)
                    }
                }
            }
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
            
            Spacer()
            
        }
        

    }
}
