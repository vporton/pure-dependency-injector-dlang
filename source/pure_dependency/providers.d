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

class Provider(Result_, Params_...) {
    alias Result = Result_;
    alias Params = Params_;
    final Result opCall(Params params) const {
        return delegate_(params);
    }
    final Result call(S)(S s) const {
        return callMemberFunctionWithParamsStruct!(this, "opCall", S)(s); // TODO: Can "Member" be removed?
    }
    abstract Result delegate_(Params params) const;
    final @property Result delegate (Params params) provider() const {
        return &delegate_;
    }
}

class ReferenceProvider(Result_, Params_...) {
    alias Result = Result_;
    alias Params = Params_;
    final ref Result opCall(Params params) const {
        return delegate_(params);
    }
    final ref Result call(S)(S s) const {
        return callMemberFunctionWithParamsStruct!(this, "opCall", S)(s); // TODO: Can "Member" be removed?
    }
    abstract ref Result delegate_(Params params) const;
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

class Callable(alias Function) : Provider!(ReturnType!Function, Parameters!Function) {
    override ReturnType!Function delegate_(Params params) const {
        return Function(params);
    }
}

class ReferenceCallable(alias Function) : ReferenceProvider!(ReturnType!Function, Parameters!Function) {
    override ref ReturnType!Function delegate_(Params params) const {
        return Function(params);
    }
}

class BaseGeneralSingleton(Base) : Provider!(Base.Result, Base.Params) {
    private Base _base;
    this(Base base) {
        _base = base;
    }
    @property Base base() const { return _base; }
}

class ReferenceBaseGeneralSingleton(Base) : ReferenceProvider!(Base.Result, Base.Params) {
    private Base _base;
    this(Base base) {
        _base = base;
    }
    @property Base base() const { return _base; }
}

/**
Not thread safe!
*/
class Singleton(Base) : BaseGeneralSingleton!Base {
    override Result delegate_(Params params) const {
        return noLockMemoizeMember!(base, "delegate_")(params);
    }
}

class ReferenceSingleton(Base) : ReferenceBaseGeneralSingleton!Base {
    override ref Result delegate_(Params params) const {
        return noLockMemoizeMember!(base, "delegate_")(params);
    }
}

class ThreadSafeSingleton(Base) : BaseGeneralSingleton!Base {
    override Result delegate_(Params params) const {
        return synchroizedMemoizeMember!(base, "delegate_")(params);
    }
}

class ReferenceThreadSafeSingleton(Base) : ReferenceBaseGeneralSingleton!Base {
    override ref Result delegate_(Params params) const {
        return synchroizedMemoizeMember!(base, "delegate_")(params);
    }
}

class ThreadLocalSingleton(Base) : BaseGeneralSingleton!Base {
    override synchronized Result delegate_(Params params) const {
        return memoizeMember!(base, "delegate_")(params);
    }
}

class ReferenceThreadLocalSingleton(Base) : ReferenceBaseGeneralSingleton!Base {
    override synchronized ref Result delegate_(Params params) const {
        return memoizeMember!(base, "delegate_")(params);
    }
}

class FixedObject(alias obj) : Provider!(typeof(obj)) {
    override Result delegate_() const {
        return obj;
    }
}

class ReferenceFixedObject(alias obj, Params...) : ReferenceProvider!(typeof(obj), Params) {
    override ref Result delegate_(Params params) const {
        return obj;
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
