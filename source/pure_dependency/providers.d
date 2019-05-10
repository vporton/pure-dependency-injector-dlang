/*
Copyright (c) 2019 Victor Porton,
Pure Dependency Injector - http://freesoft.portonvictor.org

This file is part of Pure Dependency Injector.

Pure Dependency Injector is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

module pure_dependency.providers;

import std.typecons;
import std.traits;
import memoize;
import struct_params;

/**
Base class for non-reference providers.

* `Result_` the type of the object to be provided.

* `Params_` the type of provider parameters.
*/
class Provider(Result_, Params_...) {
    alias Result = Result_; /// the type of the object to be provided.
    alias Params = Params_; /// the type of provider parameters.
    /// Call the provider.
    final const(Result) opCall(Params params) {
        return delegate_(params);
    }
    /// Call it with a structure or class as the argument (expanding its members into arguments
    /// in order).
    final const(Result) call(S)(S s) {
        return callMemberFunctionWithParamsStruct!(this, "opCall", S)(s);
    }
    /// The abstract virtual function used to create the provided object.
    abstract const(Result) delegate_(Params params);
    alias DelegateType = const(Result) delegate (Params params);
    /// Returns `delegate_` as a delegate.
    final @property DelegateType provider() {
        return &delegate_;
    }
}

/**
Base class for reference providers.

* `Result_` the type of the object to be provided.

* `Params_` the type of provider parameters.
*/
class ReferenceProvider(Result_, Params_...) {
    alias Result = Result_; /// the type of the object to be provided.
    alias Params = Params_; /// the type of provider parameters.
    /// Call the provider.
    final ref Result opCall(Params params) {
        return delegate_(params);
    }
    /// Call it with a structure or class as the argument (expanding its members into arguments
    /// in order).
    final ref Result call(S)(S s) const {
        return callMemberFunctionWithParamsStruct!(this, "opCall", S)(s);
    }
    /// The abstract virtual function used to create the provided object.
    abstract ref Result delegate_(Params params);
    alias DelegateType = ref Result delegate (Params params);
    /// Returns `delegate_` as a delegate.
    final @property DelegateType provider() {
        return &delegate_;
    }
}

//class ClassFactory(Result, Params...) : Provider!(Result, Params) {
//    override ref Result delegate_(Params params) {
//        return new Result(params);
//    }
//}
//
//class StructFactory(Result, Params...) : Provider!(Result, Params) {
//    override ref Result delegate_(Params params) {
//        return Result(params);
//    }
//}

/**
Non-reference provider that calls some function to create the provided object.

`Function` the function called to create the provided object.
*/
class Callable(alias Function) : Provider!(ReturnType!Function, Parameters!Function) {
    override const(ReturnType!Function) delegate_(Params params) {
        return Function(params);
    }
}

/**
Reference provider that calls some function to create the provided object.

`Function` the function called to create the provided object.
*/
class ReferenceCallable(alias Function) : ReferenceProvider!(ReturnType!Function, Parameters!Function) {
    override ref ReturnType!Function delegate_(Params params) {
        return Function(params);
    }
}

/**
Base class for non-reference singletons. Uses another provider to create the object.

`Base` is the type of this another provider.
*/
class BaseGeneralSingleton(Base) : Provider!(Base.Result, Base.Params) {
    private Base _base;
    /// Create the singleton with given base provider.
    this(Base base) {
        _base = base;
    }
    /// Get the base provider.
    @property ref Base base() { return _base; }
}

/**
Base class for reference singletons. Uses another provider to create the object.

`Base` is the type of this another provider.
*/
class ReferenceBaseGeneralSingleton(Base) : ReferenceProvider!(Base.Result, Base.Params) {
    private Base _base;
    /// Create the singleton with given base provider.
    this(Base base) {
        _base = base;
    }
    /// Get the base provider.
    @property ref Base base() { return _base; }
}

/**
Non-reference thread-unsafe singleton.
*/
class ThreadUnsafeSingleton(Base) : BaseGeneralSingleton!Base {
    this(Base base) { super(base); }
    override const(Result) delegate_(Params params) {
        return noLockMemoizeMember!(Base, "delegate_")(base, params);
    }
}

/**
Reference thread-unsafe singleton.
*/
class ReferenceThreadUnsafeSingleton(Base) : ReferenceBaseGeneralSingleton!Base {
    this(Base base) { super(base); }
    override ref Result delegate_(Params params) {
            return referenceNoLockMemoizeMember!(Base, "delegate_")(base, params);
    }
}

/**
Non-reference thread-safe singleton.
*/
class ThreadSafeSingleton(Base) : BaseGeneralSingleton!Base {
    this(Base base) { super(base); }
    override const(Result) delegate_(Params params) {
        return synchronizedMemoizeMember!(Base, "delegate_")(base, params);
    }
}

/**
Reference thread-safe singleton.
*/
class ReferenceThreadSafeSingleton(Base) : ReferenceBaseGeneralSingleton!Base {
    this(Base base) { super(base); }
    override ref Result delegate_(Params params) {
        return referenceSynchronizedMemoizeMember!(Base, "delegate_")(base, params);
    }
}

