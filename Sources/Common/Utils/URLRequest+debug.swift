import Foundation

extension URLRequest {
    var cURL: String {
        guard let url = self.url else {
            return ""
        }

        var baseCommand = #"curl "\#(url.absoluteString)""#

        if self.httpMethod == "HEAD" {
            baseCommand += " --head"
        }

        var command = [baseCommand]

        if let method = self.httpMethod, method != "GET" && method != "HEAD" {
            command.append("-X \(method)")
        }

        if let headers = self.allHTTPHeaderFields {
            for (key, value) in headers {
                command.append("-H '\(key): \(value)'")
            }
        }

        if let data = self.httpBody, let body = String(data: data, encoding: .utf8) {
            let cleanBody = body.replacingOccurrences(of: #"\n"#, with: "")
            command.append("-d '\(cleanBody)'")
        }

        return command.joined(separator: " \\\n\t")
    }
}
