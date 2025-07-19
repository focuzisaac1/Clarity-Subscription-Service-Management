;; Billing Cycle Contract
;; Manages recurring payment processing and billing periods

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-SUBSCRIPTION-NOT-FOUND (err u103))
(define-constant ERR-PAYMENT-FAILED (err u106))
(define-constant ERR-INVALID-STATUS (err u105))

;; Data Variables
(define-data-var total-payments-processed uint u0)
(define-data-var total-revenue uint u0)

;; Data Maps
(define-map billing-cycles
  { user: principal }
  {
    next-billing-date: uint,
    last-payment-date: uint,
    payment-amount: uint,
    billing-status: (string-ascii 20),
    failed-payments: uint
  }
)

(define-map payment-history
  { user: principal, payment-id: uint }
  {
    amount: uint,
    processed-at: uint,
    status: (string-ascii 20),
    block-height: uint
  }
)

(define-map user-payment-counts
  { user: principal }
  { count: uint }
)

;; Public Functions
(define-public (process-payment (user principal) (amount uint))
  (let (
    (billing-cycle (unwrap! (map-get? billing-cycles { user: user }) ERR-SUBSCRIPTION-NOT-FOUND))
    (current-block block-height)
    (payment-count (default-to u0 (get count (map-get? user-payment-counts { user: user }))))
  )
    ;; Validate billing status
    (asserts! (is-eq (get billing-status billing-cycle) "active") ERR-INVALID-STATUS)

    ;; Check if payment is due
    (asserts! (<= (get next-billing-date billing-cycle) current-block) ERR-NOT-AUTHORIZED)

    ;; Validate payment amount
    (asserts! (>= amount (get payment-amount billing-cycle)) ERR-PAYMENT-FAILED)

    ;; Process payment (simplified - would transfer STX in real implementation)
    (asserts! (>= (stx-get-balance user) amount) ERR-PAYMENT-FAILED)

    ;; Update billing cycle
    (map-set billing-cycles { user: user }
      (merge billing-cycle {
        next-billing-date: (+ current-block u4320), ;; Next month
        last-payment-date: current-block,
        failed-payments: u0
      })
    )

    ;; Record payment history
    (map-set payment-history { user: user, payment-id: (+ payment-count u1) }
      {
        amount: amount,
        processed-at: current-block,
        status: "completed",
        block-height: current-block
      }
    )

    ;; Update payment count
    (map-set user-payment-counts { user: user } { count: (+ payment-count u1) })

    ;; Update totals
    (var-set total-payments-processed (+ (var-get total-payments-processed) u1))
    (var-set total-revenue (+ (var-get total-revenue) amount))

    (ok true)
  )
)

(define-public (update-billing-cycle (user principal) (new-amount uint))
  (let (
    (billing-cycle (unwrap! (map-get? billing-cycles { user: user }) ERR-SUBSCRIPTION-NOT-FOUND))
  )
    ;; Only contract owner can update billing
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    ;; Update billing cycle
    (map-set billing-cycles { user: user }
      (merge billing-cycle { payment-amount: new-amount })
    )

    (ok true)
  )
)

(define-public (initialize-billing (user principal) (amount uint))
  (let (
    (current-block block-height)
  )
    ;; Check if billing cycle already exists
    (asserts! (is-none (map-get? billing-cycles { user: user })) ERR-NOT-AUTHORIZED)

    ;; Create new billing cycle
    (map-set billing-cycles { user: user }
      {
        next-billing-date: (+ current-block u4320),
        last-payment-date: current-block,
        payment-amount: amount,
        billing-status: "active",
        failed-payments: u0
      }
    )

    ;; Initialize payment count
    (map-set user-payment-counts { user: user } { count: u0 })

    (ok true)
  )
)

;; Read-only Functions
(define-read-only (get-billing-cycle (user principal))
  (map-get? billing-cycles { user: user })
)

(define-read-only (get-next-billing-date (user principal))
  (match (map-get? billing-cycles { user: user })
    billing-cycle (some (get next-billing-date billing-cycle))
    none
  )
)

(define-read-only (get-payment-history (user principal) (payment-id uint))
  (map-get? payment-history { user: user, payment-id: payment-id })
)

(define-read-only (get-total-revenue)
  (var-get total-revenue)
)

(define-read-only (is-payment-due (user principal))
  (match (map-get? billing-cycles { user: user })
    billing-cycle (<= (get next-billing-date billing-cycle) block-height)
    false
  )
)
