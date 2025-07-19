;; Cancellation Processing Contract
;; Handles subscription terminations and cleanup

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-SUBSCRIPTION-NOT-FOUND (err u103))
(define-constant ERR-INVALID-STATUS (err u105))
(define-constant ERR-ALREADY-CANCELLED (err u109))

;; Data Variables
(define-data-var total-cancellations uint u0)
(define-data-var total-refunds-processed uint u0)

;; Data Maps
(define-map cancellation-requests
  { user: principal }
  {
    requested-at: uint,
    reason: (string-ascii 100),
    status: (string-ascii 20),
    refund-amount: uint,
    processed-at: (optional uint)
  }
)

(define-map subscription-status
  { user: principal }
  {
    status: (string-ascii 20),
    cancelled-at: (optional uint),
    final-billing-date: (optional uint),
    refund-eligible: bool
  }
)

;; Public Functions
(define-public (cancel-subscription (user principal) (reason (string-ascii 100)))
  (let (
    (current-block block-height)
    (existing-status (map-get? subscription-status { user: user }))
  )
    ;; Check if already cancelled
    (asserts!
      (match existing-status
        status (not (is-eq (get status status) "cancelled"))
        true
      )
      ERR-ALREADY-CANCELLED
    )

    ;; Create cancellation request
    (map-set cancellation-requests { user: user }
      {
        requested-at: current-block,
        reason: reason,
        status: "pending",
        refund-amount: u0,
        processed-at: none
      }
    )

    ;; Update subscription status
    (map-set subscription-status { user: user }
      {
        status: "cancelled",
        cancelled-at: (some current-block),
        final-billing-date: (some (+ current-block u4320)),
        refund-eligible: true
      }
    )

    ;; Update total cancellations
    (var-set total-cancellations (+ (var-get total-cancellations) u1))

    (ok true)
  )
)

(define-public (process-refund (user principal) (refund-amount uint))
  (let (
    (cancellation (unwrap! (map-get? cancellation-requests { user: user }) ERR-SUBSCRIPTION-NOT-FOUND))
    (current-block block-height)
  )
    ;; Only contract owner can process refunds
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Check if cancellation is pending
    (asserts! (is-eq (get status cancellation) "pending") ERR-INVALID-STATUS)

    ;; Update cancellation request
    (map-set cancellation-requests { user: user }
      (merge cancellation {
        status: "completed",
        refund-amount: refund-amount,
        processed-at: (some current-block)
      })
    )

    ;; Update refunds processed
    (var-set total-refunds-processed (+ (var-get total-refunds-processed) refund-amount))

    (ok true)
  )
)

(define-public (cleanup-subscription (user principal))
  (let (
    (cancellation (unwrap! (map-get? cancellation-requests { user: user }) ERR-SUBSCRIPTION-NOT-FOUND))
    (status (unwrap! (map-get? subscription-status { user: user }) ERR-SUBSCRIPTION-NOT-FOUND))
  )
    ;; Only process cleanup after cancellation is completed
    (asserts! (is-eq (get status cancellation) "completed") ERR-INVALID-STATUS)

    ;; Check if final billing date has passed
    (asserts!
      (match (get final-billing-date status)
        final-date (<= final-date block-height)
        false
      )
      ERR-NOT-AUTHORIZED
    )

    ;; Mark as cleaned up (in real implementation would remove data)
    (map-set subscription-status { user: user }
      (merge status { status: "cleaned-up" })
    )

    (ok true)
  )
)

(define-public (immediate-cancellation (user principal))
  (let (
    (current-block block-height)
  )
    ;; Only contract owner can do immediate cancellations
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Create immediate cancellation
    (map-set cancellation-requests { user: user }
      {
        requested-at: current-block,
        reason: "Administrative cancellation",
        status: "completed",
        refund-amount: u0,
        processed-at: (some current-block)
      }
    )

    ;; Update subscription status
    (map-set subscription-status { user: user }
      {
        status: "cancelled",
        cancelled-at: (some current-block),
        final-billing-date: (some current-block),
        refund-eligible: false
      }
    )

    (var-set total-cancellations (+ (var-get total-cancellations) u1))

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-cancellation-request (user principal))
  (map-get? cancellation-requests { user: user })
)

(define-read-only (get-subscription-status (user principal))
  (map-get? subscription-status { user: user })
)

(define-read-only (is-cancelled (user principal))
  (match (map-get? subscription-status { user: user })
    status (is-eq (get status status) "cancelled")
    false
  )
)

(define-read-only (get-total-cancellations)
  (var-get total-cancellations)
)

(define-read-only (get-total-refunds-processed)
  (var-get total-refunds-processed)
)

(define-read-only (is-refund-eligible (user principal))
  (match (map-get? subscription-status { user: user })
    status (get refund-eligible status)
    false
  )
)
