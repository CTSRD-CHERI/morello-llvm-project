=========
CHERIseed
=========

.. contents::

  :local:

Introduction
============

CHERIseed is a software-only implementation of
`CHERI <https://www.cl.cam.ac.uk/research/security/ctsrd/cheri/>`_
semantics.

The aim of CHERIseed is to facilitate the porting effort of existing
code to CHERI hardware platforms, by providing some of the
functionality while running on a host machine that is not capability
aware. This functionality includes:

* 128-bit pointers for a 64-bit address space (64 bits of "metadata").
* Bounds checking on pointer dereferences.
* Permissions checking for pointers where permissions are restricted.

By compiling and running code with CHERIseed a user can experiment
with CHERI programming (see the
`CHERI C/C++ Programming Guide <https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-947.pdf>`_),
and identify potentially unsafe code that would fault on real CHERI
hardware. CHERIseed does not provide the same security guarantees as
CHERI hardware, and should not be used as a security-enforcing tool.

CHERIseed is a Work in Progress. Please see the :ref:`Limitations <cheriseed.limitations>`
below for unsupported functionality.

If you would like to contribute to CHERIseed, please read the
:ref:`Contribution Guide <cheriseed.contributing>` below.

Getting Started
===============

See `Getting Started: Building and Running Clang <https://clang.llvm.org/get_started.html>`_
for the System Requirements and instructions for how to generate a build system
for CHERIseed-enabled clang with ``CMake``.

To generate the documentation as html use

CMake option ``-DLLVM_ENABLE_PROJECTS="clang;compiler-rt"`` is
required to allow building the CHERIseed compiler-rt.

CMake option ``-DLLVM_TARGETS_TO_BUILD="X86;AArch64"`` is
recommended, to avoid build errors from other target platforms.

.. note::

  clang >= 10.0.0 is required. To force CMake to use a particular
  compiler binary use

  -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++

Once cmake has finished generating the build files, the targets to
build are:

.. code-block:: bash

  make clang compiler-rt

When the build completes, ``build/bin/`` will contain ``clang`` that
is compatible with ``-fsanitize=cheriseed``.

Pure Capability Example
-----------------------

"Pure Capability" (``purecap``) mode indicates that all pointers should
automatically be represented as a capability, without the need
for ``__capability`` annotations.

``purecap`` mode can be enabled by passing the argument
``-mabi=purecap`` to clang. This is a **new ABI**, so requires a
CHERIseed-aware ``libc``. To compile with the pure-capability ABI
enabled you must first obtain a ported, pure-capability ABI version of
the following libraries:

* `musl-libc <https://git.morello-project.org/morello/musl-libc/-/tree/cheriseed>`_
* `libshim <https://git.morello-project.org/morello/android/platform/external/libshim/-/tree/cheriseed>`_

Each should be placed in adjacent directories to ``llvm-project/``.

The following configuration should be exported to the environment:

.. code-block:: bash

  export CC=<path-to>/llvm-project/build/bin/clang
  export AR=$(which ar)
  export RANLIB=$(which ranlib)

  export TARGET_ARCH=$(uname -m)
  export TARGET_TRIPLE=${TARGET_ARCH}-linux-musl
  export MUSL_PREFIX=<path-to>/musl-libc/obj/install/${TARGET_TRIPLE}
  export LIBSHIM_DIR=<path-to>/libshim/

Then call the ``configure`` tool in ``musl-libc/`` with the following arguments

.. code-block:: bash

  ./configure --disable-shared --disable-morello \
    --enable-cheriseed --libshim-path=${LIBSHIM_DIR} \
    --target=${TARGET_TRIPLE} \
    --prefix=${MUSL_PREFIX}

And finally:

.. code-block:: bash

  make -j$(nproc) install

The result of this should be:

.. code-block:: bash

  > ls ${MUSL_PREFIX}
  bin  include  lib  share

You can now compile ``purecap`` source code with the following:

.. code-block:: bash

  ${CC} \
  --target=${TARGET_TRIPLE} \
  -rtlib=compiler-rt \
  --sysroot="${MUSL_PREFIX}" \
  -lc -lpthread -lm -lrt \
  -fsanitize=cheriseed \
  -mabi=purecap \
  -static \
  -Wno-unused-command-line-argument \
  -g3 \
  <filename.c>

An example C program to demonstrate a violation of capability bounds
is provided below.

bounds.c
########

.. code-block:: C

  #include <stdio.h>
  #include <sanitizer/cheriseed_interface.h>

  int main(void) {
    int A[2] = { 1, 2 };

    printf("A[0]: %d\n", A[0]);
    printf("A[1]: %d\n", A[1]);
    printf("A[2]: %d\n", A[2]); // Also try A[-1]

    return 0;
  }

