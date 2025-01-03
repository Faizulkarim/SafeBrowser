//
//  DnsManager.swift
//  SafeBrowser
//
//  Created by Md Faizul karim on 31/12/24.
//

import Foundation
import Combine
import NIO
import NIOExtras


final class DNSHandler: ChannelInboundHandler {
    typealias InboundIn = AddressedEnvelope<ByteBuffer>
    typealias OutboundOut = AddressedEnvelope<ByteBuffer>
    
    let domain: String
    var dnsAnswerPublisher = PassthroughSubject<String, Never>()
    init(domain: String) {
        self.domain = domain
    }
    
    func channelActive(context: ChannelHandlerContext) {
        print("Channel active, sending DNS query for \(domain)")
        
        // Create DNS query packet
        var buffer = context.channel.allocator.buffer(capacity: 512)
        let queryID: UInt16 = 12345
        let flags: UInt16 = 0x0100 // Standard query
        let qdCount: UInt16 = 1    // One question
        let anCount: UInt16 = 0    // No answers initially
        let nsCount: UInt16 = 0    // No authority
        let arCount: UInt16 = 0    // No additional
        
        // Write DNS header
        buffer.writeInteger(queryID)
        buffer.writeInteger(flags)
        buffer.writeInteger(qdCount)
        buffer.writeInteger(anCount)
        buffer.writeInteger(nsCount)
        buffer.writeInteger(arCount)
        
        // Write DNS Question
        let labels = domain.split(separator: ".")
        for label in labels {
            buffer.writeInteger(UInt8(label.count))
            buffer.writeBytes(Array(label.utf8))
        }
        buffer.writeInteger(UInt8(0)) // End of QNAME
        buffer.writeInteger(UInt16(1)) // QTYPE (A)
        buffer.writeInteger(UInt16(1)) // QCLASS (IN)
        
        // Send the packet
        let address = try! SocketAddress(ipAddress: "51.142.0.102", port: 53)
        let envelope = AddressedEnvelope(remoteAddress: address, data: buffer)
        context.writeAndFlush(self.wrapOutboundOut(envelope), promise: nil)
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let envelope = unwrapInboundIn(data)
        var buffer = envelope.data
        
        do {
            // Parse the DNS response header
            let queryID = buffer.readInteger(as: UInt16.self)
            let flags = buffer.readInteger(as: UInt16.self)
            let qdCount = buffer.readInteger(as: UInt16.self)
            let anCount = buffer.readInteger(as: UInt16.self)
            let nsCount = buffer.readInteger(as: UInt16.self)
            let arCount = buffer.readInteger(as: UInt16.self)
            
            print("Response: queryID=\(String(describing: queryID)), flags=\(String(describing: flags)), qdCount=\(qdCount), anCount=\(anCount), nsCount=\(nsCount), arCount=\(arCount)")
            
            // Skip the question section (domain query)
            for _ in 0..<(qdCount ?? 0) {
                // Read domain name
                let name = try readDomainName(from: &buffer)
                // Read QTYPE and QCLASS (we know we queried for A record)
                let qtype = buffer.readInteger(as: UInt16.self)
                let qclass = buffer.readInteger(as: UInt16.self)
                print("Query: name=\(name), qtype=\(qtype), qclass=\(qclass)")
            }
            
            if let answerCount = anCount, answerCount > 0 {
                print("Parsing answers...")
                // Read answers section
                for _ in 0..<answerCount {
                    let name = try readDomainName(from: &buffer)
                    let type = buffer.readInteger(as: UInt16.self)
                    let classType = buffer.readInteger(as: UInt16.self)
                    let ttl = buffer.readInteger(as: UInt32.self)
                    let dataLength = buffer.readInteger(as: UInt16.self)
                    
                    
                    let answer = "Answer: name=\(name), type=\(type), class=\(classType), ttl=\(ttl), dataLength=\(dataLength)"
                    print(answer)
                    dnsAnswerPublisher.send(answer)
                    if type == 1 {  // A record type
                        // Read the IP address (4 bytes for IPv4)
                        let ipAddress = buffer.readBytes(length: 4)
                        if let ipAddress = ipAddress {
                            let ip = ipAddress.map { String($0) }.joined(separator: ".")
                            print("Resolved IP address: \(ip)")
                        }
                    }
                }
            } else {
                print("No answers found in response.")
                dnsAnswerPublisher.send("not found")
            }
            
            context.close(promise: nil)
        } catch {
            print("Error parsing DNS response: \(error)")
            context.close(promise: nil)
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error.localizedDescription)")
        context.close(promise: nil)
    }
    
    func readDomainName(from buffer: inout ByteBuffer) throws -> String {
        var domainParts: [String] = []
        
        while true {
            let length = buffer.readInteger(as: UInt8.self)
            guard let length = length else {
                throw NSError(domain: "DNSParser", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to read domain length"])
            }
            if length == 0 {
                break
            }
            let part = buffer.readString(length: Int(length)) ?? ""
            domainParts.append(part)
        }
        
        return domainParts.joined(separator: ".")
    }
}




