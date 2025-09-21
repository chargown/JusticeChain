
;; title: JusticeChain
;; version: 1.0.0
;; summary: Legal technology platform for jury assembly and verdict transparency
;; description: Smart contract for managing jury selection, case assignments, and transparent verdict recording

;; traits
;;

;; token definitions
;;

;; constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-status (err u104))
(define-constant err-jury-full (err u105))
(define-constant err-case-closed (err u106))

;; Jury status constants
(define-constant jury-status-available u0)
(define-constant jury-status-assigned u1)
(define-constant jury-status-dismissed u2)

;; Case status constants
(define-constant case-status-pending u0)
(define-constant case-status-active u1)
(define-constant case-status-closed u2)

;; data vars
(define-data-var next-case-id uint u1)
(define-data-var next-juror-id uint u1)

;; data maps

;; Juror registry
(define-map jurors
  { juror-id: uint }
  {
    principal: principal,
    status: uint,
    assigned-case: (optional uint),
    registration-block: uint
  }
)

;; Principal to juror ID mapping
(define-map principal-to-juror
  { principal: principal }
  { juror-id: uint }
)

;; Cases registry
(define-map cases
  { case-id: uint }
  {
    title: (string-ascii 100),
    description: (string-ascii 500),
    judge: principal,
    status: uint,
    jury-size: uint,
    created-block: uint,
    closed-block: (optional uint)
  }
)

;; Case jury assignments
(define-map case-jury
  { case-id: uint, juror-id: uint }
  { assigned-block: uint }
)

;; Verdicts
(define-map verdicts
  { case-id: uint }
  {
    verdict: (string-ascii 200),
    jury-votes: uint,
    recorded-block: uint,
    recorded-by: principal
  }
)

;; public functions

;; Register as a juror
(define-public (register-juror)
  (let
    ((juror-id (var-get next-juror-id)))
    (asserts! (is-none (map-get? principal-to-juror { principal: tx-sender })) err-already-exists)
    (map-set jurors
      { juror-id: juror-id }
      {
        principal: tx-sender,
        status: jury-status-available,
        assigned-case: none,
        registration-block: block-height
      }
    )
    (map-set principal-to-juror
      { principal: tx-sender }
      { juror-id: juror-id }
    )
    (var-set next-juror-id (+ juror-id u1))
    (ok juror-id)
  )
)

;; Create a new case (only contract owner for now)
(define-public (create-case (title (string-ascii 100)) (description (string-ascii 500)) (judge principal) (jury-size uint))
  (let
    ((case-id (var-get next-case-id)))
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (and (> jury-size u0) (<= jury-size u12)) err-invalid-status)
    (map-set cases
      { case-id: case-id }
      {
        title: title,
        description: description,
        judge: judge,
        status: case-status-pending,
        jury-size: jury-size,
        created-block: block-height,
        closed-block: none
      }
    )
    (var-set next-case-id (+ case-id u1))
    (ok case-id)
  )
)

;; Assign juror to case
(define-public (assign-juror-to-case (case-id uint) (juror-id uint))
  (let
    ((case-data (unwrap! (map-get? cases { case-id: case-id }) err-not-found))
     (juror-data (unwrap! (map-get? jurors { juror-id: juror-id }) err-not-found))
     (current-jury-count (get-case-jury-count case-id)))

    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-eq (get status case-data) case-status-pending) err-case-closed)
    (asserts! (is-eq (get status juror-data) jury-status-available) err-unauthorized)
    (asserts! (< current-jury-count (get jury-size case-data)) err-jury-full)

    ;; Update juror status
    (map-set jurors
      { juror-id: juror-id }
      (merge juror-data {
        status: jury-status-assigned,
        assigned-case: (some case-id)
      })
    )

    ;; Add to case jury
    (map-set case-jury
      { case-id: case-id, juror-id: juror-id }
      { assigned-block: block-height }
    )

    ;; If jury is full, activate the case
    (if (is-eq (+ current-jury-count u1) (get jury-size case-data))
      (map-set cases
        { case-id: case-id }
        (merge case-data { status: case-status-active })
      )
      true
    )

    (ok true)
  )
)

;; Record verdict for a case
(define-public (record-verdict (case-id uint) (verdict (string-ascii 200)) (jury-votes uint))
  (let
    ((case-data (unwrap! (map-get? cases { case-id: case-id }) err-not-found)))

    (asserts! (is-eq tx-sender (get judge case-data)) err-unauthorized)
    (asserts! (is-eq (get status case-data) case-status-active) err-invalid-status)
    (asserts! (<= jury-votes (get jury-size case-data)) err-invalid-status)

    ;; Record the verdict
    (map-set verdicts
      { case-id: case-id }
      {
        verdict: verdict,
        jury-votes: jury-votes,
        recorded-block: block-height,
        recorded-by: tx-sender
      }
    )

    ;; Close the case
    (map-set cases
      { case-id: case-id }
      (merge case-data {
        status: case-status-closed,
        closed-block: (some block-height)
      })
    )

    ;; Release jurors
    (release-case-jurors case-id)

    (ok true)
  )
)

;; Dismiss juror from active duty
(define-public (dismiss-juror (juror-id uint))
  (let
    ((juror-data (unwrap! (map-get? jurors { juror-id: juror-id }) err-not-found)))

    (asserts! (is-eq tx-sender contract-owner) err-owner-only)

    (map-set jurors
      { juror-id: juror-id }
      (merge juror-data {
        status: jury-status-dismissed,
        assigned-case: none
      })
    )

    (ok true)
  )
)

;; read only functions

;; Get juror information
(define-read-only (get-juror (juror-id uint))
  (map-get? jurors { juror-id: juror-id })
)

;; Get juror ID by principal
(define-read-only (get-juror-id (principal principal))
  (map-get? principal-to-juror { principal: principal })
)

;; Get case information
(define-read-only (get-case (case-id uint))
  (map-get? cases { case-id: case-id })
)

;; Get case verdict
(define-read-only (get-verdict (case-id uint))
  (map-get? verdicts { case-id: case-id })
)

;; Check if juror is assigned to case
(define-read-only (is-juror-assigned-to-case (case-id uint) (juror-id uint))
  (is-some (map-get? case-jury { case-id: case-id, juror-id: juror-id }))
)

;; Get current case ID counter
(define-read-only (get-next-case-id)
  (var-get next-case-id)
)

;; Get current juror ID counter
(define-read-only (get-next-juror-id)
  (var-get next-juror-id)
)

;; private functions

;; Count jurors assigned to a case
(define-private (get-case-jury-count (case-id uint))
  (fold count-case-jurors (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12) u0)
)

;; Helper function for counting case jurors
(define-private (count-case-jurors (juror-id uint) (count uint))
  (if (is-some (map-get? case-jury { case-id: u1, juror-id: juror-id }))
    (+ count u1)
    count
  )
)

;; Release all jurors from a case
(define-private (release-case-jurors (case-id uint))
  (fold release-juror (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12) true)
)

;; Helper function to release individual juror
(define-private (release-juror (juror-id uint) (success bool))
  (match (map-get? jurors { juror-id: juror-id })
    juror-data
    (if (is-eq (get status juror-data) jury-status-assigned)
      (begin
        (map-set jurors
          { juror-id: juror-id }
          (merge juror-data {
            status: jury-status-available,
            assigned-case: none
          })
        )
        success
      )
      success
    )
    success
  )
)
