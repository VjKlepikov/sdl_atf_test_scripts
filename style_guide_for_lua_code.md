# Style guide for Lua code
## Introduction
This document gives coding conventions and some programming recommendations for the Lua code.
## Code lay-out
### Indentation
* Use 2 spaces for indentation
```
-- bad
function guide()
∙∙∙∙local name
end

-- bad
function guide()
∙local name
end

-- good
function guide()
∙∙local name
end
```
* Use indenting and line breaks to clarify the logical structure of your code.
* Use indenting and line breaks to clarify the logical structure of your code.
* Expressions which nest multiple levels of parentheses or similar structures may begin a new indenting level with each nesting level
* Avoid vertical alignment in all cases except cases described in Maximum Line Length section.
* The closing braces/bracket/parenthesis on multi-line constructs may either the last line of list, as in:
```
my_list = {
  1, 2, 3,
  4, 5, 6}

result = someFunctionThatTakesArguments(
  'a', 'b', 'c',
  'd', 'e', 'f')
```
or it may be in next line of the multi-line construct, as in:
```
my_list = {
  1, 2, 3,
  4, 5, 6,
  }

result = someFunctionThatTakesArguments(
  'a', 'b', 'c',
  'd', 'e', 'f',
  )
```
### Maximum Line Length
* Limit the length of a single line to 79 characters + newline  character
* Indent lines if they overflow past the limit
```
-- bad
if test < 1 and do_complicated_function(test) == false or seven == 8 and nine == 10 then doOtherComplicatedFunction(); return false end

-- good
if test < 1 and do_complicated_function(test) == false or
    seven == 8 and nine == 10 then
  doOtherComplicatedFunction()
  return false
end
```
* Continuation lines should align wrapped elements either vertically using Lua's implicit line joining inside parentheses, brackets and braces, or using a hanging indent.
When using a hanging indent the following should be considered; there should be no arguments on the first line and further indentation should be used to clearly distinguish itself as a continuation line.
```
-- good
-- Aligned with opening delimiter.
foo = longFunctionName(var_one, var_two,
                       var_three, var_four)

-- More indentation included to distinguish this from the rest.
function longFunctionName(
        var_one, var_two, var_three,
        var_four)
  print(var_one)
end

-- Hanging indents should add a level.
foo = longFunctionName(
    var_one, var_two,
    var_three, var_four)

-- bad
-- Arguments on first line forbidden when not using vertical alignment.
foo = longFunctionName(var_one, var_two,
    var_three, var_four)

-- Further indentation required as indentation is not distinguishable.
function longFunctionName(
  var_one, var_two, var_three,
  var_four)
  print(var_one)
end
```
* Add line break before a operator in multi-line construct
```
-- bad: operators sit far away from their operands
income = gross_wages +
         taxable_interest +
         (dividends - qualified_dividends) -
         ira_deduction -
         student_loan_interest

-- good: easy to match operators with operands
income = gross_wages
         + taxable_interest
         + (dividends - qualified_dividends)
         - ira_deduction
         - student_loan_interest
```
* Leading commas aren't okay. An ending comma on the last item is okay but discouraged.
```
-- bad
local thing = {
  once = 1
, upon = 2
, aTime = 3
}

-- good
local thing = {
  once = 1,
  upon = 2,
  aTime = 3
}

-- ok
local thing = {
  once = 1,
  upon = 2,
  aTime = 3,
}
```
### Whitespace
* Braces and parentheses are placed on the same line as the start of the function and tables.  (1TBS style)
* Avoid trailing whitespace anywhere. Because it's usually invisible, it can be confusing.
* Always surround binary operators with a single space on either side:
	- assignment ( = ),
	- comparisons ( ==, < , >, ~=, <=, >=),
	- booleans ( and, or, not ),
	- arithmetics and etc.
