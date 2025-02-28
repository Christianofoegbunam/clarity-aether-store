;; AetherStore Main Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-invalid-price (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-inactive-listing (err u104))

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

;; Helper functions
(define-private (is-valid-price (price uint))
  (> price u0)
)

(define-private (is-listing-owner (listing-id uint))
  (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) false)))
    (is-eq tx-sender (get seller listing))
  )
)

;; Public functions
(define-public (create-listing (price uint) (title (string-utf8 100)) (description (string-utf8 500)))
  (begin
    (asserts! (is-valid-price price) (err err-invalid-price))
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
)

(define-public (update-listing (listing-id uint) (price uint) (title (string-utf8 100)) (description (string-utf8 500)))
  (begin
    (asserts! (is-listing-owner listing-id) (err err-unauthorized))
    (asserts! (is-valid-price price) (err err-invalid-price))
    (map-set listings
      { listing-id: listing-id }
      {
        seller: tx-sender,
        price: price,
        title: title,
        description: description,
        active: true
      }
    )
    (ok true)
  )
)

(define-public (deactivate-listing (listing-id uint))
  (begin
    (asserts! (is-listing-owner listing-id) (err err-unauthorized))
    (map-set listings
      { listing-id: listing-id }
      (merge (unwrap! (map-get? listings { listing-id: listing-id }) (err err-listing-not-found))
        { active: false })
    )
    (ok true)
  )
)

(define-public (purchase-listing (listing-id uint))
  (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) (err err-listing-not-found))))
    (asserts! (get active listing) (err err-inactive-listing))
    (let ((price (get price listing))
         (seller (get seller listing)))
      (try! (contract-call? .escrow create-escrow price seller tx-sender listing-id))
      (ok true)
    )
  )
)
