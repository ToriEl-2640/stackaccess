;; Accessibility Bounty Contract
;; Manages bounties for accessibility improvement tasks

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u400))
(define-constant err-not-creator (err u401))
(define-constant err-not-claimer (err u402))
(define-constant err-bounty-not-found (err u403))
(define-constant err-already-claimed (err u404))
(define-constant err-not-open (err u405))

;; Bounty Status
(define-constant STATUS-OPEN u1)
(define-constant STATUS-CLAIMED u2)
(define-constant STATUS-UNDER-REVIEW u3)
(define-constant STATUS-COMPLETED u4)
(define-constant STATUS-CANCELLED u5)

;; Data Variables
(define-data-var bounty-nonce uint u0)

;; Data Maps
(define-map bounties
  { bounty-id: uint }
    {
            creator: principal,
                claimer: (optional principal),
                    reward: uint,
                        title: (string-ascii 100),
                            description: (string-ascii 500),
                                category: (string-ascii 50),
                                    status: uint,
                                        created-at: uint,
                                            claimed-at: (optional uint),
                                                completed-at: (optional uint),
                                                    submission-url: (optional (string-ascii 200))
    }
)

(define-map bounty-escrow
  { bounty-id: uint }
    { amount: uint }
    )

    (define-map user-completed-bounties
      principal
        (list 50 uint)
        )

        ;; Create Bounty
        (define-public (create-bounty
          (reward uint)
            (title (string-ascii 100))
              (description (string-ascii 500))
                (category (string-ascii 50)))
                  (let
                      (
                              (bounty-id (+ (var-get bounty-nonce) u1))
                      )
                          (try! (stx-transfer? reward tx-sender (as-contract tx-sender)))
                              
                                  (map-set bounties
                                        { bounty-id: bounty-id }
                                              {
                                                        creator: tx-sender,
                                                                claimer: none,
                                                                        reward: reward,
                                                                                title: title,
                                                                                        description: description,
                                                                                                category: category,
                                                                                                        status: STATUS-OPEN,
                                                                                                                created-at: block-height,
                                                                                                                        claimed-at: none,
                                                                                                                                completed-at: none,
                                                                                                                                        submission-url: none
                                              }
                                  )
                                      
                                          (map-set bounty-escrow
                                                { bounty-id: bounty-id }
                                                      { amount: reward }
                                                          )
                                                              
                                                                  (var-set bounty-nonce bounty-id)
                                                                      (ok bounty-id)
                  )
        )

        ;; Claim Bounty
        (define-public (claim-bounty (bounty-id uint))
          (let
              (
                      (bounty (unwrap! (map-get? bounties { bounty-id: bounty-id }) err-bounty-not-found))
              )
                  (asserts! (is-eq (get status bounty) STATUS-OPEN) err-not-open)
                      (asserts! (not (is-eq tx-sender (get creator bounty))) err-not-creator)
                          
                              (ok (map-set bounties
                                    { bounty-id: bounty-id }
                                          (merge bounty {
                                                    claimer: (some tx-sender),
                                                            status: STATUS-CLAIMED,
                                                                    claimed-at: (some block-height)
                                          })
                              ))
          )
        )

        ;; Submit Work
        (define-public (submit-work (bounty-id uint) (submission-url (string-ascii 200)))
          (let
              (
                      (bounty (unwrap! (map-get? bounties { bounty-id: bounty-id }) err-bounty-not-found))
              )
                  (asserts! (is-eq (some tx-sender) (get claimer bounty)) err-not-claimer)
                      (asserts! (is-eq (get status bounty) STATUS-CLAIMED) err-not-open)
                          
                              (ok (map-set bounties
                                    { bounty-id: bounty-id }
                                          (merge bounty {
                                                    status: STATUS-UNDER-REVIEW,
                                                            submission-url: (some submission-url)
                                          })
                              ))
          )
        )

        ;; Approve and Release Payment
        (define-public (approve-submission (bounty-id uint))
          (let
              (
                      (bounty (unwrap! (map-get? bounties { bounty-id: bounty-id }) err-bounty-not))
              )))
                                          })))
              )))
                                          })))
              )))
                                              })
                      )))
    })