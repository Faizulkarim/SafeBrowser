//
//  DNSResolverService.swift
//  SafeBrowser
//
//  Created by Md Faizul karim on 3/1/25.
//

import Foundation
import Combine
import NIO
import NIOExtras


protocol DNSResolverProtocol {
    func resolve(domain: String) -> AnyPublisher<String, Never>
}

final class DNSResolver: DNSResolverProtocol {
    func resolve(domain: String) -> AnyPublisher<String, Never> {
        let handler = DNSHandler(domain: domain)
        let subject = handler.dnsAnswerPublisher
        
        DispatchQueue.global(qos: .background).async {
            do {
                try self.performDNSResolution(handler: handler)
            } catch {
                subject.send("error")
            }
        }
        
        return subject.eraseToAnyPublisher()
    }
    
    private func performDNSResolution(handler: DNSHandler) throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        defer {
            try? group.syncShutdownGracefully()
        }
        
        let bootstrap = DatagramBootstrap(group: group)
            .channelInitializer { channel in
                channel.pipeline.addHandler(handler)
            }
            .channelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
        
        let channel = try bootstrap.bind(host: "0.0.0.0", port: 0).wait()
        try channel.closeFuture.wait()
    }
}
