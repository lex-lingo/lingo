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



#
#    Die Klasse StringA ist die Basisklasse für weitere Klassen, die im Rahmen der 
#    Objektstruktur eines Wortes benötigt werden. Die Klasse stellt eine Zeichenkette bereit,
#    die mit einem Attribut versehen werden kann.
#
class StringA
  include Comparable
  attr_accessor :form, :attr

  def initialize(form, attr='-')
    @form = form || ''
    @attr = attr || ''
    self
  end


  def <=>(other)
    return 1 if other.nil?
    if @form==other.form
      @attr<=>other.attr
    else
      @form<=>other.form
    end
  end  


  def to_s
    @form + '/' + @attr
  end  

  def inspect
    to_s
  end

end

#
#    Die Klasse Token, abgeleitet von der Klasse StringA, stellt den Container
#    für ein einzelnes Wort eines Textes dar. Das Wort wird mit einem Attribut versehen,
#    welches der Regel entspricht, die dieses Wort identifiziert hat.
#
#    Steht z.B. in ruby.cfg eine Regel zur Erkennung einer Zahl, die mit NUM bezeichnet wird,
#    so wird dies dem Token angeheftet, z.B. Token.new('100', 'NUM') -> #100/NUM#
#
class Token < StringA
  def to_s;  ':' + super + ':';  end  
end

#
#    Die Klasse Lexical, abgeleitet von der Klasse StringA, stellt den Container
#    für eine Grundform eines Wortes bereit, welches mit der Wortklasse versehen ist.
#
#    Wird z.B. aus dem Wörterbuch eine Grundform gelesen, so wird dies in Form eines
#    Lexical-Objektes zurückgegeben, z.B. Lexical.new('Rennen', 'S') -> (rennen/s)
#
class Lexical < StringA
  
  def <=>(other)
#v TODO: v1.5.1
    return 1 unless other.is_a?(Lexical)
#v
    if self.attr==other.attr
      #    gleiche attribute
      self.form<=>other.form
    else
      case  #    leeres attribut unterliegt
      when self.attr==''    then  1
      when  other.attr==''  then  -1
      else  #    vergleich der attribute
        ss = LA_SORTORDER.index(self.attr) || -1 # ' -weavsk'
        os = LA_SORTORDER.index(other.attr) || -1
        case    
        when ss==-1 && os==-1  #    beides unpriviligierte attribute (und nicht gleich)
          self.attr<=>other.attr
        when ss==-1 && os>-1  then  1
        when ss>-1 && os==-1  then  -1
        when ss>-1 && os>-1      #    beides priviligierte attribute (und nicht gleich)
          os<=>ss
        end
      end
    end
  end

#v TODO: v1.5.1
  def to_a
    [@form, @attr]
  end  
  
  def to_str;  @form + '#' + @attr;  end  
#v
  def to_s;  '(' + super + ')';  end  
end


#
#    Die Klasse Word bündelt spezifische Eigenschaften eines Wortes mit den 
#    dazu notwendigen Methoden.
#
class Word < StringA

  #    Exakte Representation der originären Zeichenkette, so wie sie im Satz 
  #    gefunden wurde, z.B. <tt>form = "RubyLing"</tt>
  
  #    Ergebnis der Wörterbuch-Suche. Sie stellt die Grundform des Wortes dar.
  #    Dabei kann es mehrere mögliche Grundformen geben, z.B. kann +abgeschoben+ 
  #    als Grundform das _Adjektiv_ +abgeschoben+ sein, oder aber das _Verb_ 
  #    +abschieben+. 
  #
  #    <tt>lemma = [['abgeschoben', '#a'], ['abschieben', '#v']]</tt>.
  #
  #    <b>Achtung: Lemma wird nicht durch die Word-Klasse bestückt, sondern extern
  #    durch die Klasse Dictionary</b>

  def initialize(form, attr=WA_UNSET)
    super
    @lexicals = Array.new
    self
  end
  
  def lexicals
    @lexicals
  end

  def lexicals=(lexis)
    if lexis.is_a?(Array)
      @lexicals = lexis.sort.uniq2
    else
      puts "Falscher Typ bei Zuweisung"
    end
  end

  #    für Compositum
  def parts
    1
  end

  def min_part_size
    @form.size
  end


  #    Gibt genau die Grundform der Wortklasse zurück, die der RegExp des Übergabe-Parameters 
  #    entspricht, z.B. <tt>word.get_wc(/a/) = ['abgeschoben', '#a']</tt>
  def get_class(wc_re)
    if @lexicals.size>0
      @lexicals.collect { |lex|
        if lex.attr =~ Regexp.new(wc_re)
          lex
        else
          nil
        end
      }.compact
    else
      []
    end
  end


  def norm
    if @attr == WA_IDENTIFIED
      lexicals[0].form
    else
      @form
    end
  end


  def compo_form
    if @attr==WA_KOMPOSITUM
      get_class(LA_KOMPOSITUM)[0]
    else
      nil
    end
  end


  def <<(other)
    case other
      when Lexical  then @lexicals << other
      when Array    then @lexicals += other
    end
    self
  end


  def <=>(other)
    return 1 if other.nil? 
    if @form==other.form
      if @attr==other.attr
        @lexicals<=>other.lexicals
      else
        @attr<=>other.attr
      end
    else
      @form<=>other.form
    end
  end  


  def to_s
    s = '<' + @form
    s << '|' + @attr unless @attr==WA_IDENTIFIED
    s << ' = ' + @lexicals.inspect unless @lexicals.empty?
    s << '>'
  end

end



class AgendaItem
  include Comparable
  attr_reader :cmd, :param

private

  def initialize(cmd, param='')
    @cmd = cmd || ''
    @param = param || ''
  end


  def <=>(other)
    return 1 unless other.is_a?(AgendaItem)
    if self.cmd==other.cmd
      self.param<=>other.param
    else
      self.cmd<=>other.cmd
    end
  end


public

  def inspect
    "*#{cmd.upcase}('#{param}')"
  end

end


