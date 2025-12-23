require "./spec_helper"

describe Shamir do
  describe ".split" do
    it "creates the correct number of shares" do
      shares = Shamir.split("test secret", n: 5, k: 3)
      shares.size.should eq(5)
    end

    it "validates that k <= n" do
      expect_raises(ArgumentError) do
        Shamir.split("test", n: 3, k: 5)
      end
    end
  end

  describe ".combine" do
    it "reconstructs the original secret with exactly k shares" do
      secret = "my secret message"
      shares = Shamir.split(secret, n: 5, k: 3)
      reconstructed = Shamir.combine(shares[0..2])
      String.new(reconstructed).should eq(secret)
    end

    it "reconstructs the original secret with more than k shares" do
      secret = "my secret message"
      shares = Shamir.split(secret, n: 5, k: 3)
      reconstructed = Shamir.combine(shares[0..3])
      String.new(reconstructed).should eq(secret)
    end

    it "works with different subsets of shares" do
      secret = "test"
      shares = Shamir.split(secret, n: 5, k: 3)
      String.new(Shamir.combine([shares[0], shares[2], shares[4]])).should eq(secret)
      String.new(Shamir.combine([shares[1], shares[2], shares[3]])).should eq(secret)
    end
  end

  describe Shamir::Math do
    describe ".mod_inverse" do
      it "calculates modular inverse correctly" do
        result = Shamir::Math.mod_inverse(BigInt.new(3), BigInt.new(11))
        ((result * 3) % 11).should eq(1)
      end
    end

    describe ".evaluate_polynomial" do
      it "evaluates polynomial correctly" do
        coefficients = [BigInt.new(5), BigInt.new(2), BigInt.new(3)]
        result = Shamir::Math.evaluate_polynomial(coefficients, 2_u8)
        # f(2) = 5 + 2*2 + 3*2^2 = 5 + 4 + 12 = 21
        result.should eq(21)
      end
    end
  end

  describe Shamir::Share do
    describe "#to_hex" do
      it "converts share to hex string with correct format" do
        share = Shamir::Share.new(1_u8, BigInt.new(12345))
        hex = share.to_hex
        hex.should eq("01:3039")
      end

      it "pads x-coordinate to 2 digits" do
        share = Shamir::Share.new(15_u8, BigInt.new(255))
        hex = share.to_hex
        hex.should eq("0f:ff")
      end

      it "handles large y values" do
        share = Shamir::Share.new(1_u8, BigInt.new("123456789012345678901234567890"))
        hex = share.to_hex
        hex.should match(/^01:[0-9a-f]+$/)
      end
    end

    describe ".from_hex" do
      it "deserializes hex string correctly" do
        hex = "01:3039"
        share = Shamir::Share.from_hex(hex)
        share.x.should eq(1)
        share.y.should eq(12345)
      end

      it "handles large values" do
        hex = "0f:18ee90ff6c373e0ee4e3f0ad2"
        share = Shamir::Share.from_hex(hex)
        share.x.should eq(15)
        share.y.should eq(BigInt.new("123456789012345678901234567890"))
      end

      it "raises error on invalid format" do
        expect_raises(ArgumentError, "Invalid hex format") do
          Shamir::Share.from_hex("invalid")
        end
      end

      it "round-trips correctly" do
        original = Shamir::Share.new(42_u8, BigInt.new("999888777666555444333222111"))
        hex = original.to_hex
        restored = Shamir::Share.from_hex(hex)
        restored.x.should eq(original.x)
        restored.y.should eq(original.y)
      end
    end

    describe "end-to-end with file storage" do
      it "can save and load shares from hex strings" do
        secret = "test secret"
        shares = Shamir.split(secret, n: 5, k: 3)

        # Simulate saving to files (just convert to hex)
        hex_shares = shares.map(&.to_hex)

        # Simulate loading from files
        loaded_shares = hex_shares[0..2].map { |hex| Shamir::Share.from_hex(hex) }

        # Reconstruct
        reconstructed = Shamir.combine(loaded_shares)
        String.new(reconstructed).should eq(secret)
      end
    end
  end
end
