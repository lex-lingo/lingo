require "yaml"
class String
  def to_shadow
    shadow = self.gsub(/[^aeiouy]/, 'c')
    shadow.gsub!(/[aeiou]/, 'v')
    shadow.gsub!(/cy/, 'cv')
    shadow.gsub!(/y/, 'c')
    shadow
  end
end



# => condition nil oder eine evaluierbare regel
# => matchExp eine Regexp
# => replacement ist downcase
# => return new stem or nil, if rule didn't match
def checkSingleRule(word, condition, matchExp, replacement)

  # => check for matching rule
  return nil unless matchExp.match(word)

  # => remember stem
  stem = $1

  # => check condition for rule
  unless condition.nil?
    evalCondition = condition.dup

    stemShadow = stem.to_shadow
    
    unless condition.index("m").nil?
      m = stemShadow.squeeze.scan(/vc/).size
      evalCondition.gsub!(/m/, m.to_s)
    end
    
    unless condition.index("*v*").nil?
      evalCondition.gsub!(/\*v\*/, stemShadow.index("v").nil? ? "false" : "true")
    end
    
    unless condition.index("*d").nil?
      evalCondition.gsub!(/\*d/, (stemShadow[-1..-1]=="c" && stem[-1]==stem[-2]) ? "true" : "false")
    end
    
    unless condition.index("*o").nil?
      bool = /cvc$/.match(stemShadow) && "wxy".index(stemShadow[-1..-1]).nil?
      evalCondition.gsub!(/\*o/, bool ? "true" : "false")
    end

    while /\*(\w)/.match(evalCondition)
      char = $1
      if char.downcase == char
        puts "unbekannter Buchstabe %s in Regel: %" % [char, condition]
        exit
      end
      
      bool = (stem[-1..-1].upcase == char)
      evalCondition.gsub!(Regexp.new(Regexp.escape("*#{char}")), bool ? "true" : "false")
    end

    evalCondition.gsub!(/and/, '&&')
    evalCondition.gsub!(/or/, '||')
    evalCondition.gsub!(/not/, '!')
    evalCondition.gsub!(/=/, '==')
p evalCondition
    return unless eval(evalCondition)
  end

  # => stem with replacement
  if /^(-\d+)$/.match(replacement)
    # => delete last characters from stem, if replacement looks like '-1' oder '-2'
    stem[0...($1.to_i)]
  else
    # => append replacement to stem
    stem + replacement
  end
    
end

def checkAllRules(word, rules)
  sequence = rules.keys.sort.reverse

  actualRuleSet = sequence.pop.to_s

  begin
#    puts "processing rule set %s" % actualRuleSet

    label = nil

    rules[actualRuleSet].each do |rule|
      unless /^(\(.+\)){0,1}\s*(\S*)\s*->\s*(\S*?)\s*(?:goto\((\S+)\))*\s*$/.match(rule)
        unless /^\s*goto\s*\(\s*(\S+)\s*\)$/.match(rule)
          puts "ungültige Regel: %s" % rule
          exit
        else
          label = $1
          break
        end
      end
      
      condition, ending, replacement, label = $1, $2.downcase, $3.downcase, $4     
      p   [rule, word, condition, ending, replacement, label ]
      result = checkSingleRule(word, condition, Regexp.new("(.+)#{ending}$"), replacement)

      unless result.nil?
        p [word, actualRuleSet, rule]
        word = result
        break
      end
    end
    
    if label.nil?
      actualRuleSet = sequence.pop.to_s
    else
      while label != actualRuleSet && !actualRuleSet.nil?
        actualRuleSet = sequence.pop.to_s
      end
    end
  end until actualRuleSet.empty?

  word
end

stemmerConfig = YAML::load_file("stem.cfg")

$rules = stemmerConfig["stemmer"]

word = $*[0]
p checkAllRules(word, $rules)

def test(word, stem)
  result = checkAllRules(word, $rules)
  if stem != result
    puts "Falsches Wort %s, Stem %s, Result %s" % [word, stem, result]
  else
    puts "Korrekt: Wort %s, Stem %s" % [word, stem]
  end
end


#test("caresses", "caress")
#test("ponies", "poni")
#test("ties", "ti")
#test("caress", "caress")
#test("cats", "cat")

#test("feed", "feed")
#?test("agreed", "agree")
#test("plastered", "plaster")
#test("bled", "bled")
#test("motoring", "motor")
#test("sing", "sing")
