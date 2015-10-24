# Copyright (c) 2015 American Registry for Internet Numbers
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

require 'jcr/parser'
require 'jcr/map_rule_names'
require 'jcr/check_groups'
require 'jcr/evaluate_rules'

module JCR

  def self.evaluate_object_rule jcr, rule_atom, data, mapping

    rules, annotations = get_rules_and_annotations( jcr )

    # if the data is not an object (Hash)
    return evaluate_reject( annotations,
      Evaluation.new( false, "#{data} is not an object at #{jcr} from #{rule_atom}") ) unless data.is_a? Hash

    # if the object has no members and there are zero sub-rules (it is suppose to be empty)
    return evaluate_reject( annotations,
      Evaluation.new( true, nil ) ) if rules.empty? && data.length == 0

    # if the object has members and there are zero sub-rules (it is suppose to be empty)
    return evaluate_reject( annotations,
      Evaluation.new( false, "Non-empty object at #{jcr} from #{rule_atom}" ) ) if rules.empty? && data.length != 0

    retval = nil
    checked = {}

    rules.each do |rule|

      # short circuit logic
      if rule[:choice_combiner] && retval && retval.success
        return evaluate_reject( annotations, retval )# short circuit
      elsif rule[:sequence_combiner] && retval && !retval.success
        return evaluate_reject( annotations, retval ) # short circuit
      end

      repeat_min, repeat_max = get_repetitions( rule )

      repeat_results = data.select do |k,v|
        unless checked[ k ]
          e = evaluate_rule( rule, rule_atom, [k,v], mapping)
          checked[ k ] = e.success
          e.success
        end
      end

      if repeat_results.length == 0 && repeat_min > 0
        retval = Evaluation.new( false, "object does not contain #{rule} for #{jcr} from #{rule_atom}")
      elsif repeat_results.length < repeat_min
        retval = Evaluation.new( false, "object does not have enough #{rule} for #{jcr} from #{rule_atom}")
      elsif repeat_results.length > repeat_max
        retval = Evaluation.new( false, "object has too many #{rule} for #{jcr} from #{rule_atom}")
      else
        retval = Evaluation.new( true, nil)
      end

    end

    return evaluate_reject( annotations, retval )
  end

end
