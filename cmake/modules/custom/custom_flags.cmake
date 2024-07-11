#
# Copyright (c) 2024 Maxime Pinard
#
# Distributed under the MIT license
# See accompanying file LICENSE or copy at
# https://opensource.org/licenses/MIT
#
cmake_minimum_required(VERSION 3.25)

include_guard()

# MSVC Asan flags
macro(custom_mscv_cxx_asan_flags_init)
    set(CUSTOM_MSVC_CXX_ASAN_FLAGS
      ################################################################
      # https://learn.microsoft.com/en-us/cpp/build/reference/fsanitize
      ################################
      # Enable AddressSanitizer
      /fsanitize=address
    )
endmacro()

# CLANG Asan flags
macro(custom_clang_cxx_asan_flags_init)
    set(CUSTOM_CLANG_CXX_ASAN_FLAGS
      ################################################################
      # https://clang.llvm.org/docs/AddressSanitizer.html
      ################################
      # Enable AddressSanitizer
      -fsanitize=address
      ################################
      # Stack Use After Return (UAR)
      -fsanitize-address-use-after-return=always
      ################################
      # Use-after-scope
      -fsanitize-address-use-after-scope
      ################################
      # To get nicer stack traces in error messages
      -fno-omit-frame-pointer
      ################################
      # To get perfect stack traces you may need to disable inlining (just use -O1) and tail call elimination
      -fno-optimize-sibling-calls
    )
endmacro()

# GCC Asan flags
macro(custom_gcc_cxx_asan_flags_init)
    set(CUSTOM_GCC_CXX_ASAN_FLAGS
      ################################################################
      # https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html
      ################################
      # Enable AddressSanitizer, a fast memory error detector.
      # Memory access instructions are instrumented to detect out-of-bounds and use-after-free bugs.
      # The option enables -fsanitize-address-use-after-scope.
      # See https://github.com/google/sanitizers/wiki/AddressSanitizer for more details.
      # The run-time behavior can be influenced using the ASAN_OPTIONS environment variable.
      # When set to help=1, the available options are shown at startup of the instrumented program.
      # See https://github.com/google/sanitizers/wiki/AddressSanitizerFlags#run-time-flags for a list of supported options.
      # The option cannot be combined with -fsanitize=thread or -fsanitize=hwaddress.
      -fsanitize=address
      ################################
      # Instrument comparison operation (<, <=, >, >=) with pointer operands.
      # The option must be combined with either -fsanitize=kernel-address or -fsanitize=address The option cannot be combined with -fsanitize=thread.
      # Note: By default the check is disabled at run time.
      # To enable it, add detect_invalid_pointer_pairs=2 to the environment variable ASAN_OPTIONS.
      # Using detect_invalid_pointer_pairs=1 detects invalid operation only when both pointers are non-null.
      -fsanitize=pointer-compare
      ################################
      # Instrument subtraction with pointer operands.
      # The option must be combined with either -fsanitize=kernel-address or -fsanitize=address The option cannot be combined with -fsanitize=thread.
      # Note: By default the check is disabled at run time.
      # To enable it, add detect_invalid_pointer_pairs=2 to the environment variable ASAN_OPTIONS.
      # Using detect_invalid_pointer_pairs=1 detects invalid operation only when both pointers are non-null.
      -fsanitize=pointer-subtract
      ################################
      # Prevents optimizing sibling and tail recursive calls; this option is implicit for -O0, -O1, or -Og
      -fno-optimize-sibling-calls
      ################################
      # Disables Identical Code Folding for functions
      -fno-ipa-icf
      ################################
      # Note that -fno-omit-frame-pointer doesn't guarantee the frame pointer is used in all functions.
      # Several targets always omit the frame pointer in leaf functions.
      -fno-omit-frame-pointer
    )
endmacro()

# MSVC UBsan flags
macro(custom_mscv_cxx_ubsan_flags_init)
    # Not supported yet: https://learn.microsoft.com/en-us/cpp/sanitizers
    set(CUSTOM_MSVC_CXX_UBSAN_FLAGS)
endmacro()