/**
Non-reference thread-local singleton.
*/
class ThreadLocalSingleton(Base) : BaseGeneralSingleton!Base {
    this(Base base) { super(base); }
    override const(Result) delegate_(Params params) {
        synchronized {
            return memoizeMember!(Base, "delegate_")(base, params);
        }
    }
}

/**
Reference thread-local singleton.
*/
class ReferenceThreadLocalSingleton(Base) : ReferenceBaseGeneralSingleton!Base {
    this(Base base) { super(base); }
    override ref Result delegate_(Params params) {
        synchronized {
            return referenceMemoizeMember!(Base, "delegate_")(base, params);
        }
    }
}

/**
Non-refernce provider that always returns the same object.

`obj` is the object returned by the provider.
*/
class FixedObject(alias obj) : Provider!(typeof(obj)) {
    override const(Result) delegate_() const {
        return obj;
    }
}

/**
Refernce provider that always returns the same object.

`obj` is the object returned by the provider.
*/
class ReferenceFixedObject(alias obj) : ReferenceProvider!(typeof(obj)) {
    override ref Result delegate_() const {
        return obj;
    }
}

// TODO: *CallableSingleton classes are of an inefficient implementation (holding a pointer).

/**
Non-reference singleton provider that calls some function to create the provided object.

`Function` the function called to create the provided object.
*/
class ThreadUnsafeCallableSingleton(alias Function) : ThreadUnsafeSingleton!(Callable!Function) {
    this() {
        super(new Callable!Function);
    }
}

/**
Reference singleton provider that calls some function to create the provided object.

`Function` the function called to create the provided object.
*/
class ReferenceThreadUnsafeCallableSingleton(alias Function) : ReferenceThreadUnsafeSingleton!(ReferenceCallable!Function) {
    this() {
        super(new ReferenceCallable!Function);
    }
}

/**
Non-reference singleton provider that calls some function to create the provided object.

`Function` the function called to create the provided object.
*/
class ThreadSafeCallableSingleton(alias Function) : ThreadSafeSingleton!(Callable!Function) {
    this() {
        super(new Callable!Function);
    }
}

/**
Reference singleton provider that calls some function to create the provided object.

`Function` the function called to create the provided object.
*/
class ReferenceThreadSafeCallableSingleton(alias Function) : ReferenceThreadSafeSingleton!(ReferenceCallable!Function) {
    this() {
        super(new ReferenceCallable!Function);
    }
}

/**
Non-reference singleton provider that calls some function to create the provided object.

`Function` the function called to create the provided object.
*/
class ThreadLocalCallableSingleton(alias Function) : ThreadLocalSingleton!(Callable!Function) {
    this() {
        super(new Callable!Function);
    }
}

/**
Reference singleton provider that calls some function to create the provided object.

`Function` the function called to create the provided object.
*/
class ReferenceThreadLocalCallableSingleton(alias Function) : ReferenceThreadLocalSingleton!(ReferenceCallable!Function) {
    this() {
        super(new ReferenceCallable!Function);
    }
}

class ProviderWithDefaults(Base, ParamsType, alias defaults) : Base {
    Result callWithDefaults(ParamsType.WithDefaults params) {
        return call(combine(params, defaults));
    }
}

unittest {
    class C {
        int v;
        this(int a, int b) { v = a + b; }
    }
    auto cFactory = new Callable!((int a, int b) => new C(a, b));
    assert(cFactory(1, 2).v == 3);
}

unittest {
    int x;
    ref int f() { return x; }
    auto cFactory = new ReferenceCallable!(f);
    assert(&cFactory() == &x);
}

unittest {
    int obj = 3;
    int f(int a, int b) { return a + b; }
    ref int g() { return obj; }

    assert(new FixedObject!obj()() == obj);
    assert(&new ReferenceFixedObject!obj()() == &obj);

    assert(new ThreadUnsafeCallableSingleton!f()(2, 5) == 7);
    auto refSingleton = new ReferenceThreadUnsafeCallableSingleton!g();
    assert(refSingleton() == refSingleton());

    assert(new ThreadSafeCallableSingleton!f()(2, 5) == 7);
    auto refSingleton2 = new ReferenceThreadSafeCallableSingleton!g();
    assert(refSingleton2() == refSingleton2());

    assert(new ThreadLocalCallableSingleton!f()(2, 5) == 7);
    auto refSingleton3 = new ReferenceThreadLocalCallableSingleton!g();
    assert(refSingleton3() == refSingleton3());
}

unittest {
    mixin StructParams!("S", int, "x", float, "y");
    float calc(int x, float y) {
        return x * y;
    }
    immutable S.Regular myDefaults = { x: 3, y: 2.1 };
    alias MyProvider = ProviderWithDefaults!(Callable!calc, S, myDefaults);

    immutable S.WithDefaults providerParams = { x: 2 }; // note y is default initialized to null
    auto provider = new MyProvider;
    assert(provider.callWithDefaults(providerParams) - 4.2 < 1e-6);
}

