//
//  ActivateChallengeResponse.swift
//  UrbanHunt
//
//  Response when activating a challenge
//

import Foundation

struct ActivateChallengeResponse: Codable {
    let challenge: Challenge
    let confirmationId: String
}