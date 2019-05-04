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
    final Result opCall(Params params) const {
        return delegate_(params);
    }
    /// Call it with a structure or class as the argument (expanding its members into arguments
    /// in order).
    final Result call(S)(S s) const {
        return callMemberFunctionWithParamsStruct!(this, "opCall", S)(s); // TODO: Can "Member" be removed?
    }
    /// The abstarct virtual function used to create the provided object.
    abstract Result delegate_(Params params) const;
    /// Returns `delegate_` as a delegate.
    final @property Result delegate (Params params) provider() const {
        return &delegate_;
    }
}

/**
Base class for reference providers.

* `Result_` the type of the object to be provided.

* `Params_` the type of provider parameters.
*/class ReferenceProvider(Result_, Params_...) {
    alias Result = Result_; /// the type of the object to be provided.
    alias Params = Params_; /// the type of provider parameters.
    /// Call the provider.
    final ref Result opCall(Params params) const {
        return delegate_(params);
    }
    /// Call it with a structure or class as the argument (expanding its members into arguments
    /// in order).
    final ref Result call(S)(S s) const {
        return callMemberFunctionWithParamsStruct!(this, "opCall", S)(s); // TODO: Can "Member" be removed?
    }
    /// The abstarct virtual function used to create the provided object.
    abstract ref Result delegate_(Params params) const;
    /// Returns `delegate_` as a delegate.
    final @property ref Result delegate (Params params) provider() const {
        return &delegate_;
    }
}

//class ClassFactory(Result, Params...) : Provider!(Result, Params) {
//    override ref Result delegate_(Params params) const {
//        return new Result(params);
//    }
//}
//
//class StructFactory(Result, Params...) : Provider!(Result, Params) {
//    override ref Result delegate_(Params params) const {
//        return Result(params);
//    }
//}

/**
Non-reference provider that calls some function to create the provided object.

`Function` the function called to create the provided object.
*/
class Callable(alias Function) : Provider!(ReturnType!Function, Parameters!Function) {
    override ReturnType!Function delegate_(Params params) const {
        return Function(params);
    }
}

/**
Reference provider that calls some function to create the provided object.

`Function` the function called to create the provided object.
*/
class ReferenceCallable(alias Function) : ReferenceProvider!(ReturnType!Function, Parameters!Function) {
    override ref ReturnType!Function delegate_(Params params) const {
        return Function(params);
    }
}

/**
Base class for non-reference singletons. Uses another provider to create the object.

`Base` is the type of this another provider.
*/
class BaseGeneralSingleton(Base) : Provider!(Base.Result, Base.Params) {
    private Base _base; // TODO: make it immutable?
    /// Create the singleton with given base provider.
    this(Base base) {
        _base = base;
    }
    /// Get the base provider.
    @property Base base() const { return _base; }
}

/**
Base class for reference singletons. Uses another provider to create the object.

`Base` is the type of this another provider.
*/
class ReferenceBaseGeneralSingleton(Base) : ReferenceProvider!(Base.Result, Base.Params) {
    private Base _base; // TODO: make it immutable?
    /// Create the singleton with given base provider.
    this(Base base) {
        _base = base;
    }
    /// Get the base provider.
    @property Base base() const { return _base; }
}

/**
Non-reference thread-unsafe singleton.
*/
class ThreadUnsafeSingleton(Base) : BaseGeneralSingleton!Base {
    override Result delegate_(Params params) const {
        return noLockMemoizeMember!(base, "delegate_")(params);
    }
}

/**
Reference thread-unsafe singleton.
*/
class ReferenceThreadUnsafeSingleton(Base) : ReferenceBaseGeneralSingleton!Base {
    override ref Result delegate_(Params params) const {
        return noLockMemoizeMember!(base, "delegate_")(params);
    }
}

/**
Non-reference thread-safe singleton.
*/
class ThreadSafeSingleton(Base) : BaseGeneralSingleton!Base {
    override Result delegate_(Params params) const {
        return synchroizedMemoizeMember!(base, "delegate_")(params);
    }
}

/**
Reference thread-safe singleton.
*/
class ReferenceThreadSafeSingleton(Base) : ReferenceBaseGeneralSingleton!Base {
    override ref Result delegate_(Params params) const {
        return synchroizedMemoizeMember!(base, "delegate_")(params);
    }
}

/**
Non-reference thread-local singleton.
*/
class ThreadLocalSingleton(Base) : BaseGeneralSingleton!Base {
    override synchronized Result delegate_(Params params) const {
        return memoizeMember!(base, "delegate_")(params);
    }
}

/**
Reference thread-local singleton.
*/
class ReferenceThreadLocalSingleton(Base) : ReferenceBaseGeneralSingleton!Base {
    override synchronized ref Result delegate_(Params params) const {
        return memoizeMember!(base, "delegate_")(params);
    }
}

/**
Non-refernce provider that always returns the same object.

`obj` is the object returned by the provider.
*/
class FixedObject(alias obj) : Provider!(typeof(obj)) {
    override Result delegate_() const {
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
class ReferenceThreadUnsafeCallableSingleton(alias Function) : ReferenceThreadUnsafeSingleton!(Callable!Function) {
    this() {
        super(new Callable!Function);
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
class ReferenceThreadSafeCallableSingleton(alias Function) : ReferenceThreadSafeSingleton!(Callable!Function) {
    this() {
        super(new Callable!Function);
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
class ReferenceThreadLocalCallableSingleton(alias Function) : ReferenceThreadLocalSingleton!(Callable!Function) {
    this() {
        super(new Callable!Function);
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

// TODO: Test FixedObject and reference providers.
