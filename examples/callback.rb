# Copyright (C) 2016 American Registry for Internet Numbers (ARIN)
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

# This example demonstrates using the JCR Validator with callbacks
# to perform custom validation

require 'jcr'

ruleset = <<RULESET
# ruleset-id rfcXXXX
# jcr-version 0.5

[ 2 my_integers, 2 my_strings ]

; this will be the rule we custom validate
my_integers :0..4

my_strings ( :"foo" | :"bar" )

RULESET

# Create a JCR context.
ctx = JCR::Context.new( ruleset )

# A local variable used in the callback closure
my_eval_count = 0

# The callback is created using a Proc object
c = Proc.new do |on|
  is_even = false

  # called if the rule evaluates to true
  # jcr is the rule
  # data is the data being evaluated against the rule
  on.rule_eval_true do |jcr,data|
    my_eval_count = my_eval_count + 1
    is_even = data.to_i % 2 == 0
  end

  # called if the rule evaluates to false
  # jcr is the rule
  # data is the data being evaluated against the rule
  # e is the evaluation of the rule
  on.rule_eval_false do |jcr,data,e|
    my_eval_count = my_eval_count + 1
    is_even = data.to_i % 2 == 0
  end

  # return the custom validation
  is_even
end

# register the callback to be called for the "my_integers" rule
ctx.callbacks[ "my_integers" ] = c

data1 = JSON.parse( '[ 2, 4, "foo", "bar" ]')
e = ctx.evaluate( data1 )
puts "Ruleset evaluation of JSON = " + e.success.to_s
puts "my_eval_count = " + my_eval_count.to_s

data2 = JSON.parse( '[ 3, 4, "foo", "bar" ]')
e = ctx.evaluate( data2 )
puts "Ruleset evaluation of JSON = " + e.success.to_s
puts "my_eval_count = " + my_eval_count.to_s
