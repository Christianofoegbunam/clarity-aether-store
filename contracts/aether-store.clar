;; AetherStore Main Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-owner (err u100))
(define-constant err-invalid-price (err u101))
(define-constant err-listing-not-found (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-inactive-listing (err u104))
(define-constant err-expired-listing (err u105))
(define-constant err-invalid-category (err u106))

;; Data structures
(define-map categories 
  { category-id: uint }
  { name: (string-ascii 20) }
)

(define-map listings
  { listing-id: uint }
  {
    seller: principal,
    price: uint,
    title: (string-utf8 100),
    description: (string-utf8 500),
    category-id: uint,
    quantity: uint,
    active: bool,
    expires-at: uint
  }
)

(define-data-var next-listing-id uint u0)
(define-data-var next-category-id uint u0)

;; Helper functions
(define-private (is-valid-price (price uint))
  (> price u0)
)

(define-private (is-listing-owner (listing-id uint))
  (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) false)))
    (is-eq tx-sender (get seller listing))
  )
)

(define-private (is-listing-valid (listing-id uint))
  (let ((listing (unwrap! (map-get? listings { listing-id: listing-id }) false)))
    (and 
      (get active listing)
      (<= block-height (get expires-at listing))
      (> (get quantity listing) u0)
    )
  )
)

;; Admin functions
(define-public (add-category (name (string-ascii 20)))
  (begin
    (asserts! (is-eq tx-sender contract-owner) (err err-not-owner))
    (let ((category-id (var-get next-category-id)))
      (map-insert categories
        { category-id: category-id }
        { name: name }
      )
      (var-set next-category-id (+ category-id u1))
      (ok category-id)
    )
  )
)

;; Public functions
(define-public (create-listing 
  (price uint) 
  (title (string-utf8 100)) 
  (description (string-utf8 500))
  (category-id uint)
  (quantity uint)
  (expires-in uint)
)
  (begin
    (asserts! (is-valid-price price) (err err-invalid-price))
    (asserts! (map-get? categories { category-id: category-id }) (err err-invalid-category))
    (let ((listing-id (var-get next-listing-id)))
      (map-insert listings
        { listing-id: listing-id }
        {
          seller: tx-sender,
          price: price,
          title: title,
          description: description,
          category-id: category-id,
          quantity: quantity,
          active: true,
          expires-at: (+ block-height expires-in)
        }
      )
      (var-set next-listing-id (+ listing-id u1))
      (ok listing-id)
    )
  )
)

;; [Previous functions remain unchanged...]
