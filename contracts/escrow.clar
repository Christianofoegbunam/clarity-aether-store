;; Escrow Contract

;; Constants
(define-constant err-insufficient-funds (err u200))
(define-constant err-unauthorized (err u201))
(define-constant err-invalid-status (err u202))
(define-constant timelock-period u144) ;; ~24 hours in blocks

;; Data structures
(define-map escrows
  { escrow-id: uint }
  {
    buyer: principal,
    seller: principal,
    amount: uint,
    status: (string-ascii 20),
    created-at: uint,
    completed-at: uint
  }
)

(define-data-var next-escrow-id uint u0)

;; Helper functions
(define-private (is-escrow-party (escrow-id uint))
  (let ((escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) false)))
    (or
      (is-eq tx-sender (get buyer escrow))
      (is-eq tx-sender (get seller escrow))
    )
  )
)

;; Public functions
(define-public (create-escrow (amount uint) (seller principal) (buyer principal) (listing-id uint))
  (let ((escrow-id (var-get next-escrow-id)))
    (try! (stx-transfer? amount buyer (as-contract tx-sender)))
    (map-insert escrows
      { escrow-id: escrow-id }
      {
        buyer: buyer,
        seller: seller, 
        amount: amount,
        status: "PENDING",
        created-at: block-height,
        completed-at: u0
      }
    )
    (var-set next-escrow-id (+ escrow-id u1))
    (ok escrow-id)
  )
)

(define-public (release-escrow (escrow-id uint))
  (let ((escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) (err err-unauthorized))))
    (asserts! (is-eq tx-sender (get buyer escrow)) (err err-unauthorized))
    (asserts! (is-eq (get status escrow) "PENDING") (err err-invalid-status))
    (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get seller escrow))))
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow { 
        status: "COMPLETED",
        completed-at: block-height
      })
    )
    (ok true)
  )
)

(define-public (refund-escrow (escrow-id uint))
  (let ((escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) (err err-unauthorized))))
    (asserts! 
      (and
        (is-eq (get status escrow) "PENDING")
        (>= block-height (+ (get created-at escrow) timelock-period))
      )
      (err err-invalid-status)
    )
    (try! (as-contract (stx-transfer? (get amount escrow) tx-sender (get buyer escrow))))
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow { 
        status: "REFUNDED",
        completed-at: block-height
      })
    )
    (ok true)
  )
)
