//
//  ContentView.swift
//  tlv.identities.ios
//
//  Created by Oleg Kleiman on 02/07/2022.
//

import SwiftUI
import Foundation
import Alamofire
//import SwiftyJSON
import JWTDecode
//import JOSESwift
import OktaJWT

struct BlueButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(12)
                .background(Color(red: 0, green: 0, blue: 0.5))
                .foregroundColor(.white)
                .clipShape(Capsule())
                .scaleEffect(configuration.isPressed ? 1.2 : 1)
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
}

struct SendOTPResponse: Codable {
    let isError: Bool
    let errorDesc: String
    let errorId: Int
}

struct SendOTPRequest {
    let userId: String
    let phoneNumber: String
}

struct OTPValidationResponse: Codable {
    let version: String// "1.0.1"
    let status: Int // 409
    let code: String // "OTP3001"
    let userMessage: String
    let developerMessage: String
    let requestId: String
    let moreInfo: String
}

struct DecodableMetadata: Decodable {
    let issuer: String
    let authorization_endpoint: String
    let token_endpoint: String
    let jwks_uri: String
    let response_modes_supported: [String]
    let response_types_supported: [String]
    let scopes_supported: [String]
    let subject_types_supported: [String]
    let id_token_signing_alg_values_supported: [String]
    let token_endpoint_auth_methods_supported: [String]
    let claims_supported: [String]
    let grant_types_supported: [String]
}

struct KeyMetadata: Decodable {
    let kid: String
    let use: String
    let kty: String
    let e: String
    let n: String
}

struct DecodableTokens: Decodable {
    let access_token: String
    let token_type: String
    let expires_in: String
    let refresh_token: String
    let id_token: String
}

struct DecodableKeysResponse: Decodable {
    let keys: [KeyMetadata]
}

let ISSUER: String =
"https://TlvfpB2CPPR.b2clogin.com/TlvfpB2CPPR.onmicrosoft.com/B2C_1A_B2C_1_ROPC_KIEV_RP/v2.0/"
////"https://tlvfpb2cppr.b2clogin.com/TlvfpB2CPPR.onmicrosoft.com/v2.0/"
//"https://tlvfpb2cppr.b2clogin.com/781ec24d-9aa5-4628-9fc1-5a1f13dc0424/v2.0/"

struct TokenView: View {
    
    @Binding var stage: Int
    @Binding var jsonTokens: DecodableTokens?
    
    @State private var issuer: String = ""
    @State private var subject: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var scope: String = ""
    @State private var expiresAt: Date? = nil
    
    @State private var showVlidationResults = false
    @State private var validationMessage = ""
    
    func stringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy HH:mm" //yyyy
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack {
            Text("Parsed Access Token:")
                .font(.title)
            
            TextField("Name", text: $name)
                .padding(2)
            TextField("EMail", text: $email)
                .padding(2)
            TextField("Scope", text: $scope)
                .padding(2)
//            TextField("Expires at", text: stringFromDate($expiresAt))
//                .padding(2)
            TextField("Issuer", text: $issuer)
                .padding(2)
                .font(.body)
                .onAppear {
                    if let accessToken = jsonTokens?.access_token {
                        let jwt = try? decode(jwt: accessToken)
                        self.issuer = jwt?.issuer ?? "unknown"
                        self.subject = jwt?.subject ?? "unknown"
                        self.expiresAt = jwt?.expiresAt ?? nil

                        var claim = jwt?.claim(name: "name")
                        self.name = claim?.string ?? "unknown"
                        
                        
                        claim = jwt?.claim(name: "scp")
                        self.scope = claim?.string ?? "unknown"
                        
                        claim = jwt?.claim(name: "signInNamesInfo.emailAddress")
                        self.email = claim?.string ?? "unknown"
                    }
                }
            TextField("Subject", text: $subject)
            Button {
                Task {
                    
                    let options = [
                      "issuer": ISSUER,
                      "exp": true,
                      "iat": true,
                      "scp": "TLV.Digitel"
                    ] as [String: Any]

                    let validator = OktaJWTValidator(options)

                    do {
                        if let accessToken = jsonTokens?.access_token {

                            _ = try validator.isValid(accessToken)
                            validationMessage = "The token is valid"
                            
                        }

                    } catch let error {
                        validationMessage = "Error: \(error)"
                    }

                    showVlidationResults = true

                }
            } label: {
                Text("Validate")
                    .padding(2)
            }
            .alert(isPresented: $showVlidationResults) {
                Alert(title: Text("Validation Results"), message: Text(validationMessage), dismissButton: .default(Text("OK")))
            }
            Button {
                self.stage = 0
            } label: {
                Text("Logout")
            }
            
        }
    }
}

struct OTPView: View {
    
    @Binding var stage: Int
    @Binding var phoneNumber: String
    @Binding var jsonTokens: DecodableTokens?

    @State private var otp: String = ""
    @State private var errorMessage: String = ""
    @State private var showError = false
    
    @State private var clientId: String = "8739c7f1-e812-4461-b9c8-d670307dd22b"
    
    var body: some View {
        VStack {
            HStack {
                Text("OTP")
                    .padding()
                    .font(.body)
                TextField("Code you've received", text: $otp)
                    .keyboardType(.numberPad)

            }
            Button {
                Task {

                    let url = URL(string: "https://tlvidentity.azurewebsites.net/api/OTPValidator")!
                    
                    let parameters: [String: String] = [
                        "phone_number": phoneNumber,
                        "otp": otp,
                        "client_id": clientId,
                        "scope": "openid offline_access https://TlvfpB2CPPR.onmicrosoft.com/\(clientId)/TLV.Digitel"
                    ]

                    AF.request(url, method: .post, parameters: parameters, encoder: URLEncodedFormParameterEncoder(destination: .queryString))
                        .responseDecodable(of: DecodableTokens.self) { response in
                            if response.response?.statusCode == 200 {
                                self.jsonTokens = response.value!
                                self.stage = 2
                            } else {
                                let error = response.result
                                print(error)
                            }
                    }

                }
            } label: {
                Text("Login")
                    .padding(2)
            }
//            .buttonStyle(BlueButton())
            
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
               
        }
    }
}

struct IdentityView: View {
    
    @State private var userId: String = "313069486"
    
    @Binding var stage: Int
    @Binding var phoneNumber: String
    
    @State private var showError = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        VStack {

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
                //.buttonStyle(BlueButton())
                
                if showError {
                    VStack {
                        TextField("", text: $errorMessage)
                            .padding()
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    
    @State private var stage: Int = 0
    @State private var phoneNumber: String = "0543307026"
    @State private var jsonTokens: DecodableTokens?
    
    var body: some View {
        VStack {
            Text("TLV Identity Platform")
                .font(.largeTitle)
            
            Group {
                switch stage {
                    case 0:
                        IdentityView(stage: $stage, phoneNumber: $phoneNumber)
                    case 1:
                        OTPView(stage: $stage, phoneNumber: $phoneNumber, jsonTokens: $jsonTokens)
                    case 2:
                        TokenView(stage: $stage, jsonTokens: $jsonTokens)
                    default:
                        Text("No action")
                }

            }
        }
    }
        
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
