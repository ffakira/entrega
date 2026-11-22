require "argon2id"

module Security
  class Argon2idPasswordHasher
    TIME_COST = 2
    MEMORY_COST = 19_456
    PARALLELISM = 1
    SALT_LENGTH = 16
    OUTPUT_LENGTH = 32

    class << self
      def create(password)
        Argon2id::Password.create(
          password,
          t_cost: TIME_COST,
          m_cost: MEMORY_COST,
          parallelism: PARALLELISM,
          salt_len: SALT_LENGTH,
          output_len: OUTPUT_LENGTH
        ).to_s
      end

      def verify(password, digest)
        return false unless password.is_a?(String)
        return false unless digest.is_a?(String)
        return false unless Argon2id::Password.valid_hash?(digest)

        Argon2id::Password.new(digest).is_password?(password)
      rescue Argon2id::Error, ArgumentError, TypeError
        false
      end

      def salt(digest)
        return if digest.blank?
        return unless Argon2id::Password.valid_hash?(digest)

        # Return the encoded salt, not its binary representation.
        digest.split("$")[4]
      rescue Argon2id::Error, ArgumentError, TypeError
        nil
      end
    end
  end
end
