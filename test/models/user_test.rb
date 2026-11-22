require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    user = User.new(email_address: " DOWNCASED@EXAMPLE.COM ")

    assert_equal "downcased@example.com", user.email_address
  end

  test "stores passwords using Argon2id" do
    user = User.create!(
      email_address: "argon@example.com",
      password: "a-strong-test-password",
      password_confirmation: "a-strong-test-password"
    )

    assert_match(/\A\$argon2id\$v=19\$/, user.password_digest)
    assert_equal user, user.authenticate("a-strong-test-password")
  end

  test "rejects an incorrect password" do
    user = User.find_by!(email_address: "one@example.com")

    assert_equal false, user.authenticate("incorrect-password")
  end

  test "requires a password digest" do
    user = User.new(email_address: "missing@example.com")

    assert_not user.valid?
    assert_includes user.errors.attribute_names, :password
  end

  test "rejects mismatched password confirmation" do
    user = User.new(
      email_address: "mismatch@example.com",
      password: "first-password",
      password_confirmation: "different-password"
    )

    assert_not user.valid?
    assert_includes user.errors.attribute_names, :password
  end

  test "authenticate_by accepts valid credentials" do
    user = User.authenticate_by(
      email_address: "one@example.com",
      password: "password"
    )

    assert_equal "one@example.com", user.email_address
  end

  test "authenticate_by rejects incorrect credentials" do
    user = User.authenticate_by(
      email_address: "one@example.com",
      password: "incorrect"
    )

    assert_nil user
  end

  test "authenticate_by rejects unknown accounts" do
    user = User.authenticate_by(
      email_address: "unknown@example.com",
      password: "password"
    )

    assert_nil user
  end

  test "password reset token becomes invalid after password changes" do
    user = User.find_by!(email_address: "one@example.com")
    token = user.password_reset_token

    assert_equal user, User.find_by_password_reset_token(token)

    user.update!(
      password: "another-strong-password",
      password_confirmation: "another-strong-password"
    )

    assert_nil User.find_by_password_reset_token(token)
  end
end
