'use strict'

{Nothing, Just} = require 'coffee-monad'
################################################################################
# pattern => [quality factor in {0..1}, regex]
patternsList =
   [ [ 0.2 ,/^\d+$/]                  # all digits
   , [ 0.2 ,/^[a-z]+\d$/]             # all lower 1 digit
   , [ 0.2 ,/^[A-Z]+\d$/]             # all upper 1 digit
   , [ 0.4 ,/^[a-zA-Z]+\d$/]          # all letters 1 digit
   , [ 0.4 ,/^[a-z]+\d+$/]            # all lower then digits
   , [ 0.2 ,/^[a-z]+$/]               # all lower
   , [ 0.2 ,/^[A-Z]+$/]               # all upper
   , [ 0.2 ,/^[A-Z][a-z]+$/]          # 1 upper all lower
   , [ 0.2 ,/^[A-Z][a-z]+\d$/]        # 1 upper, lower, 1 digit
   , [ 0.4 ,/^[A-Z][a-z]+\d+$/]       # 1 upper, lower, digits
   , [ 0.2 ,/^[a-z]+[._!\- @*#]$/]    # all lower 1 special
   , [ 0.2 ,/^[A-Z]+[._!\- @*#]$/]    # all upper 1 special
   , [ 0.4 ,/^[a-zA-Z]+[._!\- @*#]$/] # all letters 1 special
   , [ 0.2 ,/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$/]  # email
# not clear, [ 0.5 ,/^[a-z\-ZA-Z0-9.-]+$/]    # web address
   , [ 1   ,/^.*$/]    # anything
   ]
################################################################################

Math.log2 = (x) -> Math.log(x) / Math.LN2
hasDigits      = (str) -> /[0-9]/.test str
hasLowerCase   = (str) -> /[a-z]/.test str
hasUpperCase   = (str) -> /[A-Z]/.test str
hasPunctuation = (str) -> /[-!$%^&*()_+|~=`{}\[\]:";'<>?@,.\/]/.test str
base = (str) ->
  tuples = [[10, hasDigits(str)]
           ,[26, hasLowerCase(str)]
           ,[26, hasUpperCase(str)]
           ,[31, hasPunctuation(str)]]
  bases = (t[0] for t in tuples when t[1])
  b = bases.reduce(((t, s) -> t + s),0)
  if b is 0 then 1 else b

maybePassword = (str) ->
  if str is "" or !str? or (typeof str) isnt 'string'
  then Nothing
  else Just str

# metric 1
entropy = (str) ->
  maybePassword(str).bind (pw)->
    Just Math.log2 Math.pow(base(pw),pw.length)

# metric 2
quality = (str, patterns) ->
  Math.min.apply @, (p[0] for p in patterns when p[1].test str)


factor = (str, patterns) ->
  (entropy str).bind (e) ->
    Just (e*quality(str, patterns))

avg = (str, patterns) ->
  qty = quality str, patterns
  ent = entropy str, patterns
  switch qty
    when 1 then ent
    else ent.bind (e)-> Just (qty*100+e) / 2.0

################################################################################
# "Public function"

score = (str, metricMixer) ->
  s = metricMixer str, patternsList
  switch s
    when Nothing then 0
    else (if s.val > 100 then 100 else s.val)
