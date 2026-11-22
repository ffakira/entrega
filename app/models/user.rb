class User < ApplicationRecord
  has_many :sessions, dependent: :destroy

  attr_reader :password
  attr_accessor :password_confirmation

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  DUMMY_PASSWORD_DIGEST =
    Security::Argon2idPasswordHasher.create(SecureRandom.hex(32)).freeze

  validates :email_address, presence: true

  validate :password_matches_confirmation

  validate do
    errors.add(:password, :blank) if password_digest.blank?
  end

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  def password=(unencrypted_password)
    unless unencrypted_password.nil? || unencrypted_password.is_a?(String)
      raise ArgumentError, "Password must be a String or nil"
    end

    @password = unencrypted_password

    if unencrypted_password.nil?
      self.password_digest = nil
    elsif !unencrypted_password.empty?
      self.password_digest =
        Security::Argon2idPasswordHasher.create(unencrypted_password)
    end
  end

  def authenticate(unencrypted_password)
    if Security::Argon2idPasswordHasher.verify(
      unencrypted_password,
      password_digest
    )
      self
    else
      false
    end
  end

  def password_salt
    Security::Argon2idPasswordHasher.salt(password_digest)
  end

  def password_reset_token
    generate_token_for(:password_reset)
  end

  def self.find_by_password_reset_token(token)
    find_by_token_for(:password_reset, token)
  end

  def self.find_by_password_reset_token!(token)
    find_by_token_for!(:password_reset, token)
  end

  def self.authenticate_by(attributes)
    credentials = attributes.to_h.symbolize_keys
    unencrypted_password = credentials.delete(:password)

    user = if credentials.present? && credentials.values.all?(&:present?)
      find_by(credentials)
    end

    return user.authenticate(unencrypted_password) || nil if user

    # Perform equivalent password-hash verification even when the
    # account does not exist, reducing timing-based account enumeration.
    Security::Argon2idPasswordHasher.verify(
      unencrypted_password,
      DUMMY_PASSWORD_DIGEST
    )

    nil
  end

  private

  def password_matches_confirmation
    return if password.blank? || password_confirmation.blank?
    return if password == password_confirmation

    errors.add(:password, :confirmation)
  end
end
