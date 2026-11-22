require "test_helper"

module Products
  class PriceParserTest < ActiveSupport::TestCase
    test "parses Brazilian decimal notation" do
      assert_equal 3290, PriceParser.call("32,90")
    end

    test "parses decimal notation with a dot" do
      assert_equal 3290, PriceParser.call("32.90")
    end

    test "parses Brazilian thousands separator" do
      assert_equal 125090, PriceParser.call("1.250,90")
    end

    test "parses ungrouped decimal notation" do
      assert_equal 125090, PriceParser.call("1250.90")
    end

    test "parses whole currency amounts" do
      assert_equal 3200, PriceParser.call("32")
    end

    test "pads a single decimal digit" do
      assert_equal 3250, PriceParser.call("32,5")
    end

    test "trims surrounding whitespace" do
      assert_equal 3290, PriceParser.call(" 32,90 ")
    end

    test "rejects malformed input" do
      [
        "",
        "abc",
        "32,999",
        "1,250.90",
        "1.25,90",
        "-32,90",
        "R$ 32,90",
        "32."
      ].each do |value|
        assert_nil PriceParser.call(value), "Expected #{value.inspect} to be rejected"
      end
    end
  end
end
