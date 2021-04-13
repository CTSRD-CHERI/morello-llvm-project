"""
Check that when the AArch64 target is used, the disassembler is initialized to
the highest architecture version with all extensions enabled and recognizes all
instructions.
"""

from __future__ import print_function

import lldb
from lldbsuite.test import lldbtest
from lldbsuite.test.decorators import skipIfRemote, no_debug_info_test


class DisassemblyAArch64TestCase(lldbtest.TestBase):

    NO_DEBUG_INFO_TESTCASE = True

    mydir = lldbtest.TestBase.compute_mydir(__file__)

    def check_instruction(self, target, raw_bytes, exp_mnemonic, exp_operands):
        insts = target.GetInstructions(lldb.SBAddress(0, target), raw_bytes)
        inst = insts.GetInstructionAtIndex(0)

        fmt_bytes = [hex(x) for x in raw_bytes]

        if self.TraceOn():
            print("\nRaw bytes: {}".format(fmt_bytes))
            print("Disassembled: {}".format(inst))

        self.assertEqual(
            inst.GetMnemonic(target), exp_mnemonic,
            "Mnemonic of '{}' is disassembled correctly".format(fmt_bytes))
        self.assertEqual(
            inst.GetOperands(target), exp_operands,
            "Operands of '{}' are disassembled correctly".format(fmt_bytes))

    @skipIfRemote
    @no_debug_info_test
    def test_disassembly_aarch64(self):
        """Test disassembling AArch64 instructions from raw bytes."""

        # Create a target from the debugger.
        target = self.dbg.CreateTargetWithFileAndTargetTriple('', 'aarch64')
        self.assertTrue(target, lldbtest.VALID_TARGET)

        # Check ARMv8-A instructions:
        # Base set.
        self.check_instruction(target, bytearray([0x20, 0x00, 0x80, 0xd2]),
                               'mov', 'x0, #0x1')
        # Advanced SIMD.
        self.check_instruction(target, bytearray([0x20, 0x84, 0xe2, 0x5e]),
                               'add', 'd0, d1, d2')
        # Floating point.
        self.check_instruction(target, bytearray([0x20, 0xc0, 0x20, 0x1e]),
                               'fabs', 's0, s1')
        # Cryptographic instructions.
        self.check_instruction(target, bytearray([0x20, 0x08, 0x28, 0x5e]),
                               'sha1h', 's0, s1')
        # CRC checksum instructions.
        self.check_instruction(target, bytearray([0x20, 0x40, 0xc2, 0x1a]),
                               'crc32b', 'w0, w1, w2')

        # Check ARMv8.1-A instructions.
        # Rounding Double Multiply Add/Subtract.
        self.check_instruction(target, bytearray([0x20, 0x84, 0x82, 0x7e]),
                               'sqrdmlah', 's0, s1, s2')
        # Large System Extension atomic instructions.
        self.check_instruction(target, bytearray([0x41, 0x7c, 0xe0, 0x88]),
                               'casa', 'w0, w1, [x2]')

        # Check ARMv8.2-A instructions.
        # Full FP16.
        self.check_instruction(target, bytearray([0x20, 0xc0, 0xe0, 0x1e]),
                               'fabs', 'h0, h1')
        # Reliability, Availability and Serviceability extensions.
        self.check_instruction(target, bytearray([0x1f, 0x22, 0x03, 0xd5]),
                               'esb', '')
        # Statistical Profiling extension.
        self.check_instruction(target, bytearray([0x3f, 0x22, 0x03, 0xd5]),
                               'psb', 'csync')

        # Check Morello instructions.
        self.check_instruction(target, bytearray([0xd9,0x3c,0xda,0xc2]),
                               'csel', 'c25, c6, c26, lo')

        # Make sure we can still disassemble the base AArch64 set.
        self.check_instruction(target, bytearray([0x20, 0x00, 0x80, 0xd2]),
                               'mov', 'x0, #0x1')
