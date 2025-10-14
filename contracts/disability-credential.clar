;; Disability Credential NFT Contract
;; Manages verifiable disability credentials as privacy-preserving NFTs

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-authorized (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-not-found (err u103))
(define-constant err-invalid-issuer (err u104))

;; Data Variables
(define-data-var credential-nonce uint u0)

;; Data Maps
(define-map credentials
  { credential-id: uint }
    {
            holder: principal,
                issuer: principal,
                    issued-at: uint,
                        credential-type: (string-ascii 50),
                            valid: bool,
                                privacy-hash: (buff 32)
    }
)

(define-map authorized-issuers principal bool)

(define-map holder-credentials principal (list 10 uint))

;; NFT Definition
(define-non-fungible-token disability-credential uint)

;; Authorization Functions
(define-public (add-authorized-issuer (issuer principal))
  (begin
      (asserts! (is-eq tx-sender contract-owner) err-owner-only)
          (ok (map-set authorized-issuers issuer true))
            )
            )

            (define-public (remove-authorized-issuer (issuer principal))
              (begin
                  (asserts! (is-eq tx-sender contract-owner) err-owner-only)
                      (ok (map-delete authorized-issuers issuer))
                        )
                        )

                        (define-read-only (is-authorized-issuer (issuer principal))
                          (default-to false (map-get? authorized-issuers issuer))
                          )

                          ;; Credential Issuance
                          (define-public (issue-credential 
                            (holder principal)
                              (credential-type (string-ascii 50))
                                (privacy-hash (buff 32)))
                                  (let
                                      (
                                              (credential-id (+ (var-get credential-nonce) u1))
                                                    (issuer tx-sender)
                                      )
                                          (asserts! (is-authorized-issuer issuer) err-not-authorized)
                                              (try! (nft-mint? disability-credential credential-id holder))
                                                  (map-set credentials
                                                        { credential-id: credential-id }
                                                              {
                                                                        holder: holder,
                                                                                issuer: issuer,
                                                                                        issued-at: block-height,
                                                                                                credential-type: credential-type,
                                                                                                        valid: true,
                                                                                                                privacy-hash: privacy-hash
                                                              }
                                                  )
                                                      (var-set credential-nonce credential-id)
                                                          (update-holder-credentials holder credential-id)
                                                              (ok credential-id)
                                  )
                          )

                          ;; Update holder's credential list
                          (define-private (update-holder-credentials (holder principal) (credential-id uint))
                            (let
                                (
                                          (current-list (default-to (list) (map-get? holder-credentials holder)))
                                )
                                    (map-set holder-credentials holder (unwrap-panic (as-max-len? (append current-list credential-id) u10)))
                            )
                          )

                          ;; Credential Verification
                          (define-read-only (verify-credential (credential-id uint))
                            (let
                                (
                                          (credential-data (map-get? credentials { credential-id: credential-id }))
                                )
                                    (match credential-data
                                          credential (ok (get valid credential))
                                                (err err-not-found)
                                                    )
                            )
                          )

                          (define-read-only (get-credential-info (credential-id uint))
                            (ok (map-get? credentials { credential-id: credential-id }))
                            )

                            (define-read-only (get-holder-credentials (holder principal))
                              (ok (default-to (list) (map-get? holder-credentials holder)))
                              )

                              ;; Revoke Credential (only by issuer or contract owner)
                              (define-public (revoke-credential (credential-id uint))
                                (let
                                    (
                                              (credential-data (unwrap! (map-get? credentials { credential-id: credential-id }) err-not-found))
                                    )
                                        (asserts! 
                                              (or 
                                                      (is-eq tx-sender (get issuer credential-data))
                                                              (is-eq tx-sender contract-owner)
                                                                    ) 
                                                                          err-not-authorized
                                                                              )
                                                                                  (ok (map-set credentials
                                                                                        { credential-id: credential-id }
                                                                                              (merge credential-data { valid: false })
                                                                                                  ))
                                )
                              )

                              ;; Transfer credential NFT
                              (define-public (transfer (credential-id uint) (sender principal) (recipient principal))
                                (begin
                                    (asserts! (is-eq tx-sender sender) err-not-authorized)
                                        (try! (nft-transfer? disability-credential credential-id sender recipient))
                                            (let
                                                  (
                                                            (credential-data (unwrap! (map-get? credentials { credential-id: credential-id }) err-not-found))
                                                  )
                                                        (ok (map-set credentials
                                                                { credential-id: credential-id }
                                                                        (merge credential-data { holder: recipient })
                                                                              ))
                                            )
                                )
                              )

                              ;; Get owner of credential NFT
                              (define-read-only (get-owner (credential-id uint))
                                (ok (nft-get-owner? disability-credential credential-id))
                                )

                                ;; Check if holder has valid credential
                                (define-read-only (has-valid-credential (holder principal))
                                  (let
                                      (
                                              (credentials-list (default-to (list) (map-get? holder-credentials holder)))
                                      )
                                          (ok (> (len credentials-list) u0))
                                  )
                                )
                                      )))
                                                  ))))
                                    )))
                                )))
                                )))
                                                              })
                                      )))
    })