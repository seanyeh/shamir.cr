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

  describe Shamir::MathGF256 do
    describe ".evaluate_polynomial" do
      it "evaluates polynomial correctly in GF(256)" do
        # In GF(256): f(x) = 5 + 2*x (degree 1 polynomial)
        coefficients = [5_u8, 2_u8]
        result = Shamir::MathGF256.evaluate_polynomial(coefficients, 3_u8)
        # f(3) = 5 + 2*3 in GF(256) = 5 XOR (2 * 3)
        expected = Shamir::GF256.add(5_u8, Shamir::GF256.multiply(2_u8, 3_u8))
        result.should eq(expected)
      end
    end

    describe ".lagrange_interpolate" do
      it "reconstructs constant polynomial (degree 0)" do
        # If all y values are the same, polynomial is constant
        points = [{1_u8, 42_u8}, {2_u8, 42_u8}, {3_u8, 42_u8}]
        result = Shamir::MathGF256.lagrange_interpolate(points)
        result.should eq(42_u8)
      end
    end
  end

  describe Shamir::Share do
    describe "#to_hex" do
      it "converts share to hex string with correct format" do
        share = Shamir::Share.new(1_u8, Bytes[0x30, 0x39])
        hex = share.to_hex
        hex.should eq("01:3039")
      end

      it "pads x-coordinate to 2 digits" do
        share = Shamir::Share.new(15_u8, Bytes[0xff])
        hex = share.to_hex
        hex.should eq("0f:ff")
      end

      it "handles multiple bytes" do
        share = Shamir::Share.new(1_u8, Bytes[0x12, 0x34, 0x56, 0x78])
        hex = share.to_hex
        hex.should eq("01:12345678")
      end
    end

    describe ".from_hex" do
      it "deserializes hex string correctly" do
        hex = "01:3039"
        share = Shamir::Share.from_hex(hex)
        share.x.should eq(1)
        share.y.should eq(Bytes[0x30, 0x39])
      end

      it "handles single byte" do
        hex = "0f:ff"
        share = Shamir::Share.from_hex(hex)
        share.x.should eq(15)
        share.y.should eq(Bytes[0xff])
      end

      it "raises error on invalid format" do
        expect_raises(ArgumentError, "Invalid hex format") do
          Shamir::Share.from_hex("invalid")
        end
      end

      it "round-trips correctly" do
        original = Shamir::Share.new(42_u8, Bytes[0xde, 0xad, 0xbe, 0xef])
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