# CLANG UBsan flags
macro(custom_clang_cxx_ubsan_flags_init)
    set(CUSTOM_CLANG_CXX_UBSAN_FLAGS
      ################################################################
      # https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html
      ################################
      # All of the checks other than float-divide-by-zero, unsigned-integer-overflow, implicit-conversion, local-bounds and the nullability-* group of checks.
      -fsanitize=undefined
      ################################
      # Use of a misaligned pointer or creation of a misaligned reference.
      # Also sanitizes assume_aligned-like attributes.
      -fsanitize=alignment # already in -fsanitize=undefined
      ################################
      # Load of a bool value which is neither true nor false.
      #-fsanitize=bool # already in -fsanitize=undefined
      ################################
      # Passing invalid values to compiler builtins.
      -fsanitize=builtin # already in -fsanitize=undefined
      ################################
      # Out of bounds array indexing, in cases where the array bound can be statically determined.
      # The check includes -fsanitize=array-bounds and -fsanitize=local-bounds.
      # Note that -fsanitize=local-bounds is not included in -fsanitize=undefined.
      -fsanitize=bounds # already in -fsanitize=undefined
      ################################
      # Load of a value of an enumerated type which is not in the range of representable values for that enumerated type.
      -fsanitize=enum # already in -fsanitize=undefined
      ################################
      # Conversion to, from, or between floating-point types which would overflow the destination.
      # Because the range of representable values for all floating-point types supported by Clang is [-inf, +inf], the only cases detected are conversions from floating point to integer types.
      -fsanitize=float-cast-overflow # already in -fsanitize=undefined
      ################################
      # Floating point division by zero.
      # This is undefined per the C and C++ standards, but is defined by Clang (and by ISO/IEC/IEEE 60559 / IEEE 754) as producing either an infinity or NaN value, so is not included in -fsanitize=undefined.
      #-fsanitize=float-divide-by-zero # division by zero which can be legitimate to get infinity and NaN
      ################################
      # Indirect call of a function through a function pointer of the wrong type.
      -fsanitize=function # already in -fsanitize=undefined
      ################################
      # Implicit conversion from integer of larger bit width to smaller bit width, if that results in data loss.
      # That is, if the demoted value, after casting back to the original width, is not equal to the original value before the downcast.
      # The -fsanitize=implicit-unsigned-integer-truncation handles conversions between two unsigned types, while -fsanitize=implicit-signed-integer-truncation handles the rest of the conversions - when either one, or both of the types are signed.
      # Issues caught by these sanitizers are not undefined behavior, but are often unintentional.
      #-fsanitize=implicit-unsigned-integer-truncation # already in -fsanitize=undefined
      -fsanitize=implicit-signed-integer-truncation # already in -fsanitize=undefined
      ################################
      # Implicit conversion between integer types, if that changes the sign of the value.
      # That is, if the original value was negative and the new value is positive (or zero), or the original value was positive, and the new value is negative.
      # Issues caught by this sanitizer are not undefined behavior, but are often unintentional.
      -fsanitize=implicit-integer-sign-change # already in -fsanitize=undefined
      ################################
      # Integer division by zero.
      #-fsanitize=integer-divide-by-zero # already in -fsanitize=undefined
      ################################
      # Passing null pointer as a function parameter which is declared to never be null.
      -fsanitize=nonnull-attribute # already in -fsanitize=undefined
      ################################
      # Use of a null pointer or creation of a null reference.
      -fsanitize=null # already in -fsanitize=undefined
      ################################
      # Passing null as a function parameter which is annotated with _Nonnull.
      -fsanitize=nullability-arg
      ################################
      # Assigning null to an lvalue which is annotated with _Nonnull.
      -fsanitize=nullability-assign
      ################################
      # Returning null from a function with a return type annotated with _Nonnull.
      -fsanitize=nullability-return
      ################################
      # Invalid implicit cast of an ObjC object pointer to an incompatible type.
      # This is often unintentional, but is not undefined behavior, therefore the check is not a part of the undefined group.
      # Currently only supported on Darwin.
      #-fsanitize=objc-cast # already in -fsanitize=undefined
      ################################
      # An attempt to potentially use bytes which the optimizer can determine are not part of the object being accessed.
      # This will also detect some types of undefined behavior that may not directly access memory, but are provably incorrect given the size of the objects involved, such as invalid downcasts and calling methods on invalid pointers.
      # These checks are made in terms of __builtin_object_size, and consequently may be able to detect more problems at higher optimization levels.
      -fsanitize=object-size # already in -fsanitize=undefined
      ################################
      # Performing pointer arithmetic which overflows, or where either the old or new pointer value is a null pointer (or in C, when they both are).
      -fsanitize=pointer-overflow # already in -fsanitize=undefined
      ################################
      # In C++, reaching the end of a value-returning function without returning a value.
      -fsanitize=return # already in -fsanitize=undefined
      ################################
      # Returning null pointer from a function which is declared to never return null.
      -fsanitize=returns-nonnull-attribute # already in -fsanitize=undefined
      ################################
      # Shift operators where the amount shifted is greater or equal to the promoted bit-width of the left hand side or less than zero, or where the left hand side is negative.
      # For a signed left shift, also checks for signed overflow in C, and for unsigned overflow in C++.
      # You can use -fsanitize=shift-base or -fsanitize=shift-exponent to check only left-hand side or right-hand side of shift operation, respectively.
      -fsanitize=shift # already in -fsanitize=undefined
      ################################
      # check that an unsigned left-hand side of a left shift operation doesn't overflow.
      # Issues caught by this sanitizer are not undefined behavior, but are often unintentional.
      #-fsanitize=unsigned-shift-base # already in -fsanitize=undefined
      ################################
      # Signed integer overflow, where the result of a signed integer computation cannot be represented in its type.
      # This includes all the checks covered by -ftrapv, as well as checks for signed division overflow (INT_MIN/-1), but not checks for lossy implicit conversions performed before the computation (see -fsanitize=implicit-conversion).
      # Both of these two issues are handled by -fsanitize=implicit-conversion group of checks.
      -fsanitize=signed-integer-overflow
      ################################
      # If control flow reaches an unreachable program point.
      -fsanitize=unreachable # already in -fsanitize=undefined
      ################################
      # Unsigned integer overflow, where the result of an unsigned integer computation cannot be represented in its type.
      # Unlike signed integer overflow, this is not undefined behavior, but it is often unintentional.
      # This sanitizer does not check for lossy implicit conversions performed before such a computation (see -fsanitize=implicit-conversion).
      -fsanitize=unsigned-integer-overflow
      ################################
      # A variable-length array whose bound does not evaluate to a positive value.
      -fsanitize=vla-bound # already in -fsanitize=undefined
      ################################
      # Use of an object whose vptr indicates that it is of the wrong dynamic type, or that its lifetime has not begun or has ended.
      # Incompatible with -fno-rtti.
      # Link must be performed by clang++, not clang, to make sure C++-specific parts of the runtime library and C++ standard libraries are present.
      -fsanitize=vptr # already in -fsanitize=undefined
      ################################################################
      # https://clang.llvm.org/docs/AddressSanitizer.html
      ################################
      # Use-after-return
      -fsanitize-address-use-after-scope
      ################################
      # To get nicer stack traces in error messages
      -fno-omit-frame-pointer
      ################################
      # To get perfect stack traces you may need to disable inlining (just use -O1) and tail call elimination
      -fno-optimize-sibling-calls
      ################################
      # https://clang.llvm.org/docs/ClangCommandLineReference.html
      -fstack-protector-strong
      ################################################################
      # https://clang.llvm.org/docs/ClangCommandLineReference.html#cmdoption-clang-fsanitize-link-c-runtime
      -fsanitize-link-c++-runtime
    )
