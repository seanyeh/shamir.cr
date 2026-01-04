require "./shamir/share"
require "./shamir/gf256"
require "./shamir/math_gf256"

module Shamir
  VERSION = "0.3.0"

  # Split a secret into n shares, requiring k shares to reconstruct
  #
  # Uses GF(256) arithmetic - processes secret byte-by-byte with no size limit.
  #
  # Parameters:
  # - secret: The secret to split (String or Bytes)
  # - n: Total number of shares to create (must be >= k)
  # - k: Minimum number of shares required to reconstruct (threshold)
  #
  # Returns: Array of Share objects
  #
  # Example:
  #   shares = Shamir.split("my secret", n: 5, k: 3)
  #
  # Algorithm:
  #   For each byte position i in the secret:
  #     1. Create polynomial with secret[i] as constant term
  #     2. Evaluate at x = 1, 2, ..., n
  #     3. Store results as share[x].y[i]
  def self.split(secret : String | Bytes, n : Int32, k : Int32) : Array(Share)
    # Validation
    if k > n
      raise ArgumentError.new("minimum number must be <= total number of shares")
    end

    if k < 2
      raise ArgumentError.new("minimum number of shares must be >= 2")
    end

    if n > 255
      raise ArgumentError.new("total number of shares must be <= 255")
    end

    bytes = secret.is_a?(String) ? secret.to_slice : secret

    if bytes.size == 0
      raise ArgumentError.new("secret cannot be empty")
    end

    # Initialize n shares, each will hold bytes.size y-values
    shares = Array.new(n) { |i| {x: (i + 1).to_u8, y: Bytes.new(bytes.size)} }

    # Process each byte of the secret independently
    bytes.each_with_index do |secret_byte, byte_index|
      # Generate a random polynomial for this byte position
      # Polynomial: f(x) = secret_byte + a1*x + a2*x^2 + ... + a(k-1)*x^(k-1)
      coefficients = MathGF256.generate_polynomial(secret_byte, k - 1)

      # Evaluate polynomial at x = 1, 2, ..., n
      shares.each do |share|
        y_value = MathGF256.evaluate_polynomial(coefficients, share[:x])
        share[:y][byte_index] = y_value
      end
    end

    # Convert to Share objects
    shares.map { |s| Share.new(s[:x], s[:y]) }
  end

  # Reconstruct the secret from k or more shares
  #
  # Parameters:
  # - shares: Array of Share objects (must have at least k shares)
  #
  # Returns: The original secret as Bytes
  #
  # Example:
  #   secret = Shamir.combine(shares[0..2])
  #
  # Algorithm:
  #   For each byte position i:
  #     1. Extract points (x, y[i]) from all shares
  #     2. Use Lagrange interpolation to find f(0) = secret[i]
  def self.combine(shares : Array(Share)) : Bytes
    if shares.size < 2
      raise ArgumentError.new("need at least 2 shares to reconstruct")
    end

    # All shares must have the same y length (same secret size)
    secret_size = shares[0].y.size
    shares.each do |share|
      if share.y.size != secret_size
        raise ArgumentError.new("all shares must have the same length")
      end
    end

    # Reconstruct each byte of the secret independently
    secret_bytes = Bytes.new(secret_size)

    secret_size.times do |byte_index|
      # Extract (x, y[byte_index]) points from all shares
      points = shares.map { |share| {share.x, share.y[byte_index]} }

      # Use Lagrange interpolation to find f(0) = secret byte
      secret_bytes[byte_index] = MathGF256.lagrange_interpolate(points)
    end

    secret_bytes
  end
end
