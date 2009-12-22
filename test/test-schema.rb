# Copyright (C) 2009  Kouhei Sutou <kou@clear-code.com>
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

class SchemaTest < Test::Unit::TestCase
  include GroongaTestUtils

  setup :setup_database

  def test_create_table
    assert_nil(context["<posts>"])
    Groonga::Schema.create_table("<posts>") do |table|
    end
    assert_not_nil(context["<posts>"])
  end

  def test_create_table_force
    Groonga::Schema.create_table("posts") do |table|
      table.string("name")
    end
    assert_not_nil(context["posts.name"])

    Groonga::Schema.create_table("posts") do |table|
    end
    assert_not_nil(context["posts.name"])

    Groonga::Schema.create_table("posts", :force => true) do |table|
    end
    assert_nil(context["posts.name"])
  end

  def test_remove_table
    Groonga::Array.create(:name => "posts")
    assert_not_nil(context["posts"])
    Groonga::Schema.remove_table("posts")
    assert_nil(context["posts"])
  end

  def test_define_hash
    Groonga::Schema.create_table("<posts>", :type => :hash) do |table|
    end
    assert_kind_of(Groonga::Hash, context["<posts>"])
  end

  def test_define_hash_with_full_option
    path = @tmp_dir + "hash.groonga"
    tokenizer = context["<token:trigram>"]
    type = Groonga::Type.new("Niku", :size => 29)
    Groonga::Schema.create_table("<posts>",
                                 :type => :hash,
                                 :key_type => "integer",
                                 :path => path.to_s,
                                 :value_type => type,
                                 :default_tokenizer => tokenizer) do |table|
    end
    table = context["<posts>"]
    assert_equal("#<Groonga::Hash " +
                 "id: <#{table.id}>, " +
                 "name: <<posts>>, " +
                 "path: <#{path}>, " +
                 "domain: <#{context['<int>'].inspect}>, " +
                 "range: <#{type.inspect}>, " +
                 "flags: <>, " +
                 "encoding: <#{Groonga::Encoding.default.inspect}>, " +
                 "size: <0>>",
                 table.inspect)
    assert_equal(tokenizer, table.default_tokenizer)
  end

  def test_define_patricia_trie
    Groonga::Schema.create_table("<posts>", :type => :patricia_trie) do |table|
    end
    assert_kind_of(Groonga::PatriciaTrie, context["<posts>"])
  end

  def test_define_patricia_trie_with_full_option
    path = @tmp_dir + "patricia-trie.groonga"
    type = Groonga::Type.new("Niku", :size => 29)
    Groonga::Schema.create_table("<posts>",
                                 :type => :patricia_trie,
                                 :key_type => "integer",
                                 :path => path.to_s,
                                 :value_type => type,
                                 :default_tokenizer => "<token:bigram>",
                                 :key_normalize => true,
                                 :key_with_sis => true) do |table|
    end
    table = context["<posts>"]
    assert_equal("#<Groonga::PatriciaTrie " +
                 "id: <#{table.id}>, " +
                 "name: <<posts>>, " +
                 "path: <#{path}>, " +
                 "domain: <#{context['<int>'].inspect}>, " +
                 "range: <#{type.inspect}>, " +
                 "flags: <KEY_WITH_SIS|KEY_NORMALIZE|WITH_SECTION>, " +
                 "encoding: <#{Groonga::Encoding.default.inspect}>, " +
                 "size: <0>>",
                 table.inspect)
    assert_equal(context["<token:bigram>"], table.default_tokenizer)
  end

  def test_define_array
    Groonga::Schema.create_table("<posts>", :type => :array) do |table|
    end
    assert_kind_of(Groonga::Array, context["<posts>"])
  end

  def test_define_array_with_full_option
    path = @tmp_dir + "array.groonga"
    type = Groonga::Type.new("Niku", :size => 29)
    Groonga::Schema.create_table("<posts>",
                                 :type => :array,
                                 :path => path.to_s,
                                 :value_type => type) do |table|
    end
    table = context["<posts>"]
    assert_equal("#<Groonga::Array " +
                 "id: <#{table.id}>, " +
                 "name: <<posts>>, " +
                 "path: <#{path}>, " +
                 "domain: <#{type.inspect}>, " +
                 "range: <#{type.inspect}>, " +
                 "flags: <>, " +
                 "size: <0>>",
                 table.inspect)
  end

  def test_column_with_full_option
    path = @tmp_dir + "column.groonga"
    type = Groonga::Type.new("Niku", :size => 29)
    Groonga::Schema.create_table("<posts>") do |table|
      table.column("rate",
                   type,
                   :path => path,
                   :persistent => true,
                   :type => :vector,
                   :compress => :lzo)
    end

    table = context["<posts>"]
    column_name = "<posts>.rate"
    column = context[column_name]
    assert_equal("#<Groonga::VariableSizeColumn " +
                 "id: <#{column.id}>, " +
                 "name: <#{column_name}>, " +
                 "path: <#{path}>, " +
                 "domain: <#{table.inspect}>, " +
                 "range: <#{type.inspect}>, " +
                 "flags: <COMPRESS_LZO>>",
                 column.inspect)
  end

  def test_integer32_column
    assert_nil(context["<posts>.rate"])
    Groonga::Schema.create_table("<posts>") do |table|
      table.integer32 :rate
    end
    assert_equal(context["<int>"], context["<posts>.rate"].range)
  end

  def test_integer64_column
    assert_nil(context["<posts>.rate"])
    Groonga::Schema.create_table("<posts>") do |table|
      table.integer64 :rate
    end
    assert_equal(context["<int64>"], context["<posts>.rate"].range)
  end

  def test_unsigned_integer32_column
    assert_nil(context["<posts>.n_viewed"])
    Groonga::Schema.create_table("<posts>") do |table|
      table.unsigned_integer32 :n_viewed
    end
    assert_equal(context["<uint>"], context["<posts>.n_viewed"].range)
  end

  def test_unsigned_integer64_column
    assert_nil(context["<posts>.n_viewed"])
    Groonga::Schema.create_table("<posts>") do |table|
      table.unsigned_integer64 :n_viewed
    end
    assert_equal(context["<uint64>"], context["<posts>.n_viewed"].range)
  end

  def test_float_column
    assert_nil(context["<posts>.rate"])
    Groonga::Schema.create_table("<posts>") do |table|
      table.float :rate
    end
    assert_equal(context["<float>"], context["<posts>.rate"].range)
  end

  def test_time_column
    assert_nil(context["<posts>.last_modified"])
    Groonga::Schema.create_table("<posts>") do |table|
      table.time :last_modified
    end
    assert_equal(context["<time>"], context["<posts>.last_modified"].range)
  end

  def test_short_text_column
    assert_nil(context["<posts>.title"])
    Groonga::Schema.create_table("<posts>") do |table|
      table.short_text :title
    end
    assert_equal(context["<shorttext>"], context["<posts>.title"].range)
  end

  def test_text_column
    assert_nil(context["<posts>.comment"])
    Groonga::Schema.create_table("<posts>") do |table|
      table.text :comment
    end
    assert_equal(context["<text>"], context["<posts>.comment"].range)
  end

  def test_long_text_column
    assert_nil(context["<posts>.content"])
    Groonga::Schema.create_table("<posts>") do |table|
      table.long_text :content
    end
    assert_equal(context["<longtext>"], context["<posts>.content"].range)
  end

  def test_remove_column
    Groonga::Schema.create_table("posts") do |table|
      table.long_text :content
    end
    assert_not_nil(context["posts.content"])

    Groonga::Schema.change_table("posts") do |table|
      table.remove_column("content")
    end
    assert_nil(context["posts.content"])
  end

  def test_column_again
    Groonga::Schema.create_table("posts") do |table|
      table.text :content
    end

    assert_nothing_raised do
      Groonga::Schema.create_table("posts") do |table|
        table.text :content
      end
    end
  end

  def test_column_again_with_difference_type
    Groonga::Schema.create_table("posts") do |table|
      table.text :content
    end

    assert_raise(ArgumentError) do
      Groonga::Schema.create_table("posts") do |table|
        table.integer :content
      end
    end
  end

  def test_index
    assert_nil(context["<terms>.content"])
    Groonga::Schema.create_table("<posts>") do |table|
      table.long_text :content
    end
    Groonga::Schema.create_table("<terms>") do |table|
      table.index "<posts>.content"
    end
    assert_equal([context["<posts>.content"]],
                 context["<terms>.<posts>_content"].sources)
  end

  def test_index_with_full_option
    path = @tmp_dir + "index-column.groonga"
    assert_nil(context["<terms>.content"])
    index_column_name = "posts-index"

    Groonga::Schema.create_table("<posts>") do |table|
      table.long_text :content
    end
    Groonga::Schema.create_table("<terms>") do |table|
      table.index("<posts>.content",
                  :name => index_column_name,
                  :path => path,
                  :persistent => true,
                  :with_section => true,
                  :with_weight => true,
                  :with_position => true)
    end

    posts = context["<posts>"]
    terms = context["<terms>"]
    full_index_column_name = "<terms>.#{index_column_name}"
    index_column = context[full_index_column_name]
    assert_equal("#<Groonga::IndexColumn " +
                 "id: <#{index_column.id}>, " +
                 "name: <#{full_index_column_name}>, " +
                 "path: <#{path}>, " +
                 "domain: <#{terms.inspect}>, " +
                 "range: <#{posts.inspect}>, " +
                 "flags: <WITH_SECTION|WITH_WEIGHT|WITH_POSITION|" +
                         "UNIT_DOCUMENT_SECTION|UNIT_DOCUMENT_POSITION|" +
                         "UNIT_USERDEF_DOCUMENT|UNIT_USERDEF_SECTION>>",
                 index_column.inspect)
  end

  def test_index_again
    Groonga::Schema.create_table("posts") do |table|
      table.long_text :content
    end
    Groonga::Schema.create_table("terms") do |table|
      table.index "posts.content"
    end

    assert_nothing_raised do
      Groonga::Schema.create_table("terms") do |table|
        table.index "posts.content"
      end
    end
  end

  def test_index_again_with_difference_source
    Groonga::Schema.create_table("posts") do |table|
      table.long_text :content
      table.short_text :name
    end
    Groonga::Schema.create_table("terms") do |table|
      table.index "posts.content"
    end

    assert_raise(ArgumentError) do
      Groonga::Schema.create_table("terms") do |table|
        table.index "posts.name", :name => "posts_content"
      end
    end
  end

  def test_dump
    Groonga::Schema.define do |schema|
      schema.create_table("posts") do |table|
        table.short_text :title
      end
    end
    assert_equal(<<-EOS, Groonga::Schema.dump)
