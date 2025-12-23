require "big"
require "./shamir/share"
require "./shamir/math"

module Shamir
  VERSION = "0.1.0"

  # Split a secret into n shares, requiring k shares to reconstruct
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
  def self.split(secret : String | Bytes, n : Int32, k : Int32) : Array(Share)
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

    # With 2^521 - 1 prime, max secret length is 65 bytes (256^65 < 2^521)
    if bytes.size > 65
      raise ArgumentError.new("secret too long (max 65 bytes, got #{bytes.size})")
    end

    secret_int = BigInt.new(bytes.hexstring, base: 16)

    coefficients = Math.generate_polynomial(secret_int, k - 1)

    (1..n).map do |x|
      y = Math.evaluate_polynomial(coefficients, x.to_u8)
      Share.new(x.to_u8, y)
    end
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
  def self.combine(shares : Array(Share)) : Bytes
    if shares.size < 2
      raise ArgumentError.new("need at least 2 shares to reconstruct")
    end

    # Use Lagrange interpolation to find polynomial value at x=0
    secret_int = Math.lagrange_interpolate(shares)

    hex = secret_int.to_s(16)

    # Pad if odd length
    hex = "0#{hex}" if hex.size.odd?

    hex.hexbytes
  end
end
