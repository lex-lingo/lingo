# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2012 John Vorhauer, Jens Wille                           #
#                                                                             #
# Lingo is free software; you can redistribute it and/or modify it under the  #
# terms of the GNU Affero General Public License as published by the Free     #
# Software Foundation; either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# Lingo is distributed in the hope that it will be useful, but WITHOUT ANY    #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   #
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for     #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU Affero General Public License    #
# along with Lingo. If not, see <http://www.gnu.org/licenses/>.               #
#                                                                             #
###############################################################################
#++

class Lingo

  class Database

    # Crypter ermöglicht die Ver- und Entschlüsselung von Wörterbüchern

    class Crypter

      HEX_CHARS = '0123456789abcdef'.freeze

      def digest(key)
        Digest::SHA1.hexdigest(key)
      end

      def encode(key, val)
        [digest(key), crypt(key, val).each_byte.with_object('') { |b, s|
          b.divmod(16).each { |i| s << HEX_CHARS[i] }
        }]
      end

      def decode(key, val)
        crypt(key, val.each_byte.each_slice(2).with_object('') { |b, s|
          q, r = b.map { |i| HEX_CHARS.index(i.chr(ENC)) }
          s << q * 16 + r
        })
      end

      private

      def crypt(k, v)
        c, y = '', k.codepoints.reverse_each.cycle
        v.each_codepoint { |x| c << (x ^ y.next).chr(ENC) }
        c
      end

    end

  end

end
