# -*- coding: utf-8 -*-
#
# Copyright (C) 2012  Kouhei Sutou <kou@clear-code.com>
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

module Groonga
  class QueryLogger
    module Flags
      LABELS = {
        COMMAND     => "command",
        RESULT_CODE => "result_code",
        DESTINATION => "destination",
        CACHE       => "cache",
        SIZE        => "size",
        SCORE       => "score",
      }

      class << self
        def parse(input, base_flags)
          # TODO
          base_flags
        end

        def label(flags)
          labels = []
          LABELS.each do |flag, label|
            flags << label if (flags & flag) == flag
          end
          labels << "none" if labels.empty?
          labels.join("|")
        end
      end
    end

    def log(flag, timestamp, info, message)
      guard do
        puts("#{timestamp}|#{info}#{message}")
      end
    end

    def reopen
    end

    def fin
    end

    private
    def guard
      begin
        yield
      rescue Exception
        $stderr.puts("#{$!.class}: #{$!.message}")
        $stderr.puts($@)
      end
    end
  end

  class FileQueryLogger < QueryLogger
    def initialize(file_name)
      super()
      @file = nil
      @file_name = file_name
    end

    def reopen
      guard do
        return unless @file
        @file.close
        @file = nil
      end
    end

    def fin
      guard do
        return unless @file
        @file.close
      end
    end

    private
    def ensure_open
      return if @file
      @file = File.open(@file_name, "ab")
    end

    def puts(*arguments)
      ensure_open
      @file.puts(*arguments)
      @file.flush
    end
  end

  class CallbackQueryLogger < QueryLogger
    def initialize(callback)
      super()
      @callback = callback
    end

    def log(flag, timestamp, info, message)
      guard do
        @callback.call(:log, flag, timestamp, info, message)
      end
    end

    def reopen
      guard do
        @callback.call(:reopen)
      end
    end

    def fin
      guard do
        @callback.call(:fin)
      end
    end
  end
end
