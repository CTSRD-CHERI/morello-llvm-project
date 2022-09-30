==============================
CHERIseed Design Documentation
==============================

.. contents::
   :local:

Introduction
============

CHERIseed is made up of an LLVM Module Pass and a Compiler-RT
Runtime.

Module Pass
-----------

The Module Pass takes in LLVM IR that has already been generated
for CHERI, and replaces any LLVM IR instructions where the hardware
would otherwise be required to utilise capabilities. This allows the
resulting binary to still be executable on conventional platforms
(x86_64, AArch64).

Any pointers that are annotated as capabilities are **replaced with a
pointer to a capability object in memory**, that holds the address of
the original target. In the ``purecap`` case this will be all pointers.

Capabilities have the following structure in memory:

.. code-block:: C

  typedef struct {
      uint64_t value;
      uint64_t metadata;
  } __cheriseed_cap_t __attribute__((aligned(16)));

``value`` holds the memory address of the target, while ``metadata``
contains compressed bounds and permissions information, that can
be understood by the compiler runtime.

Any CHERI APIs for retrieving, modifying, or restricting capability
properties are replaced with calls to equivalent functions in the
compiler runtime.

Compiler Runtime
----------------

Provides software implementations of CHERI APIs, as listed in
`cheriintrin.h <https://git.morello-project.org/morello/llvm-project/-/blob/morello/dev/clang/lib/Headers/cheriintrin.h>`_.
Most have their functionality defined by the
`CHERI C/C++ Programming Guide <https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-947.pdf>`_.
For some that are ommited from the programming guide (e.g. ``subset_test``)
the functionality has been deduced from the builtin name, while others
(e.g. ``seal``) are unimplemented, pending inclusion in the programming guide.

The metadata of CHERIseed capabilities is compressed into a 64-bit
value using
`cheri-compressed-cap <https://github.com/CTSRD-CHERI/cheri-compressed-cap>`_.
This includes bounds and permissions information for the memory pointed
to by the capability.

The compiler-rt also provides some CHERIseed specific APIs. Some of
these are only expected to be used by the compiler, such as
``__cheriseed_check_access``, to assert that the following action is
permitted by a given capability's permissions and bounds.
Other APIs are user-accessible, to tweak the functionality, for
example ``__cheriseed_strerror`` to retrieve the string representation
of a CHERIseed error code.

See ``compiler-rt/include/sanitizer/cheriseed_interface.h`` for a
full description of all provided APIs.

Implementation Details
======================

Initialization
--------------

The sanitizer runtime must be initialized by calling
``__cheriseed_static_init()`` early during process startup.

ABI Changes
-----------

CHERIseed strongly requires capability alignment, therefore when
execution is interrupted and the next PC is explicitly set, which may
occur in signal handlers, the destination must use
``force_align_arg_pointer`` in order to ensure proper stack alignment.

Null Capability Representation
------------------------------

A null capability can have two different representations, depending on
the context:

#. If a runtime call has a `nullptr` input for a capability, it is
   treated as null capability. Typical cases is when the compiler
   emits a GEP or a CHERI intrinsic call with a `null` argument.

#. If the raw pointer to the capability points to an all-zero memory
   location, it is also a null capability.

API calls will behave as follows if either null capability
representation is passed as the argument:

* ``cheri_address_get``: returns ``0``.
* ``cheri_base_get`` : returns ``0``.
* ``cheri_length_get`` : returns ``UINT64_MAX``.
* ``cheri_offset_get`` : returns ``0``.
* ``cheri_perms_get`` : returns ``0``, or no permissions.
* All remaining APIs, that modify capabilities, will result in a
  capability with fields as above, apart from the field it modifies.

Atomic Support
--------------

Atomics are currently supported for single-threaded cases. There is
also some difference in the generated code depending on what the base
type is and what type is being atomically accessed:

1. If the base of the operation is a raw pointer and the operation
   involves non-capability type, the generated code is unchanged.
2. If the base of the operation is a capability, and the operation
   involves non-capability type, the generated code will first check
   if the access would not result in a capability violation, then the
   address of the capability is extracted. The rest of the code is the
   same as for case 1.
3. Finally, if the type involved in the operation is a capability a
   dedicated runtime call is emitted, which handles the atomic
   operation.

Global Variables
----------------

Capabilities in global variables and aliases are initialized at runtime
by invoking ``__cheriseed_relocate()``.

Variadic Arguments
------------------

Variadic arguments are supported in a generic, architecture agnostic
way. They are *exclusively* passed on-stack via an additional capability
argument, referred to as ``va_slot``.

The pass modifies the calling convention of variadic functions such that
the ellipsis (``...``) are replaced by ``va_slot``, which is always the
last argument of the function call and points to an allocated stack slot
where the pass stores the 16-byte aligned variadic arguments. Variadic
arguments ``<=`` 16-bytes are stored directly in the stack slot;
variadic arguments ``>`` 16-bytes are stored indirectly via a
capability. ``va_slot`` is NULL if there are no variadic arguments.

Function pointers
-----------------

Function pointers are represented as capabilities and they are derived
from PCC. The bounds are restricted in a way so that attempting to dereference
a function pointer at any other address (skipping instructions) will cause a
bounds error, for example:

.. code-block:: C

  typedef void (*fun_ptr_t)(void);

  void func(void) {
    char *ptr = (char *)&func;
    ++ptr;
    fun_ptr_t fptr = (fun_ptr_t)ptr;
    fptr(); // <-- bounds violation
  }

Calling signal handlers
-----------------------

The runtime may call signal handlers directly, depending on runtime
configuration. These calls have the same properties as if the kernel did so:
the current signal is blocked, unless SA_NODEFER was set, and the signals set
in :code:`sigaction.sa_mask` are blocked. The only difference is that the
runtime will not switch to the alternative signal stack, if set.

Capability Tags
---------------

The runtime maps a small chunk of memory called *shadow memory* during startup
initialization. A tag associated with each memory location that can hold
capability is represented with an 8-bit value stored within this
*shadow memory*. A capability is valid if its tag value is 1, and invalid if 0.

* Shadow Memory:
  A Shadow memory is a mapped accessible memory region which is used to store
  all tags associated to all possible capabilities in the memory.
* Shadow Gap:
  A Shadow Gap is the unaccessible memory region within the shadow memory which
  includes region which is not associated to any accessible capabilities,i.e,
  it is the region mapped to shadow memory.

The 8-bit values in the shadow memory can also have an additional value
representing the locked state of a capability. This is used as "spinlock" for
atomic capability operations. Following are the possible values in
shadow memory:

* Cleared: If the value is 0, it means the tag is cleared. The associated memory
  location contains invalid capability.
* Set: If the value is 1, it means the tag is set. The associated memory
  location contains valid capability.
* Locked: If the value is 2, it means that the associated memory location
  contains capability with unspecified status; memory access is in progress.

Possible directions of future work
==================================

This section lists some possible directions of futher development.

Atomics
-------

Support for Atomic Capability operations still needs to be implemented,
as well as further support for other atomics.

Assembly
--------

Introducing support for a ``no_sanitize`` function declaration (or similar)
would provide better support for calling assembly.
