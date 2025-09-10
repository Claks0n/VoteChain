;; VoteChain - Community governance and proposal validation platform
;; Members earn tokens based on proposal verification and participation ratings

;; Error codes
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_INPUT (err u103))
(define-constant ERR_ALREADY_VERIFIED (err u104))
(define-constant ERR_ALREADY_RATED (err u105))
(define-constant ERR_SELF_RATING (err u106))
(define-constant ERR_EMPTY_STRING (err u107))
(define-constant ERR_INVALID_RATING (err u108))
(define-constant ERR_INVALID_PROPOSAL_ID (err u109))
(define-constant ERR_EMPTY_HASH (err u110))

;; Constants
(define-constant MAX_RATING u5)
(define-constant SUPPORT_REWARD u10)
(define-constant ENGAGEMENT_REWARD u20)
(define-constant APPROVAL_REWARD u50)

;; Data maps
(define-map community-members
  { member-id: principal }
  { name: (string-ascii 50), member-type: (string-ascii 20), reputation: uint, tokens: uint, approved: bool }
)

(define-map governance-proposals
  { proposal-id: uint }
  { 
    proposer: principal, 
    description: (string-ascii 500), 
    proposal-hash: (buff 32),
    timestamp: uint, 
    verified: bool,
    endorsement-count: uint,
    support-count: uint,
    engagement-rating: uint,
    rating-count: uint
  }
)

(define-map proposal-endorsements
  { proposal-id: uint, endorser: principal }
  { endorsed: bool }
)

(define-map proposal-support
  { proposal-id: uint, supporter: principal }
  { support-level: uint, support-date: uint }
)

(define-map engagement-ratings
  { proposal-id: uint, evaluator: principal }
  { rating: uint }
)

;; Variables
(define-data-var next-proposal-id uint u1)
(define-data-var action-counter uint u0)

;; Helper functions
(define-private (is-valid-proposal-id (proposal-id uint))
  (< proposal-id (var-get next-proposal-id))
)

;; Member functions
(define-public (register-member (name (string-ascii 50)) (member-type (string-ascii 20)))
  (let ((caller tx-sender))
    (asserts! (> (len name) u0) ERR_EMPTY_STRING)
    (asserts! (or (is-eq member-type "proposer") (is-eq member-type "endorser") (is-eq member-type "supporter")) ERR_INVALID_INPUT)
    (asserts! (is-none (map-get? community-members {member-id: caller})) ERR_ALREADY_EXISTS)
    (ok (map-set community-members 
      {member-id: caller} 
      {name: name, member-type: member-type, reputation: u0, tokens: u100, approved: false}))
  )
)

(define-public (update-member (name (string-ascii 50)) (member-type (string-ascii 20)))
  (let ((caller tx-sender))
    (asserts! (> (len name) u0) ERR_EMPTY_STRING)
    (asserts! (or (is-eq member-type "proposer") (is-eq member-type "endorser") (is-eq member-type "supporter")) ERR_INVALID_INPUT)
    (asserts! (is-some (map-get? community-members {member-id: caller})) ERR_NOT_FOUND)
    (ok (map-set community-members 
      {member-id: caller} 
      (merge (unwrap! (map-get? community-members {member-id: caller}) ERR_NOT_FOUND)
             {name: name, member-type: member-type})))
  )
)

