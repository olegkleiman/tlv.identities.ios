//
//  OTPView.swift
//  tlv.identities.ios
//
//  Created by Oleg Kleiman on 05/07/2022.
//
import SwiftUI
import Foundation
import Alamofire

struct OTPView: View {
    
    @Binding var stage: Int
    @Binding var phoneNumber: String
    @Binding var jsonTokens: DecodableTokens?

    @State private var otp: String = ""
    @State private var errorMessage: String = ""
    @State private var showError = false
    
    @State private var clientId: String = "8739c7f1-e812-4461-b9c8-d670307dd22b"

    @State private var isLoading = false
    
    var body: some View {
        
        VStack(alignment: .center, spacing: 22) {
            HStack {
                Text("OTP")
                    .padding()
                    .font(.body)
                TextField("Code you've received", text: $otp)
                    .keyboardType(.numberPad)

            }
            Button("Login") {
                Task {

                    let url = URL(string: "https://tlvidentity.azurewebsites.net/api/OTPValidator")!
                    
                    let parameters: [String: String] = [
                        "phone_number": phoneNumber,
                        "otp": otp,
                        "client_id": clientId,
                        "scope": "openid offline_access https://TlvfpB2CPPR.onmicrosoft.com/\(clientId)/TLV.Digitel"
                    ]

                    self.isLoading = true
                    AF.request(url, method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder(destination: .queryString))
                        .responseDecodable(of: DecodableTokens.self) { response in
                            if response.response?.statusCode == 200 {
                                self.jsonTokens = response.value!
                                self.stage = 2
                            } else {
                                let error = response.result
                                print(error)
                            }
                            
                            self.isLoading = false
                    }

                }
            }
            .disabled(self.isLoading)
            .padding(2)
            
            if showError {
                VStack {
                    TextField("", text: $errorMessage)
                        .padding()
                        .foregroundColor(.red)
                    Button {
                        self.stage = 0
                    } label: {
                        Text("Try again")
                            .padding(2)
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

