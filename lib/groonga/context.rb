# -*- coding: utf-8 -*-
#
# Copyright (C) 2010-2013  Kouhei Sutou <kou@clear-code.com>
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

require "groonga/command"

module Groonga
  class Context
    # _path_ にある既存のデータベースを開く。ブロックを指定した場
    # 合はブロックに開いたデータベースを渡し、ブロックを抜けると
    # きに閉じる。
    def open_database(path, &block)
      options = {:context => self}

      Database.open(path, options, &block)
    end

    # This is convenience method. It wraps {Groonga::Database.create}
    # for the context.
    #
    # @overload create_database
    #   Creates a new temproary database for the context.
    #
    #   @return [Groonga::Database] A new temporary database.
    #
    #   @example Creating a new temporary database
    #     temporary_database = context.create_database
    #
    # @overload create_database(&block)
    #   Creates a new temproary database for the context. The database
    #   is closed after the passed block is finished.
    #
    #   @yield [database] Yields a newly created temporary database
    #     for the context. The database is available only in the
    #     block.
    #
    #   @yieldparam [Groonga::Database] database A newly created
    #     temporary database for the context.
    #
    #   @yieldreturn [Object] The returned value from the block is the
    #     returned value from this method.
    #
    #   @return Returned value from the block.
    #
    #   @example Creating a new temporary database with block
    #     context.create_database do |temporary_database|
    #       # ...
    #     end
    #
    # @overload create_database(path)
    #   Creates a new persistent database for the context to the _path_.
    #
    #   @param [String] path Database path for a new persistent
    #     database.
    #
    #   @return [Groonga::Database] A new persistent database for the
    #     context.
    #
    #   @example Creating a new persistent database to _"/tmp/db.groonga"_
    #     database = context.create_database("/tmp/db.groonga")
    #
    # @overload create_database(path, &block)
    #   Creates a new persistent database for the context to the
    #   _path_. The database is closed after the passed block is
    #   finished.
    #
    #   @param [String] path Database path for a new persistent
    #     database.
    #
    #   @yield [database] Yields a newly created persistent database
    #     for the context. The database is available only in the
    #     block.
    #
    #   @yieldparam [Groonga::Database] database A newly created
    #     persistent database for the context.
    #
    #   @yieldreturn [Object] The returned value from the block is the
    #     returned value from this method.
    #
    #   @return Returned value from the block.
    #
    #   @example Creating a new persistent database to _"/tmp/db.groonga"_ database with block
    #     context.create_database("/tmp/db.groonga") do |persistent_database|
    #       # ...
    #     end
    def create_database(path=nil, &block)
      options = {:context => self}
      if path
        options[:path] = path
      end

      Database.create(options, &block)
    end

    # groongaのプラグインディレクトリにあるプラグイン _name_
    # を登録する。 _path_ を指定するとプラグインディレクトリ以
    # 外にあるプラグインを登録することができる。
    def register_plugin(name_or_options)
      options = {:context => self}
      if name_or_options.is_a?(String)
        name = name_or_options
        Plugin.register(name, options)
      else
        Plugin.register(name_or_options.merge(options))
      end
    end

    # _table_ から指定した条件にマッチするレコードの値を取得
    # する。 _table_ はテーブル名かテーブルオブジェクトを指定
    # する。
    #
    # _options_ に指定できるキーは以下の通り。
    # @param [::Hash] options The name and value
    #   pairs. Omitted names are initialized as the default value.
    # @option options [Array] output_columns The output_columns
    #
    #   値を取得するカラムを指定する。
    # @option options [Array] XXX TODO
    #   TODO
    def select(table, options={})
      select = Command::Select.new(self, table, options)
      select.exec
    end

    # Restore commands dumped by "grndump" command.
    #
    # @example Restore dumped commands as a String object.
    #   dumped_commands = File.read("dump.grn")
    #   context.restore(dumped_commands)
    #
    # @example Restore dumped commands from a File object.
    #   File.open("dump.grn") do |file|
    #     context.restore(file)
    #   end
    #
    # If block is given, response is yielded.
    #
    # @example Restore dumped commands and reports result.
    #   dumped_commands = File.read("dump.grn")
    #   context.restore(dumped_commands) do |command, response|
    #     puts("#{command} -> #{response}")
    #   end
    #
    # @param [#each_line] dumped_commands commands dumped by grndump.
    #   It can be String or any objects like IO object such as File
    #   object. It should have #each_line that iterates a line.
    # @yield [command, response]
    #   Yields a sent command and its response if block is given.
    # @yieldparam command [String] A sent command.
    # @yieldparam response [String] A response for a command.
    # @return [void]
    def restore(dumped_commands)
      buffer = ""
      continued = false
      dumped_commands.each_line do |line|
        line = line.chomp
        case line
        when /\\\z/
          continued = true
          buffer << $PREMATCH
        else
          continued = false
          buffer << line
          send(buffer)
          _, response = receive
          if block_given?
            not_shared_command = continued ? buffer.dup : line
            yield(not_shared_command, response)
          end
          buffer.clear
        end
      end
      unless buffer.empty?
        send(buffer)
        _, response = receive
        yield(buffer.dup, response) if block_given?
      end
    end
  end
end