When run this should result something similar to:

.. code-block:: console

  > ./bounds.o
  A[0]: 1
  A[1]: 2

  ================================================================
  Runtime Error detected by CHERIseed

  Prevented out-of-bounds access with capability at 0x7ffdcfe62020:

    0x7ffdcfe620c0 [rwRW,0x7ffdcfe620b8-0x7ffdcfe620c0]

  Requested range was 0x7ffdcfe620c0-0x7ffdcfe620c4

  tid: 52733
  pc:  0x00000045c03a
  ================================================================


To read more about the capability string representation used,
see `Displaying Capabilities <https://github.com/CTSRD-CHERI/cheri-c-programming/wiki/Displaying-Capabilities#simplified-format>`_.

To retrieve or modify the properties of a capability, see Sections
7.2 and 7.3 of the
`CHERI C/C++ Programming Guide <https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-947.pdf>`_.

.. note::

  CHERIseed code generation may not be optimal, and performance is not
  representative of real CHERI hardware.

Behavior on a semantic rules violation
======================================

When CHERIseed detects that capability semantics have been violated at
runtime, a SIGSEV or SIGBUS signal will be raised, depending on the
nature of the violation.

When ``SIGSEGV`` is raised the following ``si_code`` are possible:

- ``SEGV_CAPBOUNDSERR``: Attempted an out-of-bounds access.
- ``SEGV_CAPPERMERR``: Attempted an access without the required permissions.
- ``SEGV_MAPERR``: Attempted to dereference a capability at an invalid address.

When ``SIGBUS`` is raised the following ``si_code`` are possible:

- ``BUS_ADRALN``: Alignment of a capability is invalid.

These signals can be trapped by the application.

Configuring Behaviour
---------------------

The default behaviour of CHERIseed upon encountering a violation of
capability semantics is:

1. Call the signal handler associated with the signal directly
   (if one has been defined).
2. Print the details of the violation.
3. Raise SIGTRAP if the process has an attached tracer.
4. Terminate the process.

This can be configured at runtime.

The API ``__cheriseed_control_semantics()`` enables or disables all CHERI
semantics at once. To fine-grain control which checks are performed at
runtime use ``__cheriseed_control_checks()`` API. The first argument specifies
if the checks set in the second argument are to be enabled or disabled.

.. note::

  Disabling CHERI semantics for some short scope will likely produce
  unexpected results.

The environment variable ``CHERISEED_CHECKS`` can be used to control how
CHERIseed behaves without the need to recompile the application. It takes a
comma separated list of options which control various checks.

The recognized options are:

* ``TAG``: controls whether tag checks are executed
* ``BOUNDS``: controls whether bounds checks are executed
* ``ALIGNMENT``: controls whether alignment of capabilities are checked
* ``PERMS``: controls whether permission checks are executed
* ``ALL``: enables all checks

To opt out a check simply prefix it with a ``-`` character.

The API ``__cheriseed_control_checks()`` allows the use of the usual
CHERI-defined permissions. For example, to control whether
``__CHERI_CAP_PERMISSION_PERMIT_LOAD__`` is checked, simply use ``[-]LOAD`` as
a named option. This goes similarly with other permissions which CHERIseed
implements.

Calling signal handlers can be enabled and disabled using the
``__cheriseed_control_invoke_signal_handlers()`` public API.

If calling signal handlers is enabled, the
``__cheriseed_set_signal_handle_mode()`` API can be used to configure
how the current violation should be handled using a few predefined macros:

- ``CHERISEED_SIGNAL_HANDLE_MODE_DEFAULT``: the default behavior detailed
  above.
- ``CHERISEED_SIGNAL_HANDLE_MODE_SILENT``: like default, but no message is
  shown on ``stderr``.
- ``CHERISEED_SIGNAL_HANDLE_MODE_IGNORE``: the signal is completely ignored.
- ``CHERISEED_SIGNAL_HANDLE_MODE_WARNING``: like ignore, but the nature
  of the violation is shown on ``stderr``.

If calling signal handlers is disabled, a violation always results in
termination of the application.

The runtime API ``__cheriseed_strerror()`` can be used to return the string
representation of the new ``SEGV_CAP*`` values, or ``UNKNOWN``.

Supported Platforms
===================

CHERIseed is compatible with any 64-bit platform, but is currently only enabled
for Linux on aarch64 and x86-64.

Enabling CHERIseed for other 64-bit platforms is expected to be relatively easy,
however there are currently no plans for any work towards this goal.

Design
======

Please refer to the :doc:`Design Document<CHERIseedDesign>`.

