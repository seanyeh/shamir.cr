require "./spec_helper"
require "../src/shamir/gf256"

describe Shamir::GF256 do
  describe ".add" do
    it "performs XOR addition" do
      Shamir::GF256.add(0x53_u8, 0xca_u8).should eq(0x53_u8 ^ 0xca_u8)
    end

    it "is commutative" do
      a, b = 0x7d_u8, 0x3c_u8
      Shamir::GF256.add(a, b).should eq(Shamir::GF256.add(b, a))
    end

    it "has 0 as identity" do
      a = 0x42_u8
      Shamir::GF256.add(a, 0_u8).should eq(a)
    end
  end

  describe ".sub" do
    it "is the same as addition (XOR)" do
      a, b = 0x53_u8, 0xca_u8
      Shamir::GF256.sub(a, b).should eq(Shamir::GF256.add(a, b))
    end
  end

  describe ".multiply" do
    it "returns 0 when either operand is 0" do
      Shamir::GF256.multiply(0x42_u8, 0_u8).should eq(0_u8)
      Shamir::GF256.multiply(0_u8, 0x42_u8).should eq(0_u8)
    end

    it "has 1 as multiplicative identity" do
      a = 0x42_u8
      Shamir::GF256.multiply(a, 1_u8).should eq(a)
    end

    it "is commutative" do
      a, b = 0x7d_u8, 0x3c_u8
      Shamir::GF256.multiply(a, b).should eq(Shamir::GF256.multiply(b, a))
    end

    it "is associative" do
      a, b, c = 0x7d_u8, 0x3c_u8, 0x91_u8
      left = Shamir::GF256.multiply(Shamir::GF256.multiply(a, b), c)
      right = Shamir::GF256.multiply(a, Shamir::GF256.multiply(b, c))
      left.should eq(right)
    end

    it "distributes over addition" do
      a, b, c = 0x7d_u8, 0x3c_u8, 0x91_u8
      left = Shamir::GF256.multiply(a, Shamir::GF256.add(b, c))
      right = Shamir::GF256.add(Shamir::GF256.multiply(a, b), Shamir::GF256.multiply(a, c))
      left.should eq(right)
    end
  end

  describe ".divide" do
    it "raises on division by zero" do
      expect_raises(ArgumentError, "Division by zero in GF(256)") do
        Shamir::GF256.divide(0x42_u8, 0_u8)
      end
    end

    it "returns 0 when numerator is 0" do
      Shamir::GF256.divide(0_u8, 0x42_u8).should eq(0_u8)
    end

    it "satisfies (a/b)*b = a" do
      a, b = 0x90_u8, 0x05_u8
      quotient = Shamir::GF256.divide(a, b)
      Shamir::GF256.multiply(quotient, b).should eq(a)
    end
  end

  describe ".inverse" do
    it "raises on inverse of zero" do
      expect_raises(ArgumentError, "No inverse for 0 in GF(256)") do
        Shamir::GF256.inverse(0_u8)
      end
    end

    it "satisfies a * inverse(a) = 1" do
      a = 0x53_u8
      inv = Shamir::GF256.inverse(a)
      Shamir::GF256.multiply(a, inv).should eq(1_u8)
    end

    it "works for all non-zero elements" do
      (1_u8..255_u8).each do |a|
        inv = Shamir::GF256.inverse(a)
        Shamir::GF256.multiply(a, inv).should eq(1_u8)
      end
    end
  end
end