endmacro()

# GCC UBsan flags
macro(custom_gcc_cxx_ubsan_flags_init)
    set(CUSTOM_GCC_CXX_UBSAN_FLAGS
      ################################################################
      # https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html
      ################################
      # Enable UndefinedBehaviorSanitizer, a fast undefined behavior detector.
      # Various computations are instrumented to detect undefined behavior at runtime.
      # See https://clang.llvm.org/docs/UndefinedBehaviorSanitizer.html for more details.
      # The run-time behavior can be influenced using the UBSAN_OPTIONS environment variable.
      -fsanitize=undefined
      ################################
      # This option enables checking that the result of a shift operation is not undefined.
      # Note that what exactly is considered undefined differs slightly between C and C++, as well as between ISO C90 and C99, etc.
      # This option has two suboptions, -fsanitize=shift-base and -fsanitize=shift-exponent.
      -fsanitize=shift
      ################################
      # This option enables checking that the second argument of a shift operation is not negative and is smaller than the precision of the promoted first argument.
      -fsanitize=shift-exponent
      ################################
      # If the second argument of a shift operation is within range, check that the result of a shift operation is not undefined.
      # Note that what exactly is considered undefined differs slightly between C and C++, as well as between ISO C90 and C99, etc.
      -fsanitize=shift-base
      ################################
      # Detect integer division by zero.
      -fsanitize=integer-divide-by-zero
      ################################
      # With this option, the compiler turns the __builtin_unreachable call into a diagnostics message call instead.
      # When reaching the __builtin_unreachable call, the behavior is undefined.
      -fsanitize=unreachable
      ################################
      # This option instructs the compiler to check that the size of a variable length array is positive.
      -fsanitize=vla-bound
      ################################
      # This option enables pointer checking.
      # Particularly, the application built with this option turned on will issue an error message when it tries to dereference a NULL pointer, or if a reference (possibly an rvalue reference) is bound to a NULL pointer, or if a method is invoked on an object pointed by a NULL pointer.
      -fsanitize=null
      ################################
      # This option enables return statement checking.
      # Programs built with this option turned on will issue an error message when the end of a non-void function is reached without actually returning a value.
      # This option works in C++ only.
      -fsanitize=return
      ################################
      # This option enables signed integer overflow checking.
      # We check that the result of +, *, and both unary and binary - does not overflow in the signed arithmetics.
      # This also detects INT_MIN / -1 signed division.
      # Note, integer promotion rules must be taken into account.
      # That is, the following is not an overflow:
      #     signed char a = SCHAR_MAX;
      #     a++;
      -fsanitize=signed-integer-overflow
      ################################
      # This option enables instrumentation of array bounds.
      # Various out of bounds accesses are detected.
      # Flexible array members, flexible array member-like arrays, and initializers of variables with static storage are not instrumented, with the exception of flexible array member-like arrays for which -fstrict-flex-arrays or -fstrict-flex-arrays= options or strict_flex_array attributes say they shouldn't be treated like flexible array member-like arrays.
      -fsanitize=bounds
      ################################
      # This option enables strict instrumentation of array bounds.
      # Most out of bounds accesses are detected, including flexible array member-like arrays.
      # Initializers of variables with static storage are not instrumented.
      -fsanitize=bounds-strict
      ################################
      # This option enables checking of alignment of pointers when they are dereferenced, or when a reference is bound to insufficiently aligned target, or when a method or constructor is invoked on insufficiently aligned object.
      -fsanitize=alignment
      ################################
      # This option enables instrumentation of memory references using the __builtin_dynamic_object_size function.
      # Various out of bounds pointer accesses are detected.
      -fsanitize=object-size
      ################################
      # Detect floating-point division by zero.
      # Unlike other similar options, -fsanitize=float-divide-by-zero is not enabled by -fsanitize=undefined, since floating-point division by zero can be a legitimate way of obtaining infinities and NaNs.
      #-fsanitize=float-divide-by-zero # division by zero which can be legitimate to get infinity and NaN
      ################################
      # This option enables floating-point type to integer conversion checking.
      # We check that the result of the conversion does not overflow.
      # Unlike other similar options, -fsanitize=float-cast-overflow is not enabled by -fsanitize=undefined.
      # This option does not work well with FE_INVALID exceptions enabled.
      -fsanitize=float-cast-overflow
      ################################
      # This option enables instrumentation of calls, checking whether null values are not passed to arguments marked as requiring a non-null value by the nonnull function attribute.
      -fsanitize=nonnull-attribute
      ################################
      # This option enables instrumentation of return statements in functions marked with returns_nonnull function attribute, to detect returning of null values from such functions.
      -fsanitize=returns-nonnull-attribute
      ################################
      # This option enables instrumentation of loads from bool.
      # If a value other than 0/1 is loaded, a run-time error is issued.
      -fsanitize=bool
      ################################
      # This option enables instrumentation of loads from an enum type.
      # If a value outside the range of values for the enum type is loaded, a run-time error is issued.
      -fsanitize=enum
      ################################
      # This option enables instrumentation of C++ member function calls, member accesses and some conversions between pointers to base and derived classes, to verify the referenced object has the correct dynamic type.
      -fsanitize=vptr
      ################################
      # This option enables instrumentation of pointer arithmetics.
      # If the pointer arithmetics overflows, a run-time error is issued.
      -fsanitize=pointer-overflow
      ################################
      # This option enables instrumentation of arguments to selected builtin functions.
      # If an invalid value is passed to such arguments, a run-time error is issued.
      # E.g. passing 0 as the argument to __builtin_ctz or __builtin_clz invokes undefined behavior and is diagnosed by this option.
      -fsanitize=builtin
      ################################################################
      # https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html
      ################################
      # Enable sanitization of local variables to detect use-after-scope bugs.
      # The option sets -fstack-reuse to 'none'.
      -fsanitize-address-use-after-scope
      # Like -fstack-protector but includes additional functions to be protected — those that have local array definitions, or have references to local frame addresses.
      # Only variables that are actually allocated on the stack are considered, optimized away variables or variables allocated in registers don't count.
      -fstack-protector-strong
      # Generate code to verify that you do not go beyond the boundary of the stack.
      # You should specify this flag if you are running in an environment with multiple threads, but you only rarely need to specify it in a single-threaded environment since stack overflow is automatically detected on nearly all systems if there is only one stack.
      -fstack-check
      ################################
      # This option is only available when compiling C++ code.
      # It turns on (or off, if using -fvtable-verify=none) the security feature that verifies at run time, for every virtual call, that the vtable pointer through which the call is made is valid for the type of the object, and has not been corrupted or overwritten.
      # If an invalid vtable pointer is detected at run time, an error is reported and execution of the program is immediately halted.
      # This option causes run-time data structures to be built at program startup, which are used for verifying the vtable pointers.
      # The options 'std' and 'preinit' control the timing of when these data structures are built.
      # In both cases the data structures are built before execution reaches main.
      # Using -fvtable-verify=std causes the data structures to be built after shared libraries have been loaded and initialized.
      #-fvtable-verify=preinit causes them to be built before shared libraries have been loaded and initialized.
      #-fvtable-verify=std
    )