create_table("posts") do |table|
  table.short_text("title")
end
EOS
  end

  def test_reference_dump
    Groonga::Schema.define do |schema|
      schema.create_table("items") do |table|
        table.short_text("title")
      end

      schema.create_table("users") do |table|
        table.short_text("name")
      end

      schema.create_table("comments") do |table|
        table.reference("item", "items")
        table.reference("author", "users")
        table.text("content")
        table.time("issued")
      end
    end

    assert_equal(<<-EOS, Groonga::Schema.dump)
create_table("comments") do |table|
  table.text("content")
  table.time("issued")
end

create_table("items") do |table|
  table.short_text("title")
end

create_table("users") do |table|
  table.short_text("name")
end

change_table("comments") do |table|
  table.reference("author", "users")
  table.reference("item", "items")
end
EOS
  end

  def test_explicit_context_create_table
    context = Groonga::Context.default
    Groonga::Context.default = nil

    Groonga::Schema.define(:context => context) do |schema|
      schema.create_table('items', :type => :hash) do |table|
        table.text("text")
      end
      schema.create_table("terms_text",
                          :type => :patricia_trie,
                          :key_normalize => true,
                          :default_tokenizer => "TokenBigram") do |table|
        table.index('items.text')
      end
    end

    assert_not_nil(context["items.text"])
    assert_not_nil(context["terms_text.items_text"])
  end
end
