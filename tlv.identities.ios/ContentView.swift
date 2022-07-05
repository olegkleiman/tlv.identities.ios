//
//  ContentView.swift
//  tlv.identities.ios
//
//  Created by Oleg Kleiman on 02/07/2022.
//

import SwiftUI
import Foundation

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