endmacro()

# MSVC Tsan flags
macro(custom_mscv_cxx_tsan_flags_init)
    # Not supported yet: https://learn.microsoft.com/en-us/cpp/sanitizers
    set(CUSTOM_MSVC_CXX_TSAN_FLAGS)
endmacro()

# CLANG Tsan flags
macro(custom_clang_cxx_tsan_flags_init)
    set(CUSTOM_CLANG_CXX_TSAN_FLAGS
      ################################################################
      # https://clang.llvm.org/docs/ThreadSanitizer.html
      ################################
      # Enable ThreadSanitizer
      -fsanitize=thread
      ################################
      # To get nicer stack traces in error messages
      -fno-omit-frame-pointer
    )
endmacro()

# GCC Tsan flags
macro(custom_gcc_cxx_tsan_flags_init)
    set(CUSTOM_GCC_CXX_TSAN_FLAGS
      ################################################################
      # https://gcc.gnu.org/onlinedocs/gcc/Instrumentation-Options.html
      ################################
      # Enable ThreadSanitizer
      -fsanitize=thread
      ################################
      # To get nicer stack traces in error messages
      -fno-omit-frame-pointer
    )
endmacro()

# MSVC warning flags
macro(custom_mscv_cxx_warning_flags_init)
    set(CUSTOM_MSVC_CXX_WARNING_FLAGS
      /utf-8 # Set source and execution character sets to UTF-8.
      /validate-charset # Validate UTF-8 files for only compatible characters.
      # /analyse # Enables code analysis.
      /diagnostics:caret # Diagnostics format: prints column and the indicated line of source.
      /W4 # Warning level
      /sdl # Enable Additional Security Checks
      ################################
      # https://docs.microsoft.com/en-us/cpp/preprocessor/compiler-warnings-that-are-off-by-default
      # /w44061 # enumerator 'identifier' in a switch of enum 'enumeration' is not explicitly handled by a case label
      # /w44062 # enumerator 'identifier' in a switch of enum 'enumeration' is not handled
      # /w14165 # 'HRESULT' is being converted to 'bool'; are you sure this is what you want?
      # /w34191 # 'operator': unsafe conversion from 'type_of_expression' to 'type_required'
      # /w44242 # 'identifier': conversion from 'type1' to 'type2', possible loss of data
      # /w44254 # 'operator': conversion from 'type1' to 'type2', possible loss of data
      # /w44255 # 'function': no function prototype given: converting '()' to '(void)'
      /w44263 # 'function': member function does not override any base class virtual member function
      /w14264 # 'virtual_function': no override available for virtual member function from base 'class'; function is hidden
      /w34265 # 'class': class has virtual functions, but destructor is not virtual
      # /w44266 # 'function': no override available for virtual member function from base 'type'; function is hidden
      /w34287 # 'operator': unsigned/negative constant mismatch
      /w44289 # nonstandard extension used : 'var' : loop control variable declared in the for-loop is used outside the for-loop scope
      /w44296 # 'operator': expression is always false
      # /w44339 # 'type' : use of undefined type detected in CLR meta-data - use of this type may lead to a runtime exception
      # /w14342 # behavior change: 'function' called, but a member operator was called in previous versions
      # /w14350 # behavior change: 'member1' called instead of 'member2'
      /w44355 # 'this' : used in base member initializer list
      /w44365 # 'action': conversion from 'type_1' to 'type_2', signed/unsigned mismatch
      # /w34370 # layout of class has changed from a previous version of the compiler due to better packing
      # /w34371 # 'classname': layout of class may have changed from a previous version of the compiler due to better packing of member 'member'
      # /w44388 # signed/unsigned mismatch
      /w24412 # 'function': function signature contains type 'type'; C++ objects are unsafe to pass between pure code and mixed or native
      # /w14426 # optimization flags changed after including header, may be due to #pragma optimize() 14.1
      # /w44435 # 'class1' : Object layout under /vd2 will change due to virtual base 'class2'
      # /w44437 # dynamic_cast from virtual base 'class1' to 'class2' could fail in some contexts
      # /w34444 # top level '__unaligned' is not implemented in this context
      /w44464 # relative include path contains '..'
      # /w44471 # a forward declaration of an unscoped enumeration must have an underlying type (int assumed) Perm
      # /w14472 # 'identifier' is a native enum: add an access specifier (private/public) to declare a managed enum
      # /w44514 # 'function': unreferenced inline function has been removed
      # /w44536 # 'type name': type-name exceeds meta-data limit of 'limit' characters
      /w14545 # expression before comma evaluates to a function which is missing an argument list
      /w14546 # function call before comma missing argument list
      /w14547 # 'operator': operator before comma has no effect; expected operator with side-effect
      /w14548 # expression before comma has no effect; expected expression with side-effect
      /w14549 # 'operator1': operator before comma has no effect; did you intend 'operator2'?
      /w14555 # expression has no effect; expected expression with side-effect
      /w34557 # '__assume' contains effect 'effect'
      # /w44571 # informational: catch(...) semantics changed since Visual C++ 7.1; structured exceptions (SEH) are no longer caught
      # /w44574 # 'identifier' is defined to be '0': did you mean to use '#if identifier'?
      # /w14577 # 'noexcept' used with no exception handling mode specified; termination on exception is not guaranteed. Specify /EHsc
      # /w44582 # 'type': constructor is not implicitly called
      # /w44583 # 'type': destructor is not implicitly called
      # /w14587 # 'anonymous_structure': behavior change: constructor is no longer implicitly called
      # /w14588 # 'anonymous_structure': behavior change: destructor is no longer implicitly called
      /w44596 # 'identifier': illegal qualified name in member declaration 14.3 Perm
      # /w33598 # '#include "header"': header number header-number in the precompiled header does not match current compilation at that position 14.3
      # /w34599 # 'option path': command-line argument number number does not match pre-compiled header 14.3
      # /w14605 # '/Dmacro' specified on current command line, but was not specified when precompiled header was built
      /w34608 # 'union_member' has already been initialized by another union member in the initializer list, 'union_member' Perm
      # /w34619 # #pragma warning: there is no warning number 'number'
      # /w44623 # 'derived class': default constructor could not be generated because a base class default constructor is inaccessible
      # /w44625 # 'derived class': copy constructor could not be generated because a base class copy constructor is inaccessible
      # /w44626 # 'derived class': assignment operator could not be generated because a base class assignment operator is inaccessible
      /w14628 # digraphs not supported with -Ze. Character sequence 'digraph' not interpreted as alternate token for 'char'
      # /w34640 # 'instance': construction of local static object is not thread-safe
      /w44643 # Forward declaring 'identifier' in namespace std is not permitted by the C++ Standard. 15.8
      # /w34647 # behavior change: __is_pod(type) has different value in previous versions
      /w44654 # Code placed before include of precompiled header line will be ignored. Add code to precompiled header. 14.1
      /w44668 # 'symbol' is not defined as a preprocessor macro, replacing with '0' for 'directives'
      # /w44682 # 'symbol' : no directional parameter attribute specified, defaulting to [in]
      # /w34686 # 'user-defined type': possible change in behavior, change in UDT return calling convention
      # /w14692 # 'function': signature of non-private member contains assembly private native type 'native_type'
      # /w44710 # 'function': function not inlined
      # /w34738 # storing 32-bit float result in memory, possible loss of performance
      # /w44746 # volatile access of 'expression' is subject to /volatile:<iso|ms> setting; consider using __iso_volatile_load/store intrinsic functions
      # /w44749 # conditionally supported: offsetof applied to non-standard-layout type 'type'
      # /w44767 # section name 'symbol' is longer than 8 characters and will be truncated by the linker
      # /w44774 # 'string' : format string expected in argument number is not a string literal
      /w44777 # 'function' : format string 'string' requires an argument of type 'type1', but variadic argument number has type 'type2'
      # /w34786 # 'symbol' : object name was truncated to 'number' characters in the debug information
      # /w44800 # Implicit conversion from 'type' to bool. Possible information loss 16.0
      # /w44820 # 'bytes' bytes padding added after construct 'member_name'
      /w14822 # 'member': local class member function does not have a body
      # /w24826 # Conversion from 'type1' to 'type2' is sign-extended. This may cause unexpected runtime behavior.
      /w44837 # trigraph detected: '??character' replaced by 'character'
      /w44841 # non-standard extension used: compound member designator used in offsetof
      # /w44842 # the result of 'offsetof' applied to a type using multiple inheritance is not guaranteed to be consistent between compiler releases
      # /w44866 # 'file(line-number)' compiler may not enforce left-to-right evaluation order for call to operator
      # /w44868 # 'file(line_number)' compiler may not enforce left-to-right evaluation order in braced initialization list
      # /w14905 # wide string literal cast to 'LPSTR'
      # /w14906 # string literal cast to 'LPWSTR'
      /w14917 # 'declarator': a GUID can only be associated with a class, interface, or namespace
      /w14928 # illegal copy-initialization; more than one user-defined conversion has been implicitly applied
      # /w44931 # we are assuming the type library was built for number-bit pointers
      /w14946 # reinterpret_cast used between related classes: 'class1' and 'class2'
      # /w44962 # 'function': profile-guided optimizations disabled because optimizations caused profile data to become inconsistent
      /w44986 # 'symbol': exception specification does not match previous declaration
      /w44987 # nonstandard extension used: 'throw (...)'
      # /w44988 # 'symbol': variable declared outside class/function scope
      # /w45022 # 'type': multiple move constructors specified
      # /w45023 # 'type': multiple move assignment operators specified
      # /w45024 # 'type': move constructor was implicitly defined as deleted
      # /w45025 # 'type': move assignment operator was implicitly defined as deleted
      # /w45026 # 'type': move constructor was implicitly defined as deleted
      # /w45027 # 'type': move assignment operator was implicitly defined as deleted
      /w45029 # nonstandard extension used: alignment attributes in C++ apply to variables, data members and tag types only
      /w45031 # #pragma warning(pop): likely mismatch, popping warning state pushed in different file 14.1
      /w45032 # detected #pragma warning(push) with no corresponding #pragma warning(pop) 14.1
      # /w45034 # use of intrinsic 'intrinsic' causes function function-name to be compiled as guest code 15.3
      # /w45035 # use of feature 'feature' causes function function-name to be compiled as guest code 15.3
      # /w15036 # varargs function pointer conversion when compiling with /hybrid:x86arm64 'type1' to 'type2' 15.3
      /w45038 # data member 'member1' will be initialized after data member 'member2' 15.3
      # /w45039 # 'function': pointer or reference to potentially throwing function passed to extern C function under -EHc. Undefined behavior may occur if this function throws an exception. 15.5
      /w45041 # 'member-name': out-of-line definition for constexpr static data member is not needed and is deprecated in C++17. 15.2
      /w35042 # 'function': function declarations at block scope cannot be specified 'inline' in standard C++; remove 'inline' specifier 15.5
      # /w45045 # Compiler will insert Spectre mitigation for memory load if /Qspectre switch specified 15.7
      # /w35052 # Keyword 'keyword-name' was introduced in C++version and requires use of the 'option' command-line option` 16.1
      /w35204 # A class with virtual functions has non-virtual trivial destructor. 16.5
      /w45214 # applying 'keyword' to an operand with a volatile qualified type is deprecated in C++20 16.7
      /w45215 # 'function-parameter' a function parameter with a volatile qualified type is deprecated in C++20 16.7
      /w45216 # 'return-type' a volatile qualified return type is deprecated in C++20 16.7
      /w45217 # a structured binding declaration that includes volatile is deprecated in C++20 16.7
      # /w25219 # implicit conversion from 'type-1' to 'type-2', possible loss of data 16.7
      # /w45220 # 'member': a non-static data member with a volatile qualified type no longer implies that compiler generated copy/move constructors and copy/move assignment operators are not trivial 16.7
      /w45233 # explicit lambda capture 'identifier' is not used 16.10
      /w45240 # 'attribute-name': attribute is ignored in this syntactic position 16.10
      /w15243 # 'type-name': using incomplete class 'class-name' can cause potential one definition rule violation due to ABI limitation 16.10
      # /w45245 # 'function': unreferenced function with internal linkage has been removed
      /w15246 # 'member': the initialization of a subobject should be wrapped in braces 16.10
      /w15247 # Section 'section-name' is reserved for C++ dynamic initialization. Manually creating the section will interfere with C++ dynamic initialization and may lead to undefined behavior 16.11
      /w15248 # Section 'section-name' is reserved for C++ dynamic initialization. Variable manually put into the section may be optimized out and its order relative to compiler generated dynamic initializers is unspecified 16.11
      /w15249 # 'bitfield' of type 'enumeration_name' has named enumerators with values that cannot be represented in the given bit field width of 'bitfield_width'. 17.0
      /w35250 # 'function_name': intrinsic function not declared. 17.0
      # /w45251 # segment-name changed after including header 17.1
      # /w45254 # language feature 'terse static assert' requires compiler flag '/std:c++17' 17.1
      ################################
      # Explicitly disabled warnings
      /wd4702 # unreachable code: triggered in STL
      /wd4996 # code uses a function, class member, variable, or typedef that's marked deprecated: triggered in STL
    )
