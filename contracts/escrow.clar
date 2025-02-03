;; Escrow Contract

;; Constants
(define-constant err-insufficient-funds (err u200))
(define-constant err-unauthorized (err u201))

;; Data structures
(define-map escrows
  { escrow-id: uint }
  {
    buyer: principal,
    seller: principal,
    amount: uint,
    status: (string-ascii 20)
  }
)

(define-data-var next-escrow-id uint u0)

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
        status: "PENDING"
      }
    )
    (var-set next-escrow-id (+ escrow-id u1))
    (ok escrow-id)
  )
)
