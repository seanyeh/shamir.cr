# Shamir

A Crystal implementation of Shamir's Secret Sharing algorithm.

Split a secret into `n` shares where any `k` shares can reconstruct the original secret, but `k-1` shares reveal nothing.

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  shamir:
    github: seanyeh/shamir.cr
```

## Usage

### Basic Example

```crystal
require "shamir"

# Split a secret into 5 shares, requiring 3 to reconstruct
secret = "my secret message"
shares = Shamir.split(secret, 5, 3)

# Reconstruct the secret from any 3 shares
reconstructed = Shamir.combine(shares[0..2])
puts String.new(reconstructed)  # => "my secret message"
```

Shares can be serialized to hex strings for storage or transmission:

```crystal
# Serialize shares to hex
shares = Shamir.split("my secret", 5, 3)
hex_strings = shares.map(&.to_hex)
# => ["01:a3f2e5d4...", "02:b8c3d9f1...", ...]

# Deserialize from hex
loaded_shares = hex_strings.map { |hex| Shamir::Share.from_hex(hex) }
secret = Shamir.combine(loaded_shares[0..2])
```

## Limitations

- **Maximum secret size:** 65 bytes
- **Maximum shares:** 255

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

MIT