;; Proposal functions
(define-public (submit-proposal (description (string-ascii 500)) (proposal-hash (buff 32)))
  (let ((caller tx-sender)
        (proposal-id (var-get next-proposal-id)))
    (asserts! (> (len description) u0) ERR_EMPTY_STRING)
    (asserts! (> (len proposal-hash) u0) ERR_EMPTY_HASH)
    (asserts! (is-some (map-get? community-members {member-id: caller})) ERR_NOT_FOUND)
    (var-set action-counter (+ (var-get action-counter) u1))
    
    (map-set governance-proposals 
      {proposal-id: proposal-id} 
      { 
        proposer: caller, 
        description: description, 
        proposal-hash: proposal-hash,
        timestamp: (var-get action-counter), 
        verified: false,
        endorsement-count: u0,
        support-count: u0,
        engagement-rating: u0,
        rating-count: u0
      })
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

(define-public (endorse-proposal (proposal-id uint))
  (let ((caller tx-sender))
    (asserts! (is-valid-proposal-id proposal-id) ERR_INVALID_PROPOSAL_ID)
    (asserts! (is-some (map-get? community-members {member-id: caller})) ERR_NOT_FOUND)
    (asserts! (is-some (map-get? governance-proposals {proposal-id: proposal-id})) ERR_NOT_FOUND)
    
    (let ((proposal (unwrap! (map-get? governance-proposals {proposal-id: proposal-id}) ERR_NOT_FOUND)))
      (asserts! (not (is-eq caller (get proposer proposal))) ERR_SELF_RATING)
      (asserts! (is-none (map-get? proposal-endorsements {proposal-id: proposal-id, endorser: caller})) ERR_ALREADY_VERIFIED)
      
      (map-set proposal-endorsements 
        {proposal-id: proposal-id, endorser: caller} 
        {endorsed: true})
      
      (let ((new-endorsement-count (+ (get endorsement-count proposal) u1))
            (proposal-proposer (unwrap! (map-get? community-members {member-id: (get proposer proposal)}) ERR_NOT_FOUND))
            (endorser-member (unwrap! (map-get? community-members {member-id: caller}) ERR_NOT_FOUND)))
        
        (map-set governance-proposals 
          {proposal-id: proposal-id} 
          (merge proposal {
            endorsement-count: new-endorsement-count,
            verified: (>= new-endorsement-count u3)
          }))
        
        (map-set community-members 
          {member-id: caller} 
          (merge endorser-member {
            tokens: (+ (get tokens endorser-member) u5),
            reputation: (+ (get reputation endorser-member) u1)
          }))
        
        (if (and (>= new-endorsement-count u3) (not (get verified proposal)))
          (map-set community-members 
            {member-id: (get proposer proposal)} 
            (merge proposal-proposer {
              tokens: (+ (get tokens proposal-proposer) APPROVAL_REWARD),
              reputation: (+ (get reputation proposal-proposer) u10),
              approved: true
            }))
          true)
        
        (ok new-endorsement-count)
      )
    )
  )
)

(define-public (support-proposal (proposal-id uint) (support-level uint))
  (let ((caller tx-sender))
    (asserts! (is-valid-proposal-id proposal-id) ERR_INVALID_PROPOSAL_ID)
    (asserts! (> support-level u0) ERR_INVALID_INPUT)
    (asserts! (is-some (map-get? community-members {member-id: caller})) ERR_NOT_FOUND)
    (asserts! (is-some (map-get? governance-proposals {proposal-id: proposal-id})) ERR_NOT_FOUND)
    
    (let ((proposal (unwrap! (map-get? governance-proposals {proposal-id: proposal-id}) ERR_NOT_FOUND)))
      (asserts! (get verified proposal) ERR_UNAUTHORIZED)
      
      (map-set proposal-support 
        {proposal-id: proposal-id, supporter: caller} 
        {support-level: support-level, support-date: (var-get action-counter)})
      
      (let ((new-support-count (+ (get support-count proposal) support-level))
            (proposal-proposer (unwrap! (map-get? community-members {member-id: (get proposer proposal)}) ERR_NOT_FOUND)))
        
        (map-set governance-proposals 
          {proposal-id: proposal-id} 
          (merge proposal {support-count: new-support-count}))
        
        (map-set community-members 
          {member-id: (get proposer proposal)} 
          (merge proposal-proposer {
            tokens: (+ (get tokens proposal-proposer) (* SUPPORT_REWARD support-level))
          }))
        
        (ok new-support-count)
      )
    )
  )
)

(define-public (rate-proposal-engagement (proposal-id uint) (rating uint))
  (let ((caller tx-sender))
    (asserts! (is-valid-proposal-id proposal-id) ERR_INVALID_PROPOSAL_ID)
    (asserts! (and (>= rating u1) (<= rating MAX_RATING)) ERR_INVALID_RATING)
    (asserts! (is-some (map-get? community-members {member-id: caller})) ERR_NOT_FOUND)
    (asserts! (is-some (map-get? governance-proposals {proposal-id: proposal-id})) ERR_NOT_FOUND)
    
    (let ((proposal (unwrap! (map-get? governance-proposals {proposal-id: proposal-id}) ERR_NOT_FOUND)))
      (asserts! (not (is-eq caller (get proposer proposal))) ERR_SELF_RATING)
      (asserts! (is-none (map-get? engagement-ratings {proposal-id: proposal-id, evaluator: caller})) ERR_ALREADY_RATED)
      
      (map-set engagement-ratings 
        {proposal-id: proposal-id, evaluator: caller} 
        {rating: rating})
      
      (let ((current-total-rating (* (get engagement-rating proposal) (get rating-count proposal)))
            (new-rating-count (+ (get rating-count proposal) u1))
            (new-total-rating (+ current-total-rating rating))
            (new-average-rating (/ new-total-rating new-rating-count))
            (proposal-proposer (unwrap! (map-get? community-members {member-id: (get proposer proposal)}) ERR_NOT_FOUND))
            (evaluator-member (unwrap! (map-get? community-members {member-id: caller}) ERR_NOT_FOUND)))
        
        (map-set governance-proposals 
          {proposal-id: proposal-id} 
          (merge proposal {
            engagement-rating: new-average-rating,
            rating-count: new-rating-count
          }))
        
        (map-set community-members 
          {member-id: caller} 
          (merge evaluator-member {
            tokens: (+ (get tokens evaluator-member) u2),
            reputation: (+ (get reputation evaluator-member) u1)
          }))
        
        (if (>= rating u4)
          (map-set community-members 
            {member-id: (get proposer proposal)} 
            (merge proposal-proposer {
              tokens: (+ (get tokens proposal-proposer) ENGAGEMENT_REWARD),
              reputation: (+ (get reputation proposal-proposer) u5)
            }))
          true)
        
        (ok new-average-rating)
      )
    )
  )
)

;; Read-only functions
(define-read-only (get-member-info (member-id principal))
  (map-get? community-members {member-id: member-id})
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? governance-proposals {proposal-id: proposal-id})
)

(define-read-only (get-proposal-endorsement (proposal-id uint) (endorser principal))
  (map-get? proposal-endorsements {proposal-id: proposal-id, endorser: endorser})
)

(define-read-only (get-proposal-support (proposal-id uint) (supporter principal))
  (map-get? proposal-support {proposal-id: proposal-id, supporter: supporter})
)

(define-read-only (get-engagement-rating (proposal-id uint) (evaluator principal))
  (map-get? engagement-ratings {proposal-id: proposal-id, evaluator: evaluator})
)

(define-read-only (get-total-proposals)
  (- (var-get next-proposal-id) u1)
)