endmacro()

# CLANG warning flags
macro(custom_clang_cxx_warning_flags_init)
    set(CUSTOM_CLANG_CXX_WARNING_FLAGS
      ################################
      # https://clang.llvm.org/docs/DiagnosticsReference.html
      -Wlifetime
      -pedantic
      -Wall
      -Wextra
      -Wpedantic
      -Wbad-function-cast
      -Wcomma
      -Wcomment
      -Wcomplex-component-init
      -Wconditional-uninitialized
      -Wcovered-switch-default
      -Wcstring-format-directive
      -Wdelete-non-virtual-dtor
      -Wdeprecated
      -Wdollar-in-identifier-extension
      -Wdouble-promotion
      -Wduplicate-enum
      -Wduplicate-method-arg
      -Wembedded-directive
      -Wexpansion-to-defined
      -Wfloat-conversion
      -Wfloat-equal
      -Wfor-loop-analysis
      -Wformat-pedantic
      -Wgnu
      -Wimplicit-fallthrough
      -Winfinite-recursion
      -Winvalid-or-nonexistent-directory
      -Wkeyword-macro
      -Wmain
      -Wmethod-signatures
      -Wmicrosoft
      -Wmismatched-tags
      -Wmissing-field-initializers
      -Wmissing-method-return-type
      -Wmissing-prototypes
      -Wmissing-variable-declarations
      -Wnested-anon-types
      -Wnon-virtual-dtor
      -Wnonportable-system-include-path
      -Wnull-pointer-arithmetic
      -Wnullability-extension
      -Wold-style-cast
      -Woverriding-method-mismatch
      -Wpacked
      -Wpedantic
      -Wpessimizing-move
      -Wredundant-move
      -Wreserved-id-macro
      -Wself-assign
      -Wself-move
      -Wsemicolon-before-method-body
      -Wshadow
      -Wshadow-field
      -Wshadow-field-in-constructor
      -Wshadow-uncaptured-local
      -Wshift-sign-overflow
      -Wshorten-64-to-32
      -Wconversion
      -Wsigned-enum-bitfield
      -Wstatic-in-inline
      -Wtautological-compare
      -Wtautological-overlap-compare
      -Wthread-safety
      -Wundefined-reinterpret-cast
      -Wuninitialized
      -Wunreachable-code
      -Wunreachable-code-aggressive
      -Wunused-const-variable
      -Wunused-lambda-capture
      -Wunused-local-typedef
      -Wunused-parameter
      -Wunused-private-field
      -Wunused-template
      -Wunused-variable
      -Wused-but-marked-unused
      -Wzero-as-null-pointer-constant
      -Wzero-length-array
      ################################
      # Disable
      -Wno-pragmas
      -Wno-variadic-macros
      ################################
      # Errors
      -Wfatal-errors
      #-Werror
      #-pedantic-errors
    )
