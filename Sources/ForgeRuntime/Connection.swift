//
// Created by v.prusakov on 12/21/22.
//

import Foundation

public struct Connection<Input: Encodable, Output: Decodable> {

    let input: FileHandle
    let output: FileHandle

    public init(input: FileHandle, output: FileHandle) {
        self.input = input
        self.output = output
    }

    public func send(_ input: Input) throws {
        let data = try JSONEncoder().encode(input)

        var payloadCountData = UInt64(littleEndian: UInt64(data.count))

        try withUnsafeBytes(of: &payloadCountData) {
            try self.output.write(contentsOf: Data($0))
        }

        try self.output.write(contentsOf: data)
    }

    public func receiveNextMessage() throws -> Output? {
        guard let header = try self.input.read(upToCount: 8) else {
            return nil
        }

        if header.count != 8 {
            throw Error.invalidHeader
        }

        let payloadCount = header.withUnsafeBytes { $0.load(as: UInt64.self) }.littleEndian

        guard payloadCount >= 2 else {
            throw Error.invalidPayloadCount
        }

        guard let payload = try self.input.read(upToCount: Int(payloadCount)), payload.count == payloadCount else {
            throw Error.invalidPayload(count: Int(payloadCount))
        }

        return try JSONDecoder().decode(Output.self, from: payload)
    }

    enum Error: Swift.Error {
        case invalidHeader
        case invalidPayloadCount
        case invalidPayload(count: Int)
    }
}
