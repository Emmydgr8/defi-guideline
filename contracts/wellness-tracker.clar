;; wellness-tracker
;; 
;; A decentralized DeFi guideline contract for tracking and incentivizing personal wellness metrics.
;; This contract provides a framework for users to log, track, and improve their health and well-being
;; through a gamified, blockchain-based wellness tracking system.

;; Error Definitions
(define-constant ERR-UNAUTHORIZED (err u1001))
(define-constant ERR-INVALID-INPUT (err u1002))
(define-constant ERR-INPUT-OUT-OF-BOUNDS (err u1003))
(define-constant ERR-RECORD-NOT-FOUND (err u1004))
(define-constant ERR-METRIC-LIMIT-EXCEEDED (err u1005))
(define-constant ERR-PROFILE-MISSING (err u1006))
(define-constant ERR-DUPLICATE-ACHIEVEMENT (err u1007))
(define-constant ERR-IMMUTABLE-RECORD (err u1008))

;; User Profile Management
(define-map user-profiles
  { user: principal }
  {
    registered-at: uint,
    wellness-index: uint,
    consecutive-days: uint
  }
)

;; Daily Health Metrics Tracking
(define-map health-metrics
  { user: principal, recorded-date: uint }
  {
    rest-duration: uint,
    hydration-volume: uint,
    mindfulness-time: uint,
    timestamp: uint
  }
)

;; Personal Health Goals
(define-map health-objectives
  { user: principal }
  {
    rest-target: uint,
    hydration-target: uint,
    mindfulness-target: uint,
    last-updated: uint
  }
)

;; Achievement Tracking
(define-map user-achievements
  { user: principal, achievement-id: uint }
  {
    earned-timestamp: uint,
    achievement-title: (string-utf8 50)
  }
)

;; Achievement Definitions
(define-map achievement-catalog
  { achievement-id: uint }
  {
    title: (string-utf8 50),
    description: (string-utf8 255),
    category: (string-utf8 20),
    milestone: uint
  }
)

;; Private Helper Functions

;; Validate input metric ranges
(define-private (validate-metric-range (metric-type (string-utf8 20)) (value uint))
  (if (is-eq metric-type u"rest-duration")
    (and (>= value u0) (<= value u24))
    (if (is-eq metric-type u"hydration-volume")
      (and (>= value u0) (<= value u10000))
      (if (is-eq metric-type u"mindfulness-time")
        (and (>= value u0) (<= value u1440))
        false
      )
    )
  )
)

;; Ensure user profile exists
(define-private (initialize-user-if-needed (user principal))
  (if (is-none (map-get? user-profiles { user: user }))
    (begin
      (map-set user-profiles
        { user: user }
        {
          registered-at: (unwrap-panic (get-block-info? time u0)),
          wellness-index: u0,
          consecutive-days: u0
        }
      )
      true
    )
    true
  )
)

;; Calculate holistic wellness index
(define-private (compute-wellness-score (user principal))
  (let (
    (user-data (unwrap! (map-get? user-profiles { user: user }) u0))
    (objectives (unwrap! (map-get? health-objectives { user: user }) u0))
    (current-timestamp (unwrap-panic (get-block-info? time u0)))
    (previous-day (- current-timestamp (* u60 u60 u24)))
    (daily-metrics (map-get? health-metrics { user: user, recorded-date: previous-day }))
  )
    (if (is-some daily-metrics)
      (let (
        (current-metrics (unwrap-panic daily-metrics))
        (rest-achievement-percent (if (> (get rest-target objectives) u0)
          (min (* u100 (/ (get rest-duration current-metrics) (get rest-target objectives))) u100)
          u0))
        (hydration-achievement-percent (if (> (get hydration-target objectives) u0)
          (min (* u100 (/ (get hydration-volume current-metrics) (get hydration-target objectives))) u100)
          u0))
        (mindfulness-achievement-percent (if (> (get mindfulness-target objectives) u0)
          (min (* u100 (/ (get mindfulness-time current-metrics) (get mindfulness-target objectives))) u100)
          u0))
        (aggregate-achievement-percent (/ (+ rest-achievement-percent hydration-achievement-percent mindfulness-achievement-percent) u3))
        (current-score (get wellness-index user-data))
        (updated-score (+ (/ current-score u10) (* (/ aggregate-achievement-percent u100) u90)))
      )
        (map-set user-profiles 
          { user: user }
          (merge user-data { wellness-index: updated-score })
        )
        updated-score
      )
      ;; No metrics recorded, slight score reduction
      (let (
        (current-score (get wellness-index user-data))
        (adjusted-score (if (> current-score u5) (- current-score u5) u0))
      )
        (map-set user-profiles 
          { user: user }
          (merge user-data { wellness-index: adjusted-score })
        )
        adjusted-score
      )
    )
  )
)

;; Issue achievement if not previously earned
(define-private (grant-achievement (user principal) (achievement-id uint) (achievement-name (string-utf8 50)) (timestamp uint))
  (let (
    (existing-achievement (map-get? user-achievements { user: user, achievement-id: achievement-id }))
  )
    (if (is-none existing-achievement)
      (begin
        (map-set user-achievements
          { user: user, achievement-id: achievement-id }
          { 
            earned-timestamp: timestamp,
            achievement-title: achievement-name
          }
        )
        (ok true)
      )
      (ok true) ;; Achievement already exists
    )
  )
)

;; Utility: Convert timestamp to standardized date
(define-private (normalize-date-from-timestamp (timestamp uint))
  (let (
    (seconds-per-day (* u60 u60 u24))
    (normalized-days (/ timestamp seconds-per-day))
  )
    (* normalized-days seconds-per-day)
  )
)