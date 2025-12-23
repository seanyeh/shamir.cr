module Shamir
  # Represents a single share in Shamir's Secret Sharing scheme
  # Each share is a point (x, y) on the polynomial
  struct Share
    getter x : UInt8
    getter y : BigInt

    def initialize(@x : UInt8, @y : BigInt)
    end

    # Convert share to hex string for storage/transmission
    # Format: "01:a3f2e5d4..." (x-coordinate:y-value in hex)
    def to_hex : String
      "#{x.to_s(16).rjust(2, '0')}:#{y.to_s(16)}"
    end

    # Deserialize share from hex string
    def self.from_hex(hex : String) : Share
      parts = hex.split(":")
      raise ArgumentError.new("Invalid hex format") if parts.size != 2

      x = parts[0].to_u8(16)
      y = BigInt.new(parts[1], 16)
      Share.new(x, y)
    end
  end
end
