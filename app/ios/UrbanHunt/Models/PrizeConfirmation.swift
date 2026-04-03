//
//  PrizeConfirmation.swift
//  UrbanHunt
//
//  Model for prize confirmation
//

import Foundation

struct PrizeConfirmation: Codable, Identifiable {
    let id: String
    let challengeId: String
    var userId: String?
    var status: ConfirmationStatus
    var message: String?
    var contentUrl: String?
    let createdAt: Date
    var confirmedAt: Date?

    enum ConfirmationStatus: String, Codable {
        case new = "NEW"
        case done = "DONE"
    }
}