endmacro()

# GCC warning flags
macro(custom_gcc_cxx_warning_flags_init)
    set(CUSTOM_GCC_CXX_WARNING_FLAGS
      ################################
      # General
      # https://gcc.gnu.org/onlinedocs/gcc/Warning-Options.html
      -Wlifetime
      -pedantic
      -Wall
      -Wextra
      -Wdouble-promotion
      -Wformat=2
      -Wformat-signedness
      -Wnull-dereference
      -Wimplicit-fallthrough
      -Wif-not-aligned
      -Wmissing-include-dirs
      #-Wswitch-default
      #-Wswitch-enum
      -Wswitch-bool
      -Wswitch-unreachable
      #-Wunused-parameter
      -Wuninitialized
      -Wstrict-overflow=5
      -Walloc-zero
      -Wduplicated-branches
      -Wduplicated-cond
      -Wfloat-equal
      -Wshadow
      -Wundef
      -Wcast-qual
      -Wcast-align
      -Wconversion
      -Wsign-conversion
      -Wdate-time
      -Wlogical-op
      -Wmissing-declarations
      -Wredundant-decls
      -Wrestrict
      -Winterference-size
      -Winvalid-pch
      -Wvla
      -Woverlength-strings
      ################################
      # C++ specific
      # https://gcc.gnu.org/onlinedocs/gcc/C_002b_002b-Dialect-Options.html
      -Wcomma-subscript
      -Wctad-maybe-unsupported
      -Wctor-dtor-privacy
      -Wnoexcept
      -Wnon-virtual-dtor
      -Wregister
      -Wredundant-tags
      -Wstrict-null-sentinel
      -Wold-style-cast
      #-Woverloaded-virtual
      -Wmismatched-tags
      -Wvolatile
      -Wzero-as-null-pointer-constant
      -Wextra-semi
      #-Wuseless-cast
      -Wsubobject-linkage
      -Wdelete-incomplete
      ################################
      # Guidelines from Scott Meyers' Effective C++ series of books
      # https://gcc.gnu.org/onlinedocs/gcc/C_002b_002b-Dialect-Options.html
      #-Weffc++
      ################################
      # Suggestions
      -Wsuggest-override
      #-Wsuggest-final-types
      #-Wsuggest-final-methods
      #-Wsuggest-attribute=pure
      #-Wsuggest-attribute=const
      #-Wsuggest-attribute=noreturn
      #-Wsuggest-attribute=format
      ################################
      # Static Analysis
      # https://gcc.gnu.org/onlinedocs/gcc-12.1.0/gcc/Static-Analyzer-Options.html
      #-fanalyzer
      ################################
      # Disable
      -Wno-pragmas
      -Wno-variadic-macros
      ################################
      # Errors
      -Wfatal-errors
      #-Werror
      #-pedantic-errors
    )
endmacro()