.. _cheriseed.limitations:

Limitations
===========

Dependency on libshim
---------------------

CHERIseed requires that libshim is available in both hybrid and pure-capability
ABIs. This constraint not only gives CHERIseed runtime library a stable
interface, but ensures that CHERIseed works correctly very early during program
startup, even before libc is initialized.

Hybrid Mode
-----------

Compiling code without ``-mabi=purecap``, meaning only pointers with
the ``__capability`` attribute will be treated as capabilities, is
possible but not recommended. Potential use cases for Hybrid
CHERIseed are still being explored to justify supporting this feature.

Multi-threading
---------------

Thread safety is not guaranteed, so multi-threaded programs are not
supported yet.

Inline Assembly
---------------

Inline assembly snippets are treated as "unsafe" from CHERIseed's
point of view, because it can not reason about how input values are used.
Therefore, only raw pointers are passed to inline assembly snippets and only
raw pointers are expected to be returned, never capabilities.

.. warning::

  If inline assembly uses pointers, including dereferencing, loading
  from or storing to memory, it can not be guaranteed that it will
  work with CHERIseed. Please review such snippets in advance to avoid
  lengthy debug sessions later on. Alternatively, consider using
  higher-level builtins instead.

The CHERIseed Module Pass will emit a warning whenever it encounters
an inline assembly snippet and it cannot reason about its safety.
This warning can be disabled with `-mllvm -cheriseed-no-inline-asm` or
`-Wno-inline-asm` (more coarse grained) flags. The only exception is when an
inline assembly snippet is an empty string (apart from whitespace characters),
which doesn't have capabilities specified in output operands. This exception
supports compiler barriers.

Signal Handlers
---------------

Use of the alternate signal stack, set by ``sigaltstack(2)``, is not
respected when the runtime library calls signal handlers.

The third argument passed to signal handlers installed with
``SA_SIGINFO`` is just opaque memory passed to user code. It
doesn't provide any details and should not be used except for passing
it to ``__cheriseed_set_signal_handle_mode()``.

Permissions
-----------

Only those permissions listed in Section 7.4 of the
`CHERI C/C++ Programming Guide <https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-947.pdf>`_
are supported by CHERIseed:

* CHERI_PERM_EXECUTE
* CHERI_PERM_LOAD
* CHERI_PERM_LOAD_CAP
* CHERI_PERM_STORE
* CHERI_PERM_STORE_CAP

Exact Bounds
------------

Pointers to large objects may have their bounds
widened in order to be representable in the compressed capability
format. The final bounds will never exceed the bounds prior to an
operation (Monotonicity).

Usually the CHERI builtin:

.. code-block:: C

  void *cheri_bounds_set_exact(void *c, size_t x)

would be used to ensure that bounds are exact, however this feature
is not yet available. ``cheri_bounds_set_exact`` is functionally
identical to ``cheri_bounds_set`` at this time.

CHERI builtin functions ``cheri_representable_length`` and
``cheri_representable_alignment_mask`` are implemented, and can
be used to determine a precisely representable allocation.

Read more in Section 7.5 of the
`CHERI C/C++ Programming Guide <https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-947.pdf>`_.

.. _cheriseed.contributing:

Contributing
============

Thank you for your interest in contributing to CHERIseed! There are
many ways to contribute, and we appreciate any contributions.

Any contributions to CHERIseed should be generic to all CHERI
platforms, rather than specific to a certain CHERI implementation.

Testing
-------

Please include a small test with any contributions. Tests for the
compiler-rt should be added to  ``compiler-rt/lib/cheriseed/tests/``,
and can be run by building the target ``CHERIseedUnitTests`` in
``llvm-project/``, then running:

.. code-block:: bash

  ./projects/compiler-rt/lib/cheriseed/tests/CHERIseed-$(uname -m)-NoInst-Test

Tests for the sanitizer pass should be added to
``llvm/test/Instrumentation/CHERIseed/``. They can be run from the
build directory using ``lit``:

.. code-block:: bash

  ./bin/llvm-lit ../llvm/test/Instrumentation/CHERIseed/

Submission Guidelines
---------------------

Please ensure that any patches submitted are:
 * Aligned with the
   `LLVM Coding Standards <https://llvm.org/docs/CodingStandards.html>`_
   (`clang-format <https://reviews.llvm.org/source/llvm-github/browse/main/clang/tools/clang-format>`_)
   can be used to format correctly).
 * Free from unrelated changes.
 * Independent. Separate changes should be submitted as separate
   patches, as this makes reviewing easier.

Raising issues and submitting patches should be done via the
Morello `gitlab <https://git.morello-project.org/morello/llvm-project/>`_.
