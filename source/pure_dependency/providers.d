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

import std.traits;

// TODO: final methods (here and in other files)

mixin template ProviderParam(T, string name) {
    mixin("Nullable!" ~ __traits(identifier, T) ~ ' ' ~ name ~ ';');
}

private string ProviderParamsCode(string name, Fields...)()
    if(!all!(t => isType!(t[0]), is(typeof(t[1]) == string) && t.length == 2)(Fields))
{
    static assert(0, "ProviderParamsCode argument should be like [[int, \"x\"], [float, \"y\"]]");
}

private string ProviderParamsCode(string name, Fields...)() {
    immutable string regularFields =
        map!(f => __traits(identifier, f[0]) ~ ' ' ~ f[1] ~ ';')(Fields).join('\n');
    immutable string fieldsWithDefaults =
        map!(f => "Nullable!" ~ __traits(identifier, f[0]) ~ ' ' ~ f[1] ~ ';')(Fields).join('\n');
    return "struct " ~ name ~ " {\n" ~
           "  struct Regular {\n" ~
           "    " ~ regularFields ~ '\n' ~
           "  }\n" ~
           "  struct WithDefaults {\n" ~
           "    " ~ fieldsWithDefaults ~ '\n' ~
           "  }\n" ~
           '}';
}

mixin template ProviderParams(string name, Fields...) {
    mixin(ProviderParamsCode!(name, Fields)());
}

S.Regular combine(S)(S.WithDefaults main, S.Regular default_) {
    S result = default_;
    static foreach (m; __traits(allMembers, S)) {
        immutable mainMember = __traits(getMember, main, m);
        __traits(getMember, result, m) =
            mainMember.isNull ? __traits(getMember, default_, m) : mainMember.get;
    }
    return result;
}

ReturnType!f callFunctionWithParamsStruct(alias f, S)(S s) {
    return f(map!(m => __traits(getMember, s, m))(__traits(allMembers, S)));
}

class Provider(Result) {
    //@property Delegate delegate(); // TODO
    // TODO: Use a dictionary? struct with nullable fields? to represent a list of default args
    final Result opCall(A...)(A a) {
        return _delegate(a);
    }
    abstract Result _delegate(...);
}
