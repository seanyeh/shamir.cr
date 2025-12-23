module Shamir
  module Math
    # A large prime number for finite field operations
    # Using Mersenne prime 2^521 - 1 (supports secrets up to ~65 bytes)
    PRIME = BigInt.new(2)**521 - 1

    # Generate a random polynomial of given degree with secret as constant term
    # Returns array of coefficients [secret, a1, a2, ..., a_degree]
    def self.generate_polynomial(secret : BigInt, degree : Int32) : Array(BigInt)
      coefficients = [secret]

      degree.times do
        coefficients << Random::Secure.rand(PRIME)
      end

      coefficients
    end

    # Evaluate polynomial at given x value in finite field using Horner's Method
    def self.evaluate_polynomial(coefficients : Array(BigInt), x : UInt8) : BigInt
      result = BigInt.new(0)
      x_big = BigInt.new(x)

      coefficients.reverse.each do |c|
        result = (c + x_big * result) % PRIME
      end

      result
    end

    # Reconstruct secret using Lagrange interpolation
    # Returns the value of the polynomial at x=0 (the secret)
    def self.lagrange_interpolate(shares : Array(Share)) : BigInt
      secret = BigInt.new(0)
      shares.each_with_index do |_, i|
        others = shares.dup
        current_share = others.delete_at(i)

        numerator = prod(others.map { |other_share| (BigInt.new(0) - other_share.x) % PRIME })
        denominator = prod(others.map { |other_share| (BigInt.new(current_share.x) - other_share.x) % PRIME })

        lagrange_basis = (numerator * mod_inverse(denominator, PRIME)) % PRIME

        secret = (secret + current_share.y * lagrange_basis) % PRIME
      end

      secret
    end

    # Modular multiplicative inverse using Extended Euclidean Algorithm
    def self.mod_inverse(a : BigInt, b : BigInt) : BigInt
      old_r, r = a, b
      old_s, s = BigInt.new(1), BigInt.new(0)
      old_t, t = BigInt.new(0), BigInt.new(1)

      while r != 0
        quotient = old_r // r
        old_r, r = r, old_r - quotient * r
        old_s, s = s, old_s - quotient * s
        old_t, t = t, old_t - quotient * t
      end

      old_s % b
    end

    # Compute product of array values in finite field
    private def self.prod(vals)
      result = BigInt.new(1)
      vals.each do |x|
        result = (result * x) % PRIME
      end
      result
    end
  end
end
