module Shamir
  # Galois Field GF(2^8) arithmetic for efficient secret sharing
  #
  # In GF(256):
  # - Addition is XOR (a + b = a ^ b)
  # - Multiplication uses polynomial arithmetic modulo an irreducible polynomial
  # - Every non-zero element can be represented as generator^i for some i
  #
  # We use logarithm tables for fast multiplication/division:
  #   log_table[g^i] = i
  #   exp_table[i] = g^i
  #
  # Then: multiply(a,b) = exp[log[a] + log[b]]
  module GF256
    # Irreducible polynomial for GF(256): x^8 + x^4 + x^3 + x + 1
    # In binary: 0b100011011 = 0x11b
    # This is the standard polynomial used in AES and other crypto systems
    POLYNOMIAL = 0x11b

    # Generator element (primitive element that generates all non-zero elements)
    # 0x03 is a common choice (could also use 0x02)
    GENERATOR = 0x03_u8

    # Lookup tables for fast arithmetic (initialized lazily)
    @@exp_table : Array(UInt8)? = nil
    @@log_table : Array(UInt8)? = nil

    # Generate the logarithm and exponent tables
    #
    # This builds two 256-element tables:
    # - exp_table[i] = GENERATOR^i (in GF(256))
    # - log_table[GENERATOR^i] = i
    #
    # These tables let us convert multiplication to addition in the exponent space
    private def self.generate_tables
      exp = Array(UInt8).new(256, 0_u8)
      log = Array(UInt8).new(256, 0_u8)

      # Start with generator^0 = 1
      value = 1_u8

      255.times do |i|
        exp[i] = value
        log[value] = i.to_u8

        # Multiply by generator (polynomial multiplication in GF(256))
        # This is the core operation: value = value * GENERATOR mod POLYNOMIAL
        value = gf_multiply_byte(value, GENERATOR)
      end

      # Handle wraparound: g^255 = g^0 = 1 (the multiplicative group has order 255)
      exp[255] = exp[0]

      @@exp_table = exp
      @@log_table = log
    end

    # Low-level polynomial multiplication of a single byte by GENERATOR
    #
    # This performs actual polynomial multiplication:
    # 1. Multiply by GENERATOR (shift and XOR)
    # 2. Reduce modulo POLYNOMIAL if result >= 256
    #
    # This is only used during table generation - after that we use tables
    private def self.gf_multiply_byte(a : UInt8, b : UInt8) : UInt8
      result = 0_u8
      a_val = a.to_u16
      b_val = b.to_u16

      8.times do
        # If lowest bit of b is set, add a to result (XOR in GF(2))
        result ^= a_val.to_u8 if (b_val & 1) != 0

        # Check if a will overflow when shifted (high bit is set)
        high_bit_set = (a_val & 0x80) != 0

        # Multiply a by x (shift left)
        a_val <<= 1

        # If we overflowed, reduce modulo POLYNOMIAL
        # XOR with POLYNOMIAL (without the x^8 term, so 0x1b instead of 0x11b)
        a_val ^= POLYNOMIAL if high_bit_set

        # Divide b by x (shift right) for next iteration
        b_val >>= 1
      end

      result
    end

    # Ensure tables are initialized
    private def self.ensure_tables
      generate_tables if @@exp_table.nil?
    end

    # Add two elements in GF(256)
    # In GF(2^n), addition is simply XOR
    def self.add(a : UInt8, b : UInt8) : UInt8
      a ^ b
    end

    # Subtract two elements in GF(256)
    # In GF(2^n), subtraction is the same as addition (both are XOR)
    def self.sub(a : UInt8, b : UInt8) : UInt8
      a ^ b
    end

    # Multiply two elements in GF(256)
    #
    # Uses logarithm tables for efficiency:
    #   a * b = g^log[a] * g^log[b] = g^(log[a] + log[b])
    #
    # Special case: if either operand is 0, result is 0
    def self.multiply(a : UInt8, b : UInt8) : UInt8
      return 0_u8 if a == 0 || b == 0

      ensure_tables
      exp_table = @@exp_table.not_nil!
      log_table = @@log_table.not_nil!

      # log[a] + log[b], with wraparound at 255
      log_sum = (log_table[a].to_u16 + log_table[b].to_u16) % 255
      exp_table[log_sum]
    end

    # Divide two elements in GF(256)
    #
    # Uses logarithm tables:
    #   a / b = g^log[a] / g^log[b] = g^(log[a] - log[b])
    #
    # Raises if b is 0 (division by zero)
    def self.divide(a : UInt8, b : UInt8) : UInt8
      raise ArgumentError.new("Division by zero in GF(256)") if b == 0
      return 0_u8 if a == 0

      ensure_tables
      exp_table = @@exp_table.not_nil!
      log_table = @@log_table.not_nil!

      # log[a] - log[b], with wraparound at 255
      log_diff = (255 + log_table[a].to_u16 - log_table[b].to_u16) % 255
      exp_table[log_diff]
    end

    # Compute multiplicative inverse of a in GF(256)
    # inverse(a) = a^254 = 1/a
    # Can also compute as: exp[255 - log[a]]
    def self.inverse(a : UInt8) : UInt8
      raise ArgumentError.new("No inverse for 0 in GF(256)") if a == 0

      ensure_tables
      exp_table = @@exp_table.not_nil!
      log_table = @@log_table.not_nil!

      exp_table[255 - log_table[a]]
    end
  end
end
