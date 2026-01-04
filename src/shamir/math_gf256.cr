module Shamir
  module MathGF256
    # Generate a random polynomial of given degree with secret as constant term
    # Returns array of coefficients [secret, a1, a2, ..., a_degree]
    #
    # Unlike the BigInt version, this operates on a single byte in GF(256)
    def self.generate_polynomial(secret_byte : UInt8, degree : Int32) : Array(UInt8)
      coefficients = [secret_byte]

      # Generate random coefficients in GF(256)
      degree.times do
        # Random byte from 0-255
        coefficients << Random::Secure.random_bytes(1)[0]
      end

      coefficients
    end

    # Evaluate polynomial at given x value in GF(256) using Horner's Method
    #
    # For polynomial: f(x) = a0 + a1*x + a2*x^2 + ... + an*x^n
    # Horner's form: f(x) = a0 + x*(a1 + x*(a2 + x*(...)))
    #
    # This is more efficient than computing powers of x
    def self.evaluate_polynomial(coefficients : Array(UInt8), x : UInt8) : UInt8
      # Start from the highest degree coefficient
      result = 0_u8

      # Horner's method: iterate from highest to lowest degree
      coefficients.reverse.each do |coeff|
        # result = coeff + x * result (in GF(256))
        result = GF256.add(coeff, GF256.multiply(x, result))
      end

      result
    end

    # Reconstruct secret using Lagrange interpolation in GF(256)
    #
    # Given k points (x1,y1), (x2,y2), ..., (xk,yk), reconstruct f(0)
    # where f is the unique polynomial of degree < k passing through these points
    #
    # Lagrange formula: f(0) = Σ yi * Li(0)
    # where Li(x) = Π (x - xj) / (xi - xj) for j ≠ i
    def self.lagrange_interpolate(points : Array(Tuple(UInt8, UInt8))) : UInt8
      secret = 0_u8

      points.each_with_index do |point_i, i|
        xi, yi = point_i

        # Get all other points (excluding current point i)
        other_points = points.each.with_index.select { |_, j| j != i }.map(&.[0]).to_a

        # Compute Lagrange basis polynomial Li(0)
        # Numerator: Π (0 - xj) = Π xj  (since 0 - xj = xj in GF(256))
        numerator = prod(other_points.map { |xj, _| xj })

        # Denominator: Π (xi - xj)
        denominator = prod(other_points.map { |xj, _| GF256.sub(xi, xj) })

        # Lagrange basis: Li(0) = numerator / denominator
        lagrange_basis = GF256.divide(numerator, denominator)

        # Accumulate: secret += yi * Li(0)
        secret = GF256.add(secret, GF256.multiply(yi, lagrange_basis))
      end

      secret
    end

    # Compute product of array values in GF(256)
    # This is the GF(256) equivalent of multiplying all elements together
    private def self.prod(values : Array(UInt8)) : UInt8
      result = 1_u8
      values.each do |x|
        result = GF256.multiply(result, x)
      end
      result
    end
  end
end
