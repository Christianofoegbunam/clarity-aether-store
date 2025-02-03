;; Reputation Contract

;; Constants
(define-constant err-invalid-rating (err u300))

;; Data structures
(define-map user-ratings
  { user: principal }
  { 
    total-rating: uint,
    rating-count: uint
  }
)

;; Public functions
(define-public (rate-user (user principal) (rating uint))
  (if (and (>= rating u1) (<= rating u5))
    (let ((current-ratings (default-to { total-rating: u0, rating-count: u0 } 
                          (map-get? user-ratings { user: user }))))
      (map-set user-ratings
        { user: user }
        {
          total-rating: (+ (get total-rating current-ratings) rating),
          rating-count: (+ (get rating-count current-ratings) u1)
        }
      )
      (ok true)
    )
    (err err-invalid-rating)
  )
)
