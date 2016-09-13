# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2016 John Vorhauer, Jens Wille                           #
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

require 'openssl'
require 'digest/sha1'

class Lingo

  class Database

    module Crypter

      extend self

      KEYLEN = 16

      CIPHER = 'AES-128-CBC'.freeze

      def digest(key)
        Digest::SHA1.hexdigest(key)
      end

      def encode(key, val)
        [digest = digest(key), crypt(:encrypt, key, val, digest)]
      end

      def decode(key, val)
        crypt(:decrypt, key, val, digest(key)).force_encoding(ENCODING)
      end

      private

      def crypt(method, key, val, digest)
        cipher = OpenSSL::Cipher.new(CIPHER).send(method)
        cipher.iv = cipher.key = digest[0, KEYLEN]
        cipher.update(val) + cipher.final
      end

    end

  end

end
