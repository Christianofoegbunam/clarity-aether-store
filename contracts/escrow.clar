;; Escrow Contract with Enhanced Security

;; Constants
(define-constant err-insufficient-funds (err u200))
(define-constant err-unauthorized (err u201))
(define-constant err-invalid-status (err u202))
(define-constant err-no-dispute (err u203))
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
    completed-at: uint,
    dispute: (optional {
      reason: (string-utf8 500),
      created-at: uint,
      resolution: (optional (string-ascii 20))
    })
  }
)

;; [Previous functions remain unchanged...]

(define-public (raise-dispute (escrow-id uint) (reason (string-utf8 500)))
  (let ((escrow (unwrap! (map-get? escrows { escrow-id: escrow-id }) (err err-unauthorized))))
    (asserts! (is-eq (get status escrow) "PENDING") (err err-invalid-status))
    (asserts! (is-eq tx-sender (get buyer escrow)) (err err-unauthorized))
    (map-set escrows
      { escrow-id: escrow-id }
      (merge escrow {
        status: "DISPUTED",
        dispute: (some {
          reason: reason,
          created-at: block-height,
          resolution: none
        })
      })
    )
    (ok true)
  )
)
