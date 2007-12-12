#  LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung, 
#  Mehrworterkennung und Relationierung.
#
#  Copyright (C) 2005  John Vorhauer
#
#  This program is free software; you can redistribute it and/or modify it under 
#  the terms of the GNU General Public License as published by the Free Software 
#  Foundation;  either version 2 of the License, or  (at your option)  any later
#  version.
#
#  This program is distributed  in the hope  that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
#  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#  You should have received a copy of the  GNU General Public License along with 
#  this program; if not, write to the Free Software Foundation, Inc., 
#  51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
#  For more information visit http://www.lex-lingo.de or contact me at
#  welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
#  Lex Lingo rules from here on


#  LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung, 
#  Mehrworterkennung und Relationierung.
#
#  Copyright (C) 2005  John Vorhauer
#
#  This program is free software; you can redistribute it and/or modify it under 
#  the terms of the GNU General Public License as published by the Free Software 
#  Foundation;  either version 2 of the License, or  (at your option)  any later
#  version.
#
#  This program is distributed  in the hope  that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
#  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
#  You should have received a copy of the  GNU General Public License along with 
#  this program; if not, write to the Free Software Foundation, Inc., 
#  51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
#  For more information visit http://www.lex-lingo.de or contact me at
#  welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
#  Lex Lingo rules from here on


STRING_SEPERATOR_PATTERN = /[; ,\|]/
FILE_EXTENSION_PATTERN = /(\.[^.]+)$/

#    String-Konstanten im Datenstrom

CHAR_PUNCT    = '.'

ISO8859_1_ALPHANUM = "0-9A-Za-z"
WIN1252_EXTRA = "\x8A\x8C\x8E\x9A\x9C\x9E\x9F"
ISO8859_1_EXTRA = "\xC0-\xCF\xD1-\xD6\xD8-\xDD\xDF-\xF6\xF8-\xFD\xFF"
PRINTABLE_CHAR = "#{ISO8859_1_ALPHANUM}#{WIN1252_EXTRA}#{ISO8859_1_EXTRA}<>"


#
#    stream commands
#
STR_CMD_TALK  = 'TALK'
STR_CMD_STATUS   = 'STATUS'
STR_CMD_ERR   = 'ERR'
STR_CMD_WARN   = 'WARN'
STR_CMD_LIR    = 'LIR-FORMAT'
STR_CMD_FILE  = 'FILE'
STR_CMD_EOL   = 'EOL'
STR_CMD_RECORD   = 'RECORD'
STR_CMD_EOF   = 'EOF'

#
#    class StringA attributes
#
#    token attributes
TA_WORD      = 'WORD'
TA_PUNCTUATION  = 'PUNC'
TA_NUMERICAL  = 'NUMS'
TA_URL      = 'URLS'
TA_ABREVIATION  = 'ABRV'
TA_ABREVIATION1  = 'ABRS'
#TA_ABREVIATION1  = '*ABR1'
TA_OTHER    = 'OTHR'
TA_STOPWORD    = 'STOP'



#
#    word attributes
#
WA_UNSET      = '-'    #    Standardattribut bei der Initialisierung eines Word-Objektes
WA_IDENTIFIED    = 'IDF'    #    Status, nachdem das Word im Wörterbuch gefunden wurde
WA_UNKNOWN      = '?'    #    Status, wenn das Word nicht gefunden werden konnte
WA_KOMPOSITUM    = 'KOM'    #    Wort ist als Kompositum erkannt worden
WA_MULTIWORD    = 'MUL'    #    Wort ist eine Mehrwortgruppe
WA_SEQUENCE      = 'SEQ'    #    Wort ist eine Mehrwortgruppe
WA_UNKMULPART    = 'MU?'    #    Word ist unbekannt, jedoch Teil einer Mehrwortgruppe

#    lexical attributes ( Wortklassen )
LA_SUBSTANTIV    = 's'
LA_ADJEKTIV      = 'a'
LA_VERB        = 'v'
LA_EIGENNAME    = 'e'

LA_KOMPOSITUM    = 'k'
LA_MULTIWORD    = 'm'
LA_SEQUENCE      = 'q'
LA_WORTFORM      = 'w'
LA_SYNONYM      = 'y'
LA_STOPWORD      = 't'
LA_TAKEITASIS    = 'x'
LA_UNKNOWN      = '?'

LA_SORTORDER    = [ \
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
  LA_UNKNOWN \
].reverse.join

#
#    field seperator for dbm files
#
KEY_SEP = '='
FLD_SEP = '|'
IDX_REF = '^'
KEY_REF = '*'
SYS_KEY = '~'
