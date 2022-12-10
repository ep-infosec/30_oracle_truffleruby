# Copyright (c) 2018, 2021 Oracle and/or its affiliates. All rights reserved. This
# code is released under a tri EPL/GPL/LGPL license. You can use it,
# redistribute it and/or modify it under the terms of the:
#
# Eclipse Public License version 2.0, or
# GNU General Public License version 2, or
# GNU Lesser General Public License version 2.1.

require_relative '../../ruby/spec_helper'
require_relative 'fixtures/classes.rb'

output = [<<HEADER]
<!-- Generated by spec/truffle/interop/special_forms_spec.rb -->

# Implicit Polyglot API

In the documentation below:
* `name` is a `String` or `Symbol`.
* `index` is an `Integer`.

Format: `Ruby code` sends `InteropLibrary message`

HEADER

describe "Interop special forms" do

  after :all do
    file = File.expand_path('../../../doc/contributor/interop_implicit_api.md', __dir__)
    if File.exist?(file) && File.writable?(file)
      File.open(file, 'w') do |out|
        output.each do |line|
          out.puts line
        end
      end
    end
  end

  doc = -> form, result do
    string = "`foreign_object#{form}` #{result}"
    output << "- #{string}"
    string
  end

  description = -> form, method, arguments = [], condition = nil do
    result = "sends `#{method}(#{[:foreign_object, *arguments].join(', ')})`"
    result += " #{condition}" if condition
    doc[form, result]
  end

  proxy = -> obj {
    logger = TruffleInteropSpecs::Logger.new
    return Truffle::Interop.proxy_foreign_object(obj, logger), obj, logger
  }

  # TODO (pitr-ch 23-Mar-2020): test what method has a precedence, special or the invokable-member on the foreign object
  # TODO (pitr-ch 23-Mar-2020): test left side operator conversion with asBoolean, asString, etc.

  it description['[key]', :readHashValue, [:key], 'if `hasHashEntries(foreign_object)`'] do
    pfo, h, l = proxy[TruffleInteropSpecs::PolyglotHash.new]
    pfo[:foo].should == nil
    l.log.should include(['readHashValueOrDefault', :foo, nil]) # readHashValue
    h.log.should include([:polyglot_read_hash_entry, :foo])

    pfo, h, l = proxy[TruffleInteropSpecs::PolyglotHash.new]
    pfo[:foo] = 42
    pfo[:foo].should == 42
    l.log.should include(['readHashValueOrDefault', :foo, nil]) # readHashValue
    h.log.should include([:polyglot_read_hash_entry, :foo])
  end

  it description['[name]', :readMember, [:name]] do
    pfo, pm, l = proxy[TruffleInteropSpecs::PolyglotMember.new]
    -> { pfo[:foo] }.should raise_error(NameError)
    -> { pfo['bar'] }.should raise_error(NameError)
    l.log.should include(['readMember', 'foo'])
    l.log.should include(['readMember', 'bar'])
    pm.log.should include([:polyglot_read_member, 'foo'])
    pm.log.should include([:polyglot_read_member, 'bar'])
  end

  it description['[index]', :readArrayElement, [:index]] do
    pfo, pa, l  = proxy[TruffleInteropSpecs::PolyglotArray.new]
    pfo[0].should == nil
    l.log.should include(['getArraySize'])
    pa.log.should include([:polyglot_array_size])
  end

  it description['[key] = value', :writeHashEntry, [:key], 'if `hasHashEntries(foreign_object)`'] do
    pfo, h, l = proxy[TruffleInteropSpecs::PolyglotHash.new]
    pfo[:foo] = 42
    l.log.should include(['writeHashEntry', :foo, 42])
    h.log.should include([:polyglot_write_hash_entry, :foo, 42])
  end

  it description['[name] = value', :writeMember, [:name, :value]] do
    pfo, pm, l = proxy[TruffleInteropSpecs::PolyglotMember.new]
    pfo[:foo] = 1
    pfo['bar'] = 2
    l.log.should include(['writeMember', 'foo', 1])
    l.log.should include(['writeMember', 'bar', 2])
    pm.log.should include([:polyglot_write_member, "foo", 1])
    pm.log.should include([:polyglot_write_member, "bar", 2])
  end

  it description['[index] = value', :writeArrayElement, [:index, :value]] do
    pfo, pa, l = proxy[TruffleInteropSpecs::PolyglotArray.new]
    pfo[0] = 1
    l.log.should include(['writeArrayElement', 0, 1])
    pa.log.should include([:polyglot_write_array_element, 0, 1])
  end

  it description['.name = value', :writeMember, [:name, :value]] do
    pfo, pm, l = proxy[TruffleInteropSpecs::PolyglotMember.new]
    pfo.foo = :bar
    l.log.should include(['writeMember', 'foo', :bar])
    pm.log.should include([:polyglot_write_member, "foo", :bar])
  end

  it description['.name = *arguments', :writeMember, [:name, 'arguments']] do
    pfo, pm, l = proxy[TruffleInteropSpecs::PolyglotMember.new]
    pfo.foo = :bar, :baz
    l.log.should include(['writeMember','foo', [:bar, :baz]])
    pm.log.should include([:polyglot_write_member, "foo", [:bar, :baz]])
  end

  it "raises an argument error if an assignment method is called with more than 1 argument" do
    pfo, _, l = proxy[TruffleInteropSpecs::PolyglotMember.new]
    l.log.should_not include(['writeMember', :bar, :baz])
    -> { pfo.__send__(:foo=, :bar, :baz) }.should raise_error(ArgumentError)
  end

  it description['.delete(key)', :removeHashEntry, [:key], 'if `hasHashEntries(foreign_object)`'] do
    pfo, h, l = proxy[TruffleInteropSpecs::PolyglotHash.new]
    pfo[:foo] = 42
    pfo.delete(:foo).should == 42
    l.log.should include(['removeHashEntry', :foo])
    h.log.should include([:polyglot_remove_hash_entry, :foo])
  end

  it description['.delete(name)', :removeMember, [:name]] do
    pfo, pm, l = proxy[TruffleInteropSpecs::PolyglotMember.new]
    -> { pfo.delete :foo }.should raise_error(NameError)
    l.log.should include(['removeMember', 'foo'])
    pm.log.should include([:polyglot_remove_member, 'foo'])
  end

  it description['.delete(index)', :removeArrayElement, [:index]] do
    pfo, pa, l = proxy[TruffleInteropSpecs::PolyglotArray.new]
    -> { pfo.delete 14 }.should raise_error(IndexError)
    l.log.should include(['removeArrayElement', 14])
    pa.log.should include([:polyglot_remove_array_element, 14])
  end

  it description['.call(*arguments)', :execute, ['*arguments']] do
    pfo, _, l = proxy[-> *x { x }]
    pfo.call(1, 2, 3)
    l.log.should include(['execute', 1, 2, 3])
  end

  it description['.nil?', :isNull] do
    pfo, _, l = proxy[Object.new]
    pfo.nil?
    l.log.should include(['isNull'])
  end

  it description['.size', :getArraySize] do
    # Method size does not exist for a foreign object
    pfo, _, _l = proxy[Object.new]
    -> { pfo.size }.should raise_error(NameError)
  end

  it description['.instance_variables', :getMembers, [], 'and returns readable non-invocable members'] do
    pfo, _, l = proxy[Truffle::Debug.foreign_object_with_members]
    pfo.instance_variables.should == [:a, :b, :c]
    l.log.should include(['getMembers', false])
  end

  it description['.methods', :getMembers, [], 'and returns invocable members merged with available Ruby methods'] do
    pfo, _, l = proxy[Truffle::Debug.foreign_object_with_members]
    methods = pfo.methods
    l.log.should include(['getMembers', false])
    methods.last(2).should == [:method1, :method2]
    methods.should include(*Object.public_instance_methods)
  end

  it description['.method_name', :invokeMember, ['method_name'], 'if member is invocable'] do
    pfo, _, l = proxy[Class.new { def foo; 3; end }.new]
    pfo.foo
    l.log.should include(["isMemberInvocable", "foo"])
    l.log.should include(["invokeMember", "foo"])
  end

  it description['.method_name', :readMember, ['method_name'], 'if member is readable but not invocable'] do
    pfo, _, l = proxy[TruffleInteropSpecs::PolyglotMember.new]
    pfo.foo = :bar
    pfo.foo
    l.log.should include(["isMemberInvocable", "foo"])
    l.log.should include(["readMember", "foo"])
  end

  it description['.method_name', :readMember, ['method_name'], 'and raises if member is neither invocable nor readable'] do
    pfo, _, l = proxy[Object.new]
    -> { pfo.foo }.should raise_error(NameError)
    l.log.should include(["isMemberInvocable", "foo"])
    l.log.should include(["readMember", "foo"])
  end

  it description['.method_name(*arguments)', :invokeMember, ['method_name', '*arguments']] do
    pfo, _, l = proxy[Object.new]
    -> { pfo.bar(1, 2, 3) }.should raise_error(NoMethodError)
    l.log.should include(["invokeMember", "bar", 1, 2, 3])
  end

  it description['.method_name(*arguments, &block)', :invokeMember, ['method_name', '*arguments, block']] do
    pfo, pm, l = proxy[TruffleInteropSpecs::PolyglotMember.new]
    block = Proc.new { }
    pfo.foo = -> *_ { 1 }
    pfo.foo(1, 2, 3, &block)
    l.log.should include(["invokeMember", "foo", 1, 2, 3, block])
    messages = pm.log
    messages.should include([:polyglot_invoke_member, "foo", 1, 2, 3, block])
  end

  it description['.new(*arguments)', :instantiate, ['*arguments']] do
    klass = Class.new
    pfo, _, l = proxy[klass]
    pfo.new.should.is_a?(klass)
    l.log.should include(["instantiate"])
  end

  it doc['.inspect', 'returns a Ruby-style `#inspect` string showing members, array elements, etc'] do
    # More detailed specs in spec/truffle/interop/foreign_inspect_to_s_spec.rb
    Truffle::Debug.foreign_object.inspect.should =~ /\A#<Polyglot::ForeignObject:0x\h+>\z/
  end

  it description['.to_s', :asTruffleString, [], 'when `isString(foreign_object)` is true'] do
    pfo, _, l = proxy['asTruffleString contents']
    pfo.to_s.should == "asTruffleString contents"
    l.log.should include(["asTruffleString"])
  end

  it description['.to_s', :toDisplayString, [], 'otherwise'] do
    pfo, _, l = proxy[Object.new]
    pfo.to_s
    l.log.should include(["toDisplayString", true])
  end

  it description['.to_str', :asTruffleString, [], 'when `isString(foreign_object)` is true'] do
    pfo, _, l = proxy["asTruffleString contents"]
    pfo.to_str.should == "asTruffleString contents"
    l.log.should include(["isString"])
    l.log.should include(["asTruffleString"])
  end

  it doc['.to_str', 'raises `NameError` otherwise'] do
    pfo, _, l = proxy[Object.new]
    -> { pfo.to_str }.should raise_error(NameError)
    l.log.should include(["isString"])
  end

  it doc['.to_a', 'converts to a Ruby `Array` with `Truffle::Interop.to_array(foreign_object)`'] do
    # method to_a does not exist for a foreign object
    pfo, _, _l = proxy[Object.new]
    -> { pfo.to_a }.should raise_error(NameError)
  end

  it doc['.to_ary', 'converts to a Ruby `Array` with `Truffle::Interop.to_array(foreign_object)`'] do
    # method to_a does not exist for a foreign object
    pfo, _, _l = proxy[Object.new]
    -> { pfo.to_a }.should raise_error(NameError)
  end

  it doc['.to_f', 'tries to converts to a Ruby `Float` using `asDouble()` and `(double) asLong()` or raises `NameError`'] do
    pfo, _, l = proxy[42]
    pfo.to_f.should.eql?(42.0)
    l.log.should include(["fitsInDouble"])
    l.log.should include(["asDouble"])

    does_not_fit_perfectly_in_double = (1 << 62) + 1
    pfo, _, l = proxy[does_not_fit_perfectly_in_double]
    pfo.to_f.should.eql?(does_not_fit_perfectly_in_double.to_f)
    l.log.should include(["fitsInDouble"])
    l.log.should include(["asLong"])

    pfo, _, l = proxy[Object.new]
    -> { pfo.to_f }.should raise_error(NameError, /to_f/)
    l.log.should include(["isNumber"])
  end

  it doc['.to_i', 'tries to converts to a Ruby `Integer` using `asInt()` and `asLong()` or raises `NameError`'] do
    pfo, _, l = proxy[42]
    pfo.to_i.should.eql?(42)
    l.log.should include(["fitsInInt"])
    l.log.should include(["asInt"])

    pfo, _, l = proxy[1 << 42]
    pfo.to_i.should.eql?(1 << 42)
    l.log.should include(["fitsInLong"])
    l.log.should include(["asLong"])

    pfo, _, l = proxy[Object.new]
    -> { pfo.to_i }.should raise_error(NameError, /to_i/)
    l.log.should include(["isNumber"])
  end

  it description['.equal?(other)', :isIdentical, [:other]] do
    pfo, _, l = proxy[Object.new]
    pfo.equal?(pfo).should == true
    l.log.should include(["isIdentical", pfo, :InteropLibrary])

    pfo, _, l = proxy[Object.new]
    other = Object.new
    pfo.equal?(other).should == false
    l.log.should include(["isIdentical", other, :InteropLibrary])
  end

  it description['.eql?(other)', :isIdentical, [:other]] do
    pfo, _, l = proxy[Object.new]
    pfo.eql?(pfo).should == true
    l.log.should include(["isIdentical", pfo, :InteropLibrary])

    pfo, _, l = proxy[Object.new]
    other = Object.new
    pfo.eql?(other).should == false
    l.log.should include(["isIdentical", other, :InteropLibrary])
  end

  it description['.object_id', :identityHashCode, [], 'when `hasIdentity()` is true (which might not be unique)'] do
    pfo, obj, l = proxy[Object.new]
    pfo.object_id.should == Truffle::Interop.identity_hash_code(obj)
    l.log.should include(["isIdentical", pfo, :InteropLibrary]) # hasIdentity()
    l.log.should include(["identityHashCode"])
  end

  it doc['.object_id', 'uses `System.identityHashCode()` otherwise (which might not be unique)'] do
    pfo, _, l = proxy[42] # primitives have no identity in InteropLibrary
    pfo.object_id.should be_kind_of(Integer)
    l.log.should include(["isIdenticalOrUndefined", 42]) # hasIdentity()
    l.log.should_not include(["identityHashCode"])
  end

  it description['.__id__', :identityHashCode, [], 'when `hasIdentity()` is true (which might not be unique)'] do
    pfo, obj, l = proxy[Object.new]
    pfo.__id__.should == Truffle::Interop.identity_hash_code(obj)
    l.log.should include(["isIdentical", pfo, :InteropLibrary]) # hasIdentity()
    l.log.should include(["identityHashCode"])
  end

  it doc['.__id__', 'uses `System.identityHashCode()` otherwise (which might not be unique)'] do
    pfo, _, l = proxy[42] # primitives have no identity in InteropLibrary
    pfo.__id__.should be_kind_of(Integer)
    l.log.should include(["isIdenticalOrUndefined", 42]) # hasIdentity()
    l.log.should_not include(["identityHashCode"])
  end

  it description['.hash', :identityHashCode, [], 'when `hasIdentity()` is true (which might not be unique)'] do
    pfo, obj, l = proxy[Object.new]
    pfo.hash.should == Truffle::Interop.identity_hash_code(obj)
    l.log.should include(["isIdentical", pfo, :InteropLibrary]) # hasIdentity()
    l.log.should include(["identityHashCode"])
  end

  it doc['.hash', 'uses `System.identityHashCode()` otherwise (which might not be unique)'] do
    pfo, _, l = proxy[42] # primitives have no identity in InteropLibrary
    pfo.hash.should be_kind_of(Integer)
    l.log.should include(["isIdenticalOrUndefined", 42]) # hasIdentity()
    l.log.should_not include(["identityHashCode"])
  end

  it doc['.map', 'and other `Enumerable` methods work for foreign arrays'] do
    array = Truffle::Debug.foreign_array
    array.map { _1 * 2 }.should == [2, 4, 6]
  end

  it doc['.map', 'and other `Enumerable` methods work for foreign iterables (`hasIterator()`)'] do
    iterable = Truffle::Debug.foreign_iterable
    iterable.map { _1 * 2 }.should == [2, 4, 6]
  end

  output << "\nUse `.respond_to?` for calling `InteropLibrary` predicates:\n"

  it description['.respond_to?(:to_str)', :isString] do
    pfo, _, l = proxy[Object.new]
    pfo.respond_to?(:to_str)
    l.log.should include(["isString"])
  end

  it description['.respond_to?(:to_a)', :hasArrayElements] do
    pfo, _, l = proxy[Object.new]
    pfo.respond_to?(:to_a)
    l.log.should include(["hasArrayElements"])
  end

  it description['.respond_to?(:to_ary)', :hasArrayElements] do
    pfo, _, l = proxy[Object.new]
    pfo.respond_to?(:to_ary)
    l.log.should include(["hasArrayElements"])
  end

  it doc['.respond_to?(:to_f)', 'sends `fitsInDouble()`'] do
    pfo, _, l = proxy[3.14]
    pfo.should.respond_to?(:to_f)
    l.log.should include(["fitsInDouble"])
  end

  it doc['.respond_to?(:to_i)', 'sends `fitsInLong()`'] do
    pfo, _, l = proxy[42]
    pfo.should.respond_to?(:to_i)
    l.log.should include(["fitsInLong"])
  end

  it description['.respond_to?(:size)', :hasArrayElements] do
    pfo, _, l = proxy[Object.new]
    pfo.respond_to?(:size)
    l.log.should include(["hasArrayElements"])
  end

  it description['.respond_to?(:call)', :isExecutable] do
    pfo, _, l = proxy[Object.new]
    pfo.respond_to?(:call)
    l.log.should include(["isExecutable"])
  end

  it description['.respond_to?(:new)', :isInstantiable] do
    pfo, _, l = proxy[Object.new]
    pfo.respond_to?(:new)
    l.log.should include(["isInstantiable"])
  end

  describe "#is_a?" do
    it "returns false for a non-Java foreign object and a Ruby class" do
      Truffle::Debug.foreign_object.is_a?(Hash).should be_false
    end

    guard -> { !TruffleRuby.native? } do
      it "returns false for Java null" do
        big_integer_class = Truffle::Interop.java_type("java.math.BigInteger")
        Truffle::Debug.java_null.is_a?(big_integer_class).should be_false
      end

      it "returns true for a directly matching Java object and class" do
        big_integer_class = Truffle::Interop.java_type("java.math.BigInteger")
        big_integer = big_integer_class.new("14")
        big_integer.is_a?(big_integer_class).should be_true
      end

      it "returns true for a directly matching Java object and superclass" do
        big_integer_class = Truffle::Interop.java_type("java.math.BigInteger")
        big_integer = big_integer_class.new("14")
        number_class = Truffle::Interop.java_type("java.lang.Number")
        big_integer.is_a?(number_class).should be_true
      end

      it "returns true for a directly matching Java object and interface" do
        big_integer_class = Truffle::Interop.java_type("java.math.BigInteger")
        big_integer = big_integer_class.new("14")
        serializable_interface = Truffle::Interop.java_type("java.io.Serializable")
        big_integer.is_a?(serializable_interface).should be_true
      end

      it "returns false for an unrelated Java object and Java class" do
        big_integer_class = Truffle::Interop.java_type("java.math.BigInteger")
        big_integer = big_integer_class.new("14")
        big_decimal_class = Truffle::Interop.java_type("java.math.BigDecimal")
        big_integer.is_a?(big_decimal_class).should be_false
      end

      it "returns false for a Java object and a Ruby class" do
        java_hash = Truffle::Interop.java_type("java.util.HashMap").new
        java_hash.is_a?(Hash).should be_false
      end

      it "raises a type error for a non-Java foreign object and a non-Java foreign class" do
        -> {
          Truffle::Debug.foreign_object.is_a?(Truffle::Debug.foreign_object)
        }.should raise_error(TypeError, /cannot check if a foreign object is an instance of a foreign class/)
      end

      it "works with boxed primitives" do
        boxed_integer = Truffle::Debug.foreign_boxed_value(14)
        boxed_integer.is_a?(Integer).should be_true
        boxed_double = Truffle::Debug.foreign_boxed_value(14.2)
        boxed_double.is_a?(Float).should be_true
      end
    end
  end
end