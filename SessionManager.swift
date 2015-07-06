//
//  SessionManager.swift
//  Chainlink
//
//  Created by AJ Priola on 6/30/15.
//  Copyright © 2015 AJ Priola. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class SessionManager: NSObject, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate, MCSessionDelegate {
    
    var controller:ViewController!
    let serviceType = "bluenet"
    var browser : MCNearbyServiceBrowser!
    var advertiser : MCNearbyServiceAdvertiser!
    var peerID: MCPeerID
    var session: MCSession
    var numberOfConnections = 0
    var sessions = [MCSession]()
    
    init(controller:ViewController, id:String) {
        peerID = MCPeerID(displayName: id)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
        sessions.append(session)
        super.init()
        
        self.controller = controller
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.advertiser.delegate = self
        self.session.delegate = self
        
        self.advertiser.startAdvertisingPeer()
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        self.browser.delegate = self
        browser.startBrowsingForPeers()
    }
    
    func close() {
        for session in sessions {
            session.disconnect()
        }
        sessions.removeAll()
        browser.stopBrowsingForPeers()
        advertiser.stopAdvertisingPeer()
    }
    
    @objc func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        if sessions.last!.connectedPeers.count > 7 {
            let newSession = MCSession(peer: peerID)
            self.sessions.append(newSession)
            newSession.delegate = self
            browser.invitePeer(peerID, toSession: newSession, withContext: nil, timeout: 10)
        } else {
            browser.invitePeer(peerID, toSession: sessions.last!, withContext: nil, timeout: 10)
        }
    }
    
    @objc func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) { }
    
    @objc func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        if sessions.last!.connectedPeers.count > 7 {
            let newSession = MCSession(peer: peerID)
            self.sessions.append(newSession)
            newSession.delegate = self
            invitationHandler(true, newSession)
        } else {
            invitationHandler(true, sessions.last!)
        }
    }
    
    func sendData(data:NSData, type:String) {
        for session in sessions {
            guard type == "m" else { return }
            
            do {
                try session.sendData(data, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
            } catch { }
        }
    }
    
    func updateConnectionsCount() {
        var c = 0
        c += session.connectedPeers.count
        self.numberOfConnections = c
        self.controller.updateCount(c)
    }
    
   @objc
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        let message = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? MessageObject
        dispatch_async(dispatch_get_main_queue()) {
            self.controller.displayNewMessage(message!)
        }
    }
    
    @objc func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        switch state {
        case MCSessionState.Connected:
            dispatch_async(dispatch_get_main_queue()) {
                self.controller.displaySystemMessage("@\(peerID.displayName) connected!")
                self.updateConnectionsCount()
            }
        case MCSessionState.Connecting:
            self.controller.updateCount(0)
        case MCSessionState.NotConnected:
            dispatch_async(dispatch_get_main_queue()) {
                self.controller.displaySystemMessage("@\(peerID.displayName) disconnected.")
                self.updateConnectionsCount()
            }
        }
    }
    
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError) { }
    
    func session(session: MCSession, didReceiveCertificate certificate: [AnyObject]?, fromPeer peerID: MCPeerID, certificateHandler: (Bool) -> Void) {
        certificateHandler(true)
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) { }
}