```
-- bad
local thing=1
thing = thing-1
thing = thing*1
thing = 'string'..'s'

-- good
local thing = 1
thing = thing - 1
thing = thing * 1
thing = 'string' .. 's'
```
* Use one space after commas.
```
-- bad
local thing = {1,2,3}
thing = {1 , 2 , 3}
thing = {1 ,2 ,3}

-- good
local thing = {1, 2, 3}
```
* Avoid extraneous whitespace in the following situations:
1. Immediately inside parentheses, brackets or braces.
```
-- bad
spam( ham[ 1 ], { eggs = 2 } )

-- good
spam(ham[1], {eggs = 2})
```
2. Immediately before a comma and semicolon
```
-- bad
if x == 4 then
 print x , y ; x , y = y , x
end

-- good
if x == 4 then
  print x, y; x, y = y, x
end
```
3. Immediately before the open parenthesis that starts the argument list of a function for he call and function definition
```
-- bad
spam (1)

function spam (text)
  -- ...stuff...
end

-- good
spam(1)

function spam (text)
  -- ...stuff...
end
```
4. Immediately before the open brackets that starts an indexing
```
-- bad
dct ['key'] = lst [index]

-- good
dct['key'] = lst[index]
```
5. More than one space around an assignment (or other) operator to align it with another
```
-- bad
x             = 1
y             = 2
long_variable = 3

-- good
x = 1
y = 2
long_variable = 3
```
Example:
```
-- Do this
function foo(param1, param2)
  local x = {a = "this", b = "that"}
  local y = bar(1, 2, 3)
  x[6] = 11
end

-- and not
function foo ( param1, param2 )
  local x={ a="this" , b="that" }
  local y=bar ( 1 , 2,       3 )
  x[ 6 ] = 11
end
```
### Blank Lines
* All files should have a newline character at the end.
It makes sense since all other lines have a newline character at the end.
It makes passing data around in non-binary formats (like diffs) easier.
Command-line tools like cat and wc don't handle files without one well (or at least, not in the way that 	one would like or expect).
* Blank lines to split groups of code further into subgroups.
* Surround top-level function definitions in module with one blank line.
* Extra blank lines may be used (sparingly) to separate groups of related functions.
* Use blank lines in functions, sparingly, to indicate logical sections.
### Source File Encoding
* All files should be encoded with UTF-8 without a Byte Order Mark.
* All files should use Unix-style newlines (single LF character, not a CR+LF combination).
## Comments and code documentation
* For documentation of code use [Ldoc](https://stevedonovan.github.io/ldoc/manual/doc.md.html) tool and Lua comments
* A comment starts anywhere with a double hyphen `--` and runs until the end of the line.
* Block comments, which start with `--[[` and run until the corresponding `]]`
* Comments should be complete sentences. If a comment is a phrase or sentence, its first word should be capitalized, unless it is an identifier that begins with a lower case letter (never alter the case of identifiers!).
* You may add variable description. Especially with global variables, you may wish to include a description of what they contain, how wide they are scopes, and what units are used for values held in them.
* You may add comment  to "end" statement. Because "end" is a terminator for many different constructs, it can help the reader (especially in a large block) if a comment is used to clarify which construct is being terminated
```
for i,v in ipairs(t) do
  if type(v) == "string" then
    -- ...lots of code here...
  end -- if string
end -- for each t
```
* Use a space after --
```
-- bad
return nil  --not found

-- good
return nil  -- not found
```
* Use inline comments sparingly. Inline comments are unnecessary and in fact distracting if they state the obvious.
	Don't do this:
  `x = x + 1   -- Increment x`
  but sometimes, this is useful:
  `x = x + 1    -- Compensate for border`
* Write docstrings for all public modules, functions, tables, and methods.
Docstrings are not necessary for non-public functions, but you should have a comment that describes what it does.
* Lua coders from non-English speaking countries: please write your comments in English, unless you are 120% sure that the code will never be read by people who don't speak your language.
* Assume your readers already know Lua so try not to teach that to them (it would show that you're really trying to teach it to yourself). But don't tell them that the code "speaks for itself" either because it doesn't.
* Take time to document the tricky parts of the code.
* Comments that contradict the code are worse than no comments. Always make a priority of keeping the comments up-to-date when the code changes!
## Naming Conventions
* Variable names with larger scope should be more descriptive than those with smaller scope
* Avoid single letter names. Be descriptive with your naming. You can get away with single-letter names when they are variables in loops.
```
-- bad
local function q()
  -- ...stuff...
end

-- good
local function query()
  -- ..stuff..
end
```
* Never use the characters 'l' (lowercase letter el), 'O' (uppercase letter oh), or 'I' (uppercase letter eye) as single character variable names. In some fonts, these characters are indistinguishable from the numerals one and zero. When tempted to use 'l', use 'L' instead.
* The following words are reserved; we cannot use them as identifiers:
```
and      break     do     else      elseif    end      false
for      function  if     in        local     nil       not
repeat   return    then   true      until     while     or
```
* In the standard library, function names consisting of multiple words are simply put together (e.g. setmetatable).
* Avoid identifiers starting with an underscore followed by one or more uppercase letters. Names starting with an underscore followed by uppercase letters (such as _VERSION) are reserved for internal global variables used by Lua.
* Constants are usually defined on a module level and written in all capital letters with underscores separating words
```
-- bad
max_overflow = 1000
Total = “Total amount of requests ”

-- good
MAX_OVERFLOW = 1000
TOTAL = “Total amount of requests ”
```
* The variable consisting of only an underscore "_" is commonly used as a placeholder when you want to ignore the variable.
```
-- bad
for tmp, name in pairs(names) do
  -- ...stuff...
end

-- good
for _, name in pairs(names) do
  -- ...stuff...
end
```
* Use snake_case when naming primitives, objects and instances.
```
-- bad
local OBJEcttsssss = {}
local thisIsMyObject = {}
local this-is-my-object = {}

-- good
local this_is_my_object = {}
```
* Use camelCase when naming functions.
```
-- bad
local function do_that_thing()
  -- ...stuff...
end

-- good
local function doThatThing()
  -- ...stuff...
end
```
* When tables have functions, use “self” when referring to itself, or use “:” syntactic sugar
```
-- bad
local player = {}

function player.attack(this, target)
  this.target =  target
end

-- good
local player = {}

function player.attack(self, target)
  self.target =  target
end

-- good
local player = {}

function player:attack(target)
  self.target =  target
end
```
* Always use “self” for the first argument to instance methods.
* All function names should begin with a verb unless they can't, like "getLength()" instead of "length"
* Prefix Boolean values used as predicates with “is”, such as “is_directory” rather than directory (which might store a directory object itself).
* Use is or has for boolean-returning functions.
```
-- bad
local function evil(alignment)
  return alignment < 100
end

local function getCertificate(alignment)
  return is_certificate     -- boolean value
end

-- good
local function isEvil(alignment)
  return alignment < 100
end

local function hasCertificate(alignment)
  return is_certificate     -- boolean value
end
```
* Use PascalCase for factories/classes. If so, acronyms (e.g. XML) might only uppercase the first letter (XmlDocument).
```
-- bad
local player = require('player')
local me = player('Jack')

-- good
local Player = require('player')
local me = Player('Jack')
```
* Modules should have short, all-lowercase nouns names. Underscores can be used in the module name if it improves readability. Module names should not contain colons, or any other punctuation
```
-- bad
local Player = require('Player')

-- good
local Player = require('player')
```
* The file should be named like the module.
```
-- thing.lua
local thing = {}

local meta = {
  __call = function(self, key, vars)
    print key
  end
}

return setmetatable(thing, meta)
```
* The above followed somewhat the Java convention of the package "bankaccount" being in all lowercase, while the class BankAccount being in PascalCase and objects being lower_case. Notice the advantage. The classes are easy to spot and differentiate from instantiations of classes (i.e. objects), which are lower-case. If you spot something like BankAccount:add(1), it is almost certainly an error since : is a method call on an object, but you'll notice that BankAccount is obviously a class due to the case convention.
* Take time to find good names. The process of naming makes you face the horrible fact that you have no idea what the hell you're doing.
## Programming Recommendations
### General
* Use locals rather than globals whenever possible. Globals have larger scopes and lifetimes and therefore increase coupling and complexity. Don't pollute the environment. In Lua, access to locals is also faster than globals since globals require a table lookup at run-time, while locals exist as registers.
```
-- bad
power = "SuperPower"

-- good
local power = "SuperPower"
```
* Pretty much never put multiple statements on one line
```
-- bad
local whatever = 'sure';
a = 1; b = 2

-- good
local whatever = 'sure'
a = 1
b = 2
```
* Single line blocks are okay only for small statements. It's okay to put an if/for/while with a small body on the same line, never do this for multi-clause statements.
```
-- good
if test then return false end

-- good
if test then
  return false
end

-- bad
if test < 1 and do_complicated_function(test) == false or seven == 8 and nine == 10 then do_other_complicated_function()end
```
* Assign variables closer to its use where possible. This makes it easier to understand the code.
```
-- bad
local bad = function()
  local name = getName()
  test()
  print('doing stuff..')
  -- ..other stuff..
  if name == 'test' then
    return false
  end
  return name
end

-- good
local function good()
  test()
  print('doing stuff..')
  -- ..other stuff..
  local name = getName()
  if name == 'test' then
    return false
  end
  return name
end
```
* Avoid using the debug library unless necessary, especially if trusted code is being run.
### Strings
* In Lua, single-quoted strings and double-quoted strings are the same. When a string contains single or double quote characters, however, use the other one to avoid backslashes in the string. It improves readability.
* Strings longer than 79 characters should be written across multiple lines using concatenation. This allows you to indent nicely.
```
-- bad
local errorMessage = 'This is a super long error that was thrown because of Batman. When you stop to think about how Batman had anything to do with this, you would get nowhere fast.'

-- bad
local errorMessage = 'This is a super long error that \
was thrown because of Batman. \
When you stop to think about \
how Batman had anything to do \
with this, you would get nowhere \
fast.'

-- bad
local errorMessage = [[This is a super long error that
  was thrown because of Batman.
  When you stop to think about
  how Batman had anything to do
  with this, you would get nowhere
  fast.]]

-- good
local errorMessage = 'This is a super long error that ' ..
  'was thrown because of Batman. ' ..
  'When you stop to think about ' ..
  'how Batman had anything to do ' ..
  'with this, you would get nowhere ' ..
  'fast.'
```
### Type cast
* Use tostring() for strings if you need to cast without string concatenation.
```
-- bad
local totalScore = review_score .. ''

-- good
local total_score = tostring(review_score)
```
* Use tonumber() for Numbers.
```
local input_value = '4'

-- bad
local val = input_value * 1

-- good
local val = tonumber(input_value)
```
* To test whether a variable is `not nil` in a conditional, it is terser to just write the variable name rather than explicitly compare against nil.
```
-- ok
local data
if data == nil then
  -- ..other stuff..
end

-- good
if data then
  -- ..other stuff..
end
```
However, if the variable tested can ever contain false as well, then you will need to be explicit if the two conditions must be differentiated: line == nil v.s. line == false.
### Functions
* Each function should perform what's described as a single logical operation. If you write a function that formats a string AND outputs the result, sooner or later you'll need to format the string and then add it on to the end of another string and your original function won't do the job for you.
* Prefer lots of small functions to large, complex functions.
* Try to keep the functional behavior side-effect free.
* Prefer function syntax over variable syntax. This helps differentiate between named and anonymous functions.
```
-- bad
local nope = function(name, options)
  -- ...stuff...
end

-- good
local function yup(name, options)
  -- ...stuff...
end
```
* Prefer defaults to else statements where it makes sense. This results in less complex and safer code at the expense of variable reassignment, so situations may differ.
```
-- bad
local function fullName(first, last)
  local name

  if first and last then
    name = first .. ' ' .. last
  else
    name = 'John Smith'
  end

  return name
end

-- good
local function fullName(first, last)
  local name = 'John Smith'

  if first and last then
    name = first .. ' ' .. last
  end

  return name
end
```
* Perform validation early and return as early as possible.
```
-- bad
local function isGoodName(name, options, arg)
  local is_good = #name > 3
  is_good = is_good and #name < 30
  -- ...stuff...
  return  is_good
end

-- good
local function isGoodName(name, options, args)
  if #name < 3 or #name > 30 then return false end
  -- ...stuff...
  return true
end
```
* Be consistent in return statements. Either all return statements in a function should return an expression, or none of them should. If any return statement returns an expression, any return statements where no value is returned should explicitly state this as return nil , and an explicit return statement should be present at the end of the function (if reachable).
```
-- bad
function foo(x)
  if x >= 0 then
    return math.sqrt(x)
  end
end

function bar(x)
  if x < 0 then
    return
  end
  return math.sqrt(x)
end

-- good
function foo(x)
  if x >= 0 then
    return math.sqrt(x)
  end
  return nil
end

function bar(x)
  if x < 0 then
    return nil
  end
  return math.sqrt(x)
end
```
### Tables
* Use the constructor syntax for table property creation where possible.
```
-- bad
local player = {}
player.name = 'Jack'
player.class = 'Rogue'

-- good
local player = {
  name = 'Jack',
  class = 'Rogue'
}
```
* Define functions externally to table definition.
```
-- bad
local player = {
  attack = function()
  -- ...stuff...
  end
}

-- good
local function attack()
  -- ...stuff...
end

local player = {
  attack = attack
}
```
* Use dot notation when accessing known properties.
```
local luke = {
  jedi = true,
  age = 28
}

-- bad
local isJedi = luke['jedi']

-- good
local isJedi = luke.jedi
```
* Use subscript notation `[]` when accessing properties with a variable or if using a table as a list.
```
-- good
local luke = {
  jedi = true,
  age = 28
}

local function getProp(prop)
  return luke[prop]
end

local isJedi = getProp('jedi')
```
* Consider `nil` properties when selecting lengths. A good idea is to store an n property on lists that contain the length
```
-- nils don't count
local list = {}
list[0] = nil
list[1] = 'item'

print(#list) -- 0
print(select('#', list)) -1
```
### Modules
* Note that modules are loaded as singletons and therefore should usually be factories (a function returning a new instance of a table) unless static (like utility libraries.)
* The module should not use the global namespace for anything ever. The module should be a closure.
* The module should return a table or function.
* Requires are always put at the top of the file, just after any module comments and docstrings, and before module globals and constants.
* Keep _G clean, don't use module(). Use one of these patterns instead:
```
local M = {}
function M.foo()
   ...
end

function M.bar()
  -- ...stuff...
end

return M
```
Or
```
local function foo()
  -- ...stuff...
end
local function bar()
   -- ...stuff...
end

return {
   foo = foo,
   bar = bar,
}
```
## References
* [lua-users.org](http://lua-users.org/wiki/LuaStyleGuide)
* [www.mediawiki.org](https://www.mediawiki.org/wiki/Manual:Coding_conventions/Lua)
* [luapower.com](https://luapower.com/coding-style)
* [Wikipedia_talk](https://en.wikipedia.org/wiki/Wikipedia_talk:Lua_style_guide)
* [www.wellho.net](http://www.wellho.net/mouth/3685_Programming-Standards-in-Lua.html)
* [wiki.beamng.com](http://wiki.beamng.com/Lua_Code_Style_Conventions)
* [www.python.org](https://www.python.org/dev/peps/pep-0008)
* [github.com/Olivine-Labs](https://github.com/Olivine-Labs/lua-style-guide)
* [dev.minetest.net](http://dev.minetest.net/Lua_code_style_guidelines)

* [LDoc](https://stevedonovan.github.io/ldoc/manual/doc.md.html)