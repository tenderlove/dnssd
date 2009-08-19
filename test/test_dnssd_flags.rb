require 'minitest/autorun'
require 'dnssd'

class TestDNSSDFlags < MiniTest::Unit::TestCase

  def setup
    @flags = DNSSD::Flags.new
  end

  def test_accessors
    DNSSD::Flags.constants.each do |name|
      next unless name =~ /[a-z]/
      attr = name.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').downcase

      assert_respond_to @flags, "#{attr}="
      assert_respond_to @flags, "#{attr}?"
    end
  end

  def test_add_eh
    refute @flags.add?

    @flags.add = true

    assert @flags.add?
  end

  def test_add_equals
    @flags.add = true

    assert_equal DNSSD::Flags::Add, @flags

    @flags.add = false

    assert_equal 0, @flags
  end

  def test_default_eh
    refute @flags.default?

    @flags.default = true

    assert @flags.default?
  end

  def test_default_equals
    @flags.default = true

    assert_equal DNSSD::Flags::Default, @flags

    @flags.default = false

    assert_equal 0, @flags
  end

  def test_clear_flag
    @flags.set_flag DNSSD::Flags::Add
    @flags.set_flag DNSSD::Flags::Default

    @flags.clear_flag DNSSD::Flags::Add

    assert_equal DNSSD::Flags::Default, @flags
  end

  def test_complement
    new_flags = ~@flags

    assert_equal DNSSD::Flags.new(*DNSSD::Flags::ALL_FLAGS), new_flags
  end

  def test_equals
    assert_equal @flags, DNSSD::Flags.new
    refute_equal @flags, DNSSD::Flags.new(DNSSD::Flags::Add)

    @flags.add = true
    @flags.default = true

    assert_equal @flags, (DNSSD::Flags::Add | DNSSD::Flags::Default)
    assert_equal @flags, (DNSSD::Flags::Add | DNSSD::Flags::Default)
  end

  def test_inspect
    assert_equal '#<DNSSD::Flags>', @flags.inspect

    @flags.add = true
    @flags.default = true

    assert_equal '#<DNSSD::Flags add, default>', @flags.inspect
  end

  def test_intersection
    new_flags = @flags & DNSSD::Flags::Add

    assert_equal @flags, new_flags

    @flags.default = true

    new_flags = @flags & DNSSD::Flags::Default

    assert_equal @flags, new_flags

    assert_equal new_flags, (new_flags & new_flags)
  end

  def test_set_flag
    @flags.set_flag DNSSD::Flags::Add

    assert_equal DNSSD::Flags::Add, @flags
  end

  def test_to_a
    assert_equal [], @flags.to_a

    @flags.add = true
    @flags.default = true

    assert_equal %w[add default], @flags.to_a.sort
  end

  def test_to_i
    assert_equal 0, @flags.to_i

    @flags.add = true
    @flags.default = true

    assert_equal 6, @flags.to_i
  end

  def test_union
    new_flags = @flags | DNSSD::Flags::Add

    assert_equal DNSSD::Flags.new(DNSSD::Flags::Add), new_flags

    new_flags = new_flags | DNSSD::Flags::Default

    assert_equal DNSSD::Flags.new(DNSSD::Flags::Add, DNSSD::Flags::Default),
                 new_flags

    assert_equal new_flags, (new_flags | new_flags)
  end

end

