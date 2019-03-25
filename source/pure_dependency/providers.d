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

class Provider(Result) {
    final Result opCall(A...)(A a) {
        return delegate_(a);
    }
    final Result call(S)(S s) {
        return callMemberFunctionWithParamsStruct!(this, "opCall")(s);
    }
    abstract Result delegate_(...);
    final @property Result delegate (...) provider() {
        return delegate_;
    }
}

/**
Not thread safe!
*/
class Singleton(Result) : Provider!Result {
    final Result opCall(A...)(A a) {
        return noLockMemoizeMember!delegate_(a);
    }
}

class Object_(obj) : Provider!Result {
    final Result opCall(A...)(A a) {
        return obj;
    }
}

class ThreadSafeSingleton(Result) : Provider!Result {
    final synchronized Result opCall(A...)(A a) {
        return memoizeMember!delegate_(a);
    }
}

class ThreadLocalSingleton(Result) : Provider!Result {
    final synchronized Result opCall(A...)(A a) {
        return memoize!delegate_(a);
    }
}
