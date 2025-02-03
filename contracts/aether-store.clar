;; AetherStore Main Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-invalid-price (err u101))
(define-constant err-listing-not-found (err u102))

;; Data structures
(define-map listings
  { listing-id: uint }
  {
    seller: principal,
    price: uint,
    title: (string-utf8 100),
    description: (string-utf8 500),
    active: bool
  }
)

(define-data-var next-listing-id uint u0)

;; Public functions
(define-public (create-listing (price uint) (title (string-utf8 100)) (description (string-utf8 500)))
  (let ((listing-id (var-get next-listing-id)))
    (map-insert listings
      { listing-id: listing-id }
      {
        seller: tx-sender,
        price: price,
        title: title,
        description: description,
        active: true
      }
    )
    (var-set next-listing-id (+ listing-id u1))
    (ok listing-id)
  )
)

(define-public (purchase-listing (listing-id uint))
  (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) (err err-listing-not-found))))
    (if (get active listing)
      (let ((price (get price listing))
           (seller (get seller listing)))
        (try! (contract-call? .escrow create-escrow price seller tx-sender listing-id))
        (ok true)
      )
      (err err-listing-not-found)
    )
  )
)
