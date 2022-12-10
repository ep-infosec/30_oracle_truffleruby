<!-- Generated by spec/truffle/interop/special_forms_spec.rb -->

# Implicit Polyglot API

In the documentation below:
* `name` is a `String` or `Symbol`.
* `index` is an `Integer`.

Format: `Ruby code` sends `InteropLibrary message`

- `foreign_object[key]` sends `readHashValue(foreign_object, key)` if `hasHashEntries(foreign_object)`
- `foreign_object[name]` sends `readMember(foreign_object, name)`
- `foreign_object[index]` sends `readArrayElement(foreign_object, index)`
- `foreign_object[key] = value` sends `writeHashEntry(foreign_object, key)` if `hasHashEntries(foreign_object)`
- `foreign_object[name] = value` sends `writeMember(foreign_object, name, value)`
- `foreign_object[index] = value` sends `writeArrayElement(foreign_object, index, value)`
- `foreign_object.name = value` sends `writeMember(foreign_object, name, value)`
- `foreign_object.name = *arguments` sends `writeMember(foreign_object, name, arguments)`
- `foreign_object.delete(key)` sends `removeHashEntry(foreign_object, key)` if `hasHashEntries(foreign_object)`
- `foreign_object.delete(name)` sends `removeMember(foreign_object, name)`
- `foreign_object.delete(index)` sends `removeArrayElement(foreign_object, index)`
- `foreign_object.call(*arguments)` sends `execute(foreign_object, *arguments)`
- `foreign_object.nil?` sends `isNull(foreign_object)`
- `foreign_object.size` sends `getArraySize(foreign_object)`
- `foreign_object.instance_variables` sends `getMembers(foreign_object)` and returns readable non-invocable members
- `foreign_object.methods` sends `getMembers(foreign_object)` and returns invocable members merged with available Ruby methods
- `foreign_object.method_name` sends `invokeMember(foreign_object, method_name)` if member is invocable
- `foreign_object.method_name` sends `readMember(foreign_object, method_name)` if member is readable but not invocable
- `foreign_object.method_name` sends `readMember(foreign_object, method_name)` and raises if member is neither invocable nor readable
- `foreign_object.method_name(*arguments)` sends `invokeMember(foreign_object, method_name, *arguments)`
- `foreign_object.method_name(*arguments, &block)` sends `invokeMember(foreign_object, method_name, *arguments, block)`
- `foreign_object.new(*arguments)` sends `instantiate(foreign_object, *arguments)`
- `foreign_object.inspect` returns a Ruby-style `#inspect` string showing members, array elements, etc
- `foreign_object.to_s` sends `asTruffleString(foreign_object)` when `isString(foreign_object)` is true
- `foreign_object.to_s` sends `toDisplayString(foreign_object)` otherwise
- `foreign_object.to_str` sends `asTruffleString(foreign_object)` when `isString(foreign_object)` is true
- `foreign_object.to_str` raises `NameError` otherwise
- `foreign_object.to_a` converts to a Ruby `Array` with `Truffle::Interop.to_array(foreign_object)`
- `foreign_object.to_ary` converts to a Ruby `Array` with `Truffle::Interop.to_array(foreign_object)`
- `foreign_object.to_f` tries to converts to a Ruby `Float` using `asDouble()` and `(double) asLong()` or raises `NameError`
- `foreign_object.to_i` tries to converts to a Ruby `Integer` using `asInt()` and `asLong()` or raises `NameError`
- `foreign_object.equal?(other)` sends `isIdentical(foreign_object, other)`
- `foreign_object.eql?(other)` sends `isIdentical(foreign_object, other)`
- `foreign_object.object_id` sends `identityHashCode(foreign_object)` when `hasIdentity()` is true (which might not be unique)
- `foreign_object.object_id` uses `System.identityHashCode()` otherwise (which might not be unique)
- `foreign_object.__id__` sends `identityHashCode(foreign_object)` when `hasIdentity()` is true (which might not be unique)
- `foreign_object.__id__` uses `System.identityHashCode()` otherwise (which might not be unique)
- `foreign_object.hash` sends `identityHashCode(foreign_object)` when `hasIdentity()` is true (which might not be unique)
- `foreign_object.hash` uses `System.identityHashCode()` otherwise (which might not be unique)
- `foreign_object.map` and other `Enumerable` methods work for foreign arrays
- `foreign_object.map` and other `Enumerable` methods work for foreign iterables (`hasIterator()`)

Use `.respond_to?` for calling `InteropLibrary` predicates:
- `foreign_object.respond_to?(:to_str)` sends `isString(foreign_object)`
- `foreign_object.respond_to?(:to_a)` sends `hasArrayElements(foreign_object)`
- `foreign_object.respond_to?(:to_ary)` sends `hasArrayElements(foreign_object)`
- `foreign_object.respond_to?(:to_f)` sends `fitsInDouble()`
- `foreign_object.respond_to?(:to_i)` sends `fitsInLong()`
- `foreign_object.respond_to?(:size)` sends `hasArrayElements(foreign_object)`
- `foreign_object.respond_to?(:call)` sends `isExecutable(foreign_object)`
- `foreign_object.respond_to?(:new)` sends `isInstantiable(foreign_object)`