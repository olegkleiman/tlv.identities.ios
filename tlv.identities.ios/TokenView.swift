//
//  TokenView.swift
//  tlv.identities.ios
//
//  Created by Oleg Kleiman on 05/07/2022.
//

import SwiftUI
import Foundation
import JWTDecode
import OktaJWT

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
            Text("Parsed ID Token:")
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
                    if let id_token = jsonTokens?.id_token {
                        let jwt = try? decode(jwt: id_token)
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

