;; Marketplace Escrow Contract
;; Handles secure peer-to-peer transactions for assistive tech marketplace

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u200))
(define-constant err-not-seller (err u201))
(define-constant err-not-buyer (err u202))
(define-constant err-listing-not-found (err u203))
(define-constant err-listing-not-active (err u204))
(define-constant err-insufficient-payment (err u205))
(define-constant err-already-completed (err u206))
(define-constant err-dispute-period-active (err u207))

;; Platform fee (2%)
(define-constant platform-fee-percent u2)

;; Data Variables
(define-data-var listing-nonce uint u0)
(define-data-var platform-balance uint u0)

;; Listing Status
(define-constant STATUS-ACTIVE u1)
(define-constant STATUS-ESCROWED u2)
(define-constant STATUS-COMPLETED u3)
(define-constant STATUS-CANCELLED u4)
(define-constant STATUS-DISPUTED u5)

;; Data Maps
(define-map listings
  { listing-id: uint }
    {
            seller: principal,
                buyer: (optional principal),
                    price: uint,
                        title: (string-ascii 100),
                            category: (string-ascii 50),
                                status: uint,
                                    created-at: uint,
                                        escrow-released-at: (optional uint),
                                            description-hash: (buff 32)
    }
)

(define-map escrow-balance
  { listing-id: uint }
    { amount: uint }
    )

    (define-map seller-ratings
      principal
        { total-rating: uint, num-ratings: uint }
        )

        ;; Create Listing
        (define-public (create-listing 
          (price uint)
            (title (string-ascii 100))
              (category (string-ascii 50))
                (description-hash (buff 32)))
                  (let
                      (
                              (listing-id (+ (var-get listing-nonce) u1))
                      )
                          (map-set listings
                                { listing-id: listing-id }
                                      {
                                                seller: tx-sender,
                                                        buyer: none,
                                                                price: price,
                                                                        title: title,
                                                                                category: category,
                                                                                        status: STATUS-ACTIVE,
                                                                                                created-at: block-height,
                                                                                                        escrow-released-at: none,
                                                                                                                description-hash: description-hash
                                      }
                          )
                              (var-set listing-nonce listing-id)
                                  (ok listing-id)
                  )
        )

        ;; Purchase Item (places funds in escrow)
        (define-public (purchase-item (listing-id uint))
          (let
              (
                      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-listing-not-found))
                            (price (get price listing))
              )
                  (asserts! (is-eq (get status listing) STATUS-ACTIVE) err-listing-not-active)
                      (asserts! (not (is-eq tx-sender (get seller listing))) err-not-buyer)
                          
                              ;; Transfer payment to contract for escrow
                                  (try! (stx-transfer? price tx-sender (as-contract tx-sender)))
                                      
                                          ;; Update listing status
                                              (map-set listings
                                                    { listing-id: listing-id }
                                                          (merge listing {
                                                                    buyer: (some tx-sender),
                                                                            status: STATUS-ESCROWED
                                                          })
                                              )
                                                  
                                                      ;; Record escrow balance
                                                          (map-set escrow-balance
                                                                { listing-id: listing-id }
                                                                      { amount: price }
                                                                          )
                                                                              
                                                                                  (ok true)
          )
        )

        ;; Release Escrow (buyer confirms receipt)
        (define-public (confirm-receipt (listing-id uint))
          (let
              (
                      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-listing-not-found))
                            (escrow (unwrap! (map-get? escrow-balance { listing-id: listing-id }) err-listing-not-found))
                                  (price (get amount escrow))
                                        (platform-fee (/ (* price platform-fee-percent) u100))
                                              (seller-amount (- price platform-fee))
              )
                  (asserts! (is-eq (get status listing) STATUS-ESCROWED) err-listing-not-active)
                      (asserts! (is-eq (some tx-sender) (get buyer listing)) err-not-buyer)
                          
                              ;; Transfer funds to seller
                                  (try! (as-contract (stx-transfer? seller-amount tx-sender (get seller listing))))
                                      
                                          ;; Add platform fee to balance
                                              (var-set platform-balance (+ (var-get platform-balance) platform-fee))
                                                  
                                                      ;; Update listing status
                                                          (map-set listings
                                                                { listing-id: listing-id }
                                                                      (merge listing {
                                                                                status: STATUS-COMPLETED,
                                                                                        escrow-released-at: (some block-height)
                                                                      })
                                                          )
                                                              
                                                                  ;; Clear escrow
                                                                      (map-delete escrow-balance { listing-id: listing-id })
                                                                          
                                                                              (ok true)
          )
        )

        ;; Cancel Listing
        (define-public (cancel-listing (listing-id uint))
          (let
              (
                      (listing (unwrap! (map-get? listings { listing-id: listing-id }) err-listing-not-found))
              )
                  (asserts! (is-eq tx-sender (get seller listing)) err-not-seller)
                      (asserts! (is-eq (get status listing) STATUS-ACTIVE) err-listing-not-active)
                          
                              (ok (map-set listings
                                    { listing-id: listing-id }
                                          (merge listing { status: STATUS-CANCELLED })
                                              ))
          )
        )

        ;; Rate Seller
        (define-public (rate-seller (seller principal) (rating uint))
          (let
              (
                      (current-rating (default-to { total-rating: u0, num-ratings: u0 } 
                                             (map-get? seller-ratings seller)))
              )
                  (asserts! (<= rating u5) (err u209))
                      (ok (map-set seller-ratings
                            seller
                                  {
                                            total-rating: (+ (get total-rating current-rating) rating),
                                                    num-ratings: (+ (get num-ratings current-rating) u1)
                                  }
                      ))
          )
        )

        ;; Read-only functions
        (define-read-only (get-listing (listing-id uint))
          (ok (map-get? listings { listing-id: listing-id }))
          )

          (define-read-only (get-seller-rating (seller principal))
            (let
                (
                          (rating-data (default-to { total-rating: u0, num-ratings: u0 } 
                                              (map-get? seller-ratings seller)))
                )
                    (if (> (get num-ratings rating-data) u0)
                          (ok (/ (get total-rating rating-data) (get num-ratings rating-data)))
                                (ok u0)
                                    )
            )
          )

          (define-read-only (get-platform-balance)
            (ok (var-get platform-balance))
            )
                )))
                                  }))
              )))
              )))
                                                                      }))
              )))
                                                          }))
              )))
                                      })
                      )))
    })