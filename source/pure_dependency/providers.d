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

class Provider(Result, Params...) {
    final Result opCall(Params params) {
        return delegate_(params);
    }
    final Result call(Params params) {
        return callMemberFunctionWithParamsStruct!(this, "opCall")(params); // TODO: Can "Member" be removed?
    }
    abstract Result delegate_(Params params);
    final @property Result delegate (Params params) provider() {
        return delegate_;
    }
}

class ClassFactory(Result, Params...) : Provider!(Result, Params) {
    Result delegate_(Params params) {
        return new Result(params);
    }
}

/**
Not thread safe!
*/
class Singleton(Result, Params...) : Provider!(Result, Params) {
    final Result opCall(Params params) {
        return noLockMemoizeMember!delegate_(params);
    }
}

class Object_(obj, Params...) : Provider!(Result, Params) {
    final Result opCall(Params params) {
        return obj;
    }
}

class ThreadSafeSingleton(Result, Params...) : Provider!(Result, Params) {
    final synchronized Result opCall(Params params) {
        return memoizeMember!delegate_(params);
    }
}

class ThreadLocalSingleton(Result, Params...) : Provider!(Result, Params) {
    final synchronized Result opCall(Params params) {
        return memoize!delegate_(params);
    }
}
