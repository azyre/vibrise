import Foundation
import Combine
import StoreKit

enum DonationPurchaseResult: Equatable {
    case success
    case pending
    case cancelled
}

protocol DonationPurchasing {
    func preloadProducts() async throws
    func purchaseDefaultTip() async throws -> DonationPurchaseResult
}

struct DonationCatalog {
    static let productIDs = [
        "com.azyre.vibrise.tip.coffee"
    ]
}

actor StoreKitDonationService: DonationPurchasing {
    private var cachedProducts: [Product] = []

    func preloadProducts() async throws {
        cachedProducts = try await loadProducts()
    }

    func purchaseDefaultTip() async throws -> DonationPurchaseResult {
        let products = if cachedProducts.isEmpty {
            try await loadProducts()
        } else {
            cachedProducts
        }

        guard let product = products.sorted(by: { $0.price < $1.price }).first else {
            throw DonationStoreError.productsUnavailable
        }

        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            return .success
        case .pending:
            return .pending
        case .userCancelled:
            return .cancelled
        @unknown default:
            return .cancelled
        }
    }

    private func loadProducts() async throws -> [Product] {
        let products = try await withThrowingTaskGroup(of: [Product].self) { group in
            group.addTask {
                try await Product.products(for: DonationCatalog.productIDs)
            }

            group.addTask {
                try await Task.sleep(for: .seconds(6))
                throw DonationStoreError.loadingTimedOut
            }

            let first = try await group.next() ?? []
            group.cancelAll()
            return first
        }

        if products.isEmpty {
            throw DonationStoreError.productsUnavailable
        }

        return products
    }

    private func checkVerified<T>(_ verification: VerificationResult<T>) throws -> T {
        switch verification {
        case .verified(let safe):
            return safe
        case .unverified:
            throw DonationStoreError.verificationFailed
        }
    }
}

enum DonationStoreError: LocalizedError {
    case productsUnavailable
    case verificationFailed
    case loadingTimedOut

    var errorDescription: String? {
        switch self {
        case .productsUnavailable:
            return "Donations aren't available yet"
        case .verificationFailed:
            return "Couldn't verify the purchase"
        case .loadingTimedOut:
            return "Donation store timed out"
        }
    }
}

@MainActor
final class DonationCoordinator: ObservableObject {
    @Published private(set) var isPurchaseInProgress = false
    @Published private(set) var isShowingThanksOverlay = false
    @Published private(set) var thanksMessage = "Thank You"
    @Published private(set) var transientMessage: String?
    @Published private(set) var isStoreReady = false

    private let service: DonationPurchasing
    private var preloadTask: Task<Void, Never>?
    private var thanksHideTask: Task<Void, Never>?
    private var transientHideTask: Task<Void, Never>?
    private var lastThanksMessage = ""

    init() {
        self.service = StoreKitDonationService()
    }

    init(service: DonationPurchasing) {
        self.service = service
    }

    func prepareStoreIfNeeded() {
        guard preloadTask == nil else { return }

        preloadTask = Task { [weak self] in
            defer { self?.preloadTask = nil }
            guard let self else { return }
            do {
                try await service.preloadProducts()
                isStoreReady = true
            } catch {
                isStoreReady = false
                showTransientMessage(error.localizedDescription)
            }
        }
    }

    func purchaseCoffee() {
        guard !isPurchaseInProgress else { return }

        isPurchaseInProgress = true
        Task { [weak self] in
            guard let self else { return }
            defer { self.isPurchaseInProgress = false }

            do {
                let result = try await service.purchaseDefaultTip()
                isStoreReady = true
                switch result {
                case .success:
                    showThanksOverlay()
                case .pending:
                    showTransientMessage("Purchase pending")
                case .cancelled:
                    break
                }
            } catch {
                isStoreReady = false
                showTransientMessage(error.localizedDescription)
            }
        }
    }

    private func showThanksOverlay() {
        thanksHideTask?.cancel()
        thanksMessage = nextThanksMessage()
        isShowingThanksOverlay = true

        thanksHideTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1600))
            self?.isShowingThanksOverlay = false
        }
    }

    private func showTransientMessage(_ message: String) {
        transientHideTask?.cancel()
        transientMessage = message

        transientHideTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(1800))
            self?.transientMessage = nil
        }
    }

    private func nextThanksMessage() -> String {
        let messages = [
            "Thank You",
            "Much Appreciated",
            "You're Awesome",
            "Truly Grateful",
            "Made My Day",
            "Deeply Touched",
            "Greatly Honored"
        ]

        let candidates = messages.filter { $0 != lastThanksMessage }
        let next = candidates.randomElement() ?? messages[0]
        lastThanksMessage = next
        return next
    }
}
