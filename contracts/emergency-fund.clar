;; Emergency Access Fund Contract
;; Community-powered emergency assistance fund

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u300))
(define-constant err-not-authorized (err u301))
(define-constant err-insufficient-funds (err u302))
(define-constant err-request-not-found (err u303))
(define-constant err-already-voted (err u304))
(define-constant err-request-closed (err u305))
(define-constant err-max-amount-exceeded (err u307))
(define-constant err-cooldown-active (err u308))

;; Constants for fund management
(define-constant max-request-amount u500000000) ;; 500 STX
(define-constant voting-period u144) ;; ~24 hours in blocks
(define-constant approval-threshold u60) ;; 60% approval
(define-constant cooldown-period u1008) ;; ~1 week in blocks

;; Data Variables
(define-data-var total-fund-balance uint u0)
(define-data-var request-nonce uint u0)
(define-data-var total-distributed uint u0)
(define-data-var people-helped uint u0)

;; Request Status
(define-constant STATUS-PENDING u1)
(define-constant STATUS-APPROVED u2)
(define-constant STATUS-REJECTED u3)
(define-constant STATUS-DISTRIBUTED u4)

;; Data Maps
(define-map fund-requests
  { request-id: uint }
    {
            requester: principal,
                amount: uint,
                    reason: (string-ascii 200),
                        created-at: uint,
                            status: uint,
                                votes-for: uint,
                                    votes-against: uint,
                                        total-voters: uint
    }
)

(define-map request-votes
  { request-id: uint, voter: principal }
    { vote: bool }
    )

    (define-map last-request-time
      principal
        uint
        )

        (define-map contributor-balance
          principal
            uint
            )

            ;; Contribute to Fund
            (define-public (contribute (amount uint))
              (begin
                  (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
                      (var-set total-fund-balance (+ (var-get total-fund-balance) amount))
                          (let
                                (
                                            (current-contribution (default-to u0 (map-get? contributor-balance tx-sender)))
                                )
                                      (map-set contributor-balance tx-sender (+ current-contribution amount))
                          )
                              (ok true)
              )
            )

            ;; Request Emergency Funds
            (define-public (request-funds (amount uint) (reason (string-ascii 200)))
              (let
                  (
                          (request-id (+ (var-get request-nonce) u1))
                                (last-request (default-to u0 (map-get? last-request-time tx-sender)))
                  )
                      (asserts! (<= amount max-request-amount) err-max-amount-exceeded)
                          (asserts! (>= (- block-height last-request) cooldown-period) err-cooldown-active)
                              (asserts! (<= amount (var-get total-fund-balance)) err-insufficient-funds)
                                  
                                      (map-set fund-requests
                                            { request-id: request-id }
                                                  {
                                                            requester: tx-sender,
                                                                    amount: amount,
                                                                            reason: reason,
                                                                                    created-at: block-height,
                                                                                            status: STATUS-PENDING,
                                                                                                    votes-for: u0,
                                                                                                            votes-against: u0,
                                                                                                                    total-voters: u0
                                                  }
                                      )
                                          
                                              (var-set request-nonce request-id)
                                                  (map-set last-request-time tx-sender block-height)
                                                      
                                                          (ok request-id)
              )
            )

            ;; Vote on Request
            (define-public (vote-on-request (request-id uint) (approve bool))
              (let
                  (
                          (request (unwrap! (map-get? fund-requests { request-id: request-id }) err-request-not-found))
                                (contribution (default-to u0 (map-get? contributor-balance tx-sender)))
                  )
                      (asserts! (> contribution u0) err-not-authorized)
                          (asserts! (is-none (map-get? request-votes { request-id: request-id, voter: tx-sender })) err-already-voted)
                              (asserts! (is-eq (get status request) STATUS-PENDING) err-request-closed)
                                  (asserts! (< (- block-height (get created-at request)) voting-period) err-request-closed)
                                      
                                          (map-set request-votes
                                                { request-id: request-id, voter: tx-sender }
                                                      { vote: approve }
                                                          )
                                                              
                                                                  (map-set fund-requests
                                                                        { request-id: request-id }
                                                                              (merge request {
                                                                                        votes-for: (if approve (+ (get votes-for request) u1) (get votes-for request)),
                                                                                                votes-against: (if approve (get votes-against request) (+ (get votes-against request) u1)),
                                                                                                        total-voters: (+ (get total-voters request) u1)
                                                                              })
                                                                  )
                                                                      
                                                                          (ok true)
              )
            )

            ;; Finalize Request
            (define-public (finalize-request (request-id uint))
              (let
                  (
                          (request (unwrap! (map-get? fund-requests { request-id: request-id }) err-request-not-found))
                                (total-votes (get total-voters request))
                                      (votes-for (get votes-for request))
                                            (approval-rate (if (> total-votes u0) (/ (* votes-for u100) total-votes) u0))
                  )
                      (asserts! (>= (- block-height (get created-at request)) voting-period) (err u309))
                          (asserts! (is-eq (get status request) STATUS-PENDING) err-request-closed)
                              
                                  (if (>= approval-rate approval-threshold)
                                        (begin
                                                (try! (as-contract (stx-transfer? (get amount request) tx-sender (get requester request))))
                                                        (var-set total-fund-balance (- (var-get total-fund-balance) (get amount request)))
                                                                (var-set total-distributed (+ (var-get total-distributed) (get amount request)))
                                                                        (var-set people-helped (+ (var-get people-helped) u1))
                                                                                
                                                                                        (ok (map-set fund-requests
                                                                                                  { request-id: request-id }
                                                                                                            (merge request { status: STATUS-DISTRIBUTED })
                                                                                                                    ))
                                                                                                                          )
                                                                                                                                (ok (map-set fund-requests
                                                                                                                                        { request-id: request-id }
                                                                                                                                                (merge request { status: STATUS-REJECTED })
                                                                                                                                                      ))
                                                                                                                                                          )
              )
            )

            ;; Read-only functions
            (define-read-only (get-fund-balance)
              (ok (var-get total-fund-balance))
              )

              (define-read-only (get-total-distributed)
                (ok (var-get total-distributed))
                )

                (define-read-only (get-people-helped)
                  (ok (var-get people-helped))
                  )

                  (define-read-only (get-request (request-id uint))
                    (ok (map-get? fund-requests { request-id: request-id }))
                    )

                    (define-read-only (get-contributor-balance (contributor principal))
                      (ok (default-to u0 (map-get? contributor-balance contributor)))
                      )
                  )))
                                                                              }))
                  )))
                                                  })
                  )))
                                ))))
    })