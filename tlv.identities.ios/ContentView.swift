//
//  ContentView.swift
//  tlv.identities.ios
//
//  Created by Oleg Kleiman on 02/07/2022.
//

import SwiftUI
import Foundation
import Alamofire
import SwiftyJSON
import JWTDecode

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

struct DecodableKeysResponse: Decodable {
    let keys: [KeyMetadata]
}

struct TokenView: View {
    
    @Binding var stage: Int
    @Binding var jsonTokens: [String: Any]
    
    @State private var issuer: String = ""
    @State private var subject: String = ""
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var scope: String = ""
    @State private var expiresAt: Date? = nil
    
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
                    if let accessToken = jsonTokens["access_token"] {
                        let jwt = try? decode(jwt: accessToken as! String)
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
                    
                    if let accessToken = jsonTokens["access_token"] as? String {
                        let parts = accessToken.components(separatedBy: ".")
                        
                        let header = parts[0]
                        
                        let payload = parts[1]
                    }
                    
                    var url = URL(string:"https://TlvfpB2CPPR.b2clogin.com/TlvfpB2CPPR.onmicrosoft.com/B2C_1A_B2C_1_ROPC_KIEV_RP/v2.0/.well-known/openid-configuration")!
                    
                    AF.request(url, method: .get)
                        .responseDecodable(of: DecodableMetadata.self) { response in
                            let keysUrl = response.value?.jwks_uri
                            
                            url = URL(string: keysUrl!)!
                            AF.request(url, method: .get)
                                .responseDecodable(of: DecodableKeysResponse.self) { response in
                                    let keys = response.value?.keys
                                    let key: KeyMetadata = (keys?[0])!
                                    let publicKey = key.n
                                    print(publicKey)
                                }
                        }

//
//                    if let accessToken = jsonTokens["access_token"] as? String {
//                        let parts = accessToken.components(separatedBy: ".")
//
//                        let header = parts[0]
//                        let payload = parts[1]
////                        let signature = Data(base64URLEncoded: parts[2])!
//
//                        let signingInput = (header + "." + payload).data(using: .ascii)!
////
////                        SecKeyVerifySignature(publicKey, .rsaSignatureMessagePKCS1v15SHA256, signingInput as CFData, signature as! CFData, nil))
//                    }
                }
            } label: {
                Text("Validate")
                    .padding(2)
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
    @Binding var jsonTokens: [String: Any]
    
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
                    
                    var components = URLComponents(string: "https://tlvidentity.azurewebsites.net/api/OTPValidator")!
                    components.queryItems = [
                        URLQueryItem(name: "phone_number", value: phoneNumber),
                        URLQueryItem(name: "otp", value: otp),
                        URLQueryItem(name: "client_id", value: clientId),
                        URLQueryItem(name: "scope", value: "openid offline_access https://TlvfpB2CPPR.onmicrosoft.com/\(clientId)/TLV.Digitel")
                    ]

                    var request = URLRequest(url: components.url!)
                    request.httpMethod = "POST"
                    
                    let task = URLSession.shared.dataTask(with: request) {data,
                        response, error in
                        
                        guard let data = data,
                              let response = response as? HTTPURLResponse,
                              200 ..< 300 ~= response.statusCode,
                            error == nil
                        else {
                            print(error?.localizedDescription ?? "No data")
                            return
                        }
                        
                        let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                        if let responseJSON = responseJSON as? [String: Any] {
                            print(responseJSON)
                            
                            if let status = responseJSON["status"] {
                                if( status as! Int != 200 ) {
                                    self.errorMessage = responseJSON["userMessage"] as! String
                                    showError.toggle()
                                } else {
                                    self.stage = 2
                                }
                            } else { // tokens obtained
                                
                                self.jsonTokens = responseJSON
                                self.stage = 2
                                
                            }

                        }

                    }
                    task.resume()
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
                        var request = URLRequest(url: url)
                        request.httpMethod = "POST"
                   
                        let json: [String: Any] = ["userId": userId,
                                                   "phoneNumber": phoneNumber]
                        let jsonData = try? JSONSerialization.data(withJSONObject: json)
                        
                        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
                        request.setValue("\(String(describing: jsonData?.count))", forHTTPHeaderField: "Content-Length")
                        
                        request.httpBody = jsonData
                        
                        let task = URLSession.shared.dataTask(with: request) {data, response, error in
                            
                            guard let data = data, error == nil else {
                                print(error?.localizedDescription ?? "No data")
                                return
                            }
                            
                            let responseJSON = try? JSONSerialization.jsonObject(with: data, options: [])
                            if let responseJSON = responseJSON as? [String: Any] {
                                print(responseJSON)
                                if !(responseJSON["isError"] as! Bool) {
                                    self.stage = 1
                                } else {
                                    self.errorMessage = (responseJSON["errorDesc"] as? String)!
                                    self.showError = true
                                }
                            }

                        }
                        task.resume()
                        
                        
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
    @State private var jsonTokens: [String: Any] = [:]
    
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
