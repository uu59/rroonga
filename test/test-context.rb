# Copyright (C) 2009  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

class ContextTest < Test::Unit::TestCase
  include GroongaTestUtils

  def setup
    Groonga::Context.default = nil
    Groonga::Context.default_options = nil
  end

  def test_default
    context = Groonga::Context.default
    assert_not_predicate(context, :use_ql?)
    assert_not_predicate(context, :batch_mode?)
    assert_equal(Groonga::Encoding::DEFAULT, context.encoding)
  end

  def test_default_options
    Groonga::Context.default_options = {
      :use_ql => true,
      :batch_mode => true,
      :encoding => Groonga::Encoding::UTF8,
    }
    context = Groonga::Context.default
    assert_predicate(context, :use_ql?)
    assert_predicate(context, :batch_mode?)
    assert_equal(Groonga::Encoding::UTF8, context.encoding)
  end

  def test_use_ql?
    context = Groonga::Context.new
    assert_not_predicate(context, :use_ql?)

    context = Groonga::Context.new(:use_ql => true)
    assert_predicate(context, :use_ql?)
  end

  def test_batch_mode?
    context = Groonga::Context.new
    assert_not_predicate(context, :batch_mode?)

    context = Groonga::Context.new(:batch_mode => true)
    assert_predicate(context, :batch_mode?)
  end

  def test_encoding
    context = Groonga::Context.new
    assert_equal(Groonga::Encoding::DEFAULT, context.encoding)

    context = Groonga::Context.new(:encoding => :utf8)
    assert_equal(Groonga::Encoding::UTF8, context.encoding)
  end
end
