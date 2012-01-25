# encoding: utf-8

#--
# LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
# Mehrworterkennung und Relationierung.
#
# Copyright (C) 2005-2007 John Vorhauer
# Copyright (C) 2007-2012 John Vorhauer, Jens Wille
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
# For more information visit http://www.lex-lingo.de or contact me at
# welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
# Lex Lingo rules from here on
#++

require_relative 'language/lexical_hash'
require_relative 'language/dictionary'
require_relative 'language/grammar'
require_relative 'language/word_form'
require_relative 'language/token'
require_relative 'language/lexical'
require_relative 'language/word'

class Lingo

  module Language

    # String-Konstanten im Datenstrom
    CHAR_PUNCT = '.'

    TA_WORD        = 'WORD'
    TA_PUNCTUATION = 'PUNC'
    TA_OTHER       = 'OTHR'

    # Standardattribut bei der Initialisierung eines Word-Objektes
    WA_UNSET      = '-'
    # Status, nachdem das Word im Wörterbuch gefunden wurde
    WA_IDENTIFIED = 'IDF'
    # Status, wenn das Word nicht gefunden werden konnte
    WA_UNKNOWN    = '?'
    # Wort ist als Kompositum erkannt worden
    WA_KOMPOSITUM = 'KOM'
    # Wort ist eine Mehrwortgruppe
    WA_MULTIWORD  = 'MUL'
    # Wort ist eine Mehrwortgruppe
    WA_SEQUENCE   = 'SEQ'
    # Word ist unbekannt, jedoch Teil einer Mehrwortgruppe
    WA_UNKMULPART = 'MU?'

    LA_SUBSTANTIV = 's'
    LA_ADJEKTIV   = 'a'
    LA_VERB       = 'v'
    LA_EIGENNAME  = 'e'
    LA_KOMPOSITUM = 'k'
    LA_MULTIWORD  = 'm'
    LA_SEQUENCE   = 'q'
    LA_WORTFORM   = 'w'
    LA_SYNONYM    = 'y'
    LA_STOPWORD   = 't'
    LA_TAKEITASIS = 'x'
    LA_UNKNOWN    = '?'

    LA_SORTORDER = [
      LA_MULTIWORD,
      LA_KOMPOSITUM,
      LA_SUBSTANTIV,
      LA_VERB,
      LA_ADJEKTIV,
      LA_EIGENNAME,
      LA_WORTFORM,
      LA_STOPWORD,
      LA_TAKEITASIS,
      LA_SYNONYM,
      LA_UNKNOWN
    ].reverse.join

  end

end
