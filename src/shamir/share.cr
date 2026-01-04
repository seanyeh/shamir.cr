module Shamir
  # Represents a single share in Shamir's Secret Sharing scheme
  # - x: share index (1-255)
  # - y: array of bytes, one for each byte of the secret
  #
  # Each share holds one y-value per byte position in the original secret
  struct Share
    getter x : UInt8
    getter y : Bytes

    def initialize(@x : UInt8, @y : Bytes)
    end

    # Convert share to hex string for storage/transmission
    # Format: "01:a3f2e5d4..." (x-coordinate:y-values in hex)
    #
    # Example:
    #   Share with x=1, y=[0xa3, 0xf2, 0xe5] => "01:a3f2e5"
    def to_hex : String
      "#{x.to_s(16).rjust(2, '0')}:#{y.hexstring}"
    end

    # Deserialize share from hex string
    # Format: "01:a3f2e5d4..." (x-coordinate:y-values in hex)
    def self.from_hex(hex : String) : Share
      parts = hex.split(":")
      raise ArgumentError.new("Invalid hex format") if parts.size != 2

      x = parts[0].to_u8(16)
      y = parts[1].hexbytes
      Share.new(x, y)
    end
  end
end
