// Mints a short-lived App Store Connect API JWT (ES256) and prints it.
// Env: ASC_KEY_ID, ASC_ISSUER_ID, and the key at
//      ~/.appstoreconnect/private_keys/AuthKey_<ASC_KEY_ID>.p8
import Foundation
import CryptoKit

let env = ProcessInfo.processInfo.environment
guard let kid = env["ASC_KEY_ID"], let iss = env["ASC_ISSUER_ID"] else {
    FileHandle.standardError.write("set ASC_KEY_ID / ASC_ISSUER_ID\n".data(using: .utf8)!); exit(2)
}
let p8 = "\(NSHomeDirectory())/.appstoreconnect/private_keys/AuthKey_\(kid).p8"
let pem = try String(contentsOfFile: p8, encoding: .utf8)
let key = try P256.Signing.PrivateKey(pemRepresentation: pem)

func b64url(_ d: Data) -> String {
    d.base64EncodedString().replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: "=", with: "")
}
let header = #"{"alg":"ES256","kid":"\#(kid)","typ":"JWT"}"#
let now = Int(Date().timeIntervalSince1970)
let payload = #"{"iss":"\#(iss)","iat":\#(now),"exp":\#(now + 1080),"aud":"appstoreconnect-v1"}"#
let signingInput = b64url(Data(header.utf8)) + "." + b64url(Data(payload.utf8))
let sig = try key.signature(for: Data(signingInput.utf8))
print(signingInput + "." + b64url(sig.rawRepresentation))
