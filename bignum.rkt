#lang racket
(require racket/fixnum)
(provide adigits
         @@bignum?
         @@bignum.negative?
         @@bignum.adigit-length
         @@bignum.mdigit-length
         @@fixnum->bignum
         @@bignum.make
         @@bignum.adigit-add!
         @@bignum.adigit-sub!
         @@bignum.adigit-inc!
         @@bignum.adigit-dec!
         @@bignum.adigit-shrink!
         @@bignum.adigit-zero?
         @@bignum.adigit-negative?
         @@bignum.adigit-ones?
         @@bignum.mdigit-ref
         @@bignum.fdigit-width
         @@bignum.mdigit-width
         @@bignum.adigit-width)

#|
Bignum Representation
adigit := value between 0 and 2 ^ 64 - 1
mdigit := value between 0 and 2 ^ 16 - 1
fdigit := value between 0 and 2 ^ 8 - 1
Probably the representation of bignums uses 64 bit values for adigits.
As a result mdigits come in multiples of 4
The representation is a normal two's complement number
Our represention is a vector of adigits, represented a racket number
|#

(struct bignum (adigits) #:mutable #:transparent)
(define-syntax-rule (adigits x) (bignum-adigits x))

(define @@bignum? bignum?)

(define (@@bignum.negative? x)
  (not (zero? (bitwise-and most-significant-adigit-bit
                           (vector-ref (adigits x) (- (vector-length (adigits x)) 1))))))
(define (@@bignum.adigit-length x) (vector-length (adigits x)))
(define (@@bignum.mdigit-length x) (* (@@bignum.adigit-length (adigits x)) mdigits-in-adigit))
(define (@@bignum.adigit-< x y i)
  (< (vector-ref (adigits x) i) (vector-ref (adigits y) i)))
(define (@@fixnum->bignum x) (bignum (vector (modulo (+ x adigit-modulus) adigit-modulus))))
(define (@@bignum.make k x complement?)
  (define y (make-vector k 0))
  (for ((adigit (in-vector (adigits x)))
        (i (in-range k)))
    (vector-set! y i adigit))
  (when complement?
    (for ((i (in-range k)))
      (vector-set! y i (bitwise-xor adigit-ones (vector-ref y i)))))
  (bignum y))
(define (@@bignum.adigit-add! x i y j carry)
  (define sum (+ (vector-ref (adigits x) i) (vector-ref (adigits y) j) carry))
  (vector-set! (adigits x) i (modulo sum adigit-modulus))
  (quotient sum adigit-modulus))
(define (@@bignum.adigit-sub! x i y j carry)
  (define diff (- (vector-ref (adigits x) i) (vector-ref (adigits y) j) carry))
  (vector-set! (adigits x) i (modulo (+ diff adigit-modulus) adigit-modulus))
  (if (< diff 0) 1 0))
(define (@@bignum.adigit-inc! x i)
  (define sum (add1 (vector-ref (adigits x) i)))
  (vector-set! (adigits x) i (modulo adigit-modulus))
  (quotient sum adigit-modulus))
(define (@@bignum.adigit-dec! x i)
  (define diff (sub1 (vector-ref (adigits x) i)))
  (vector-set! (adigits x) i (modulo (+ diff adigit-modulus) adigit-modulus))
  (if (< diff 0) 1 0))
(define (@@bignum.adigit-shrink! x n)
  (set-bignum-adigits! x (vector-take (adigits x) n)))
(define (@@bignum.adigit-zero? x i)
  (zero? (vector-ref (adigits x) i)))
(define (@@bignum.adigit-ones? x i)
  (= (vector-ref (adigits x) i) adigit-ones))
(define (@@bignum.adigit-negative? x i)
  (not (zero? (bitwise-and most-significant-adigit-bit (vector-ref (adigits x) i)))))
(define (@@bignum.mdigit-ref x i)
  (define adigit-index (quotient i mdigits-in-adigit))
  (define mdigit-subindex (modulo i mdigits-in-adigit))
  (modulo (quotient (vector-ref (adigits x) adigit-index) (expt mdigit-modulus mdigit-subindex))
          mdigit-modulus))
(define @@bignum.fdigit-width 8)
(define @@bignum.mdigit-width 16)
(define @@bignum.adigit-width 64)

(define most-significant-adigit-bit (expt 2 @@bignum.adigit-width))
(define adigit-modulus (expt 2 @@bignum.adigit-width))
(define mdigit-modulus (expt 2 @@bignum.mdigit-width))
(define adigit-ones (- adigit-modulus 1))
(define mdigits-in-adigit (/ @@bignum.adigit-width @@bignum.mdigit-width))
  