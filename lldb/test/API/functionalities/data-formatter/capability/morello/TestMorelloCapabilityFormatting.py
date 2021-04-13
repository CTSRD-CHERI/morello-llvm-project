"""
Check that capabilities are formatted properly.
"""

from __future__ import print_function

import os

import lldb
from lldbsuite.test import lldbtest
from lldbsuite.test import lldbutil


class CapabilityFormattingTestCase(lldbtest.TestBase):

    mydir = lldbtest.TestBase.compute_mydir(__file__)

    def check_capability_format(self, frame, expr, expect):
        val = frame.EvaluateExpression(expr)
        val.SetFormat(lldb.eFormatCapability)
        self.assertEqual(val.GetValue(), expect,
                         "'{}' is formatted properly".format(expr))


    def test_morello_with_run_command(self):
        """Check that Morello capabilities are formatted properly."""

        self.build()
        exe = self.getBuildArtifact('a.out')

        # Create a target from the debugger.
        target = self.dbg.CreateTarget(exe)
        self.assertTrue(target, lldbtest.VALID_TARGET)

        # Create the breakpoint.
        filespec = lldb.SBFileSpec('main.cpp', False)
        breakpoint = target.BreakpointCreateBySourceRegex(
            '// break here', filespec)
        self.assertTrue(breakpoint, lldbtest.VALID_BREAKPOINT)

        # Now launch the process, and do not stop at the entry point.
        process = target.LaunchSimple(
            None, None, self.get_process_working_directory())
        self.assertTrue(process, lldbtest.PROCESS_IS_VALID)
        self.assertEqual(process.GetState(), lldb.eStateStopped,
                         lldbtest.STOPPED_DUE_TO_BREAKPOINT)

        thread = lldbutil.get_one_thread_stopped_at_breakpoint(
            process, breakpoint)
        self.assertIsNotNone(
            thread, "Expected one thread to be stopped at the breakpoint")

        frame = thread.GetFrameAtIndex(0)


        # Permissions tests.
        self.check_capability_format(
            frame, 'permissions_load',
            "{address = 0x0000000000000000, attributes = {[Load], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_store',
            "{address = 0x0000000000000000, attributes = {[Store], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_execute',
            "{address = 0x0000000000000000, attributes = {[Execute], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_loadcap',
            "{address = 0x0000000000000000, attributes = {[LoadCap], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_storecap',
            "{address = 0x0000000000000000, attributes = {[StoreCap], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_storelocalcap',
            "{address = 0x0000000000000000, attributes = {[StoreLocalCap], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_seal',
            "{address = 0x0000000000000000, attributes = {[Seal], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_unseal',
            "{address = 0x0000000000000000, attributes = {[Unseal], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_system',
            "{address = 0x0000000000000000, attributes = {[System], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_branchunseal',
            "{address = 0x0000000000000000, attributes = {[BranchSealedPair], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_compartmentid',
            "{address = 0x0000000000000000, attributes = {[CompartmentID], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_mutableload',
            "{address = 0x0000000000000000, attributes = {[MutableLoad], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_user3',
            "{address = 0x0000000000000000, attributes = {[User3], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_user2',
            "{address = 0x0000000000000000, attributes = {[User2], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_user1',
            "{address = 0x0000000000000000, attributes = {[User1], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_user0',
            "{address = 0x0000000000000000, attributes = {[User0], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_executive',
            "{address = 0x0000000000000000, attributes = {[Executive], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_global',
            "{address = 0x0000000000000000, attributes = {[Global], range = [0x0-0x0)}}")

        self.check_capability_format(
            frame, 'permissions_none',
            "{address = 0x0000000000000000, attributes = {[], range = [0x0-0x0)}}")
        self.check_capability_format(
            frame, 'permissions_several',
            "{address = 0x0000000000000000, attributes = {[Global User0 User1 User2 User3 MutableLoad CompartmentID Unseal StoreLocalCap Execute Load], range = [0x0-0x0)}}")

        # Object type tests.
        self.check_capability_format(
            frame, 'sealed_max_otype',
            "{address = 0x0000000000000000, attributes = {[Sealed Global Store Load], otype = 0x7fff, range = [0x0-0x0)}}")

        self.check_capability_format(
            frame, 'sealed_no_perms',
            "{address = 0x0000000000000000, attributes = {[Sealed], otype = 0x77dc, range = [0x0-0x0)}}")

        self.check_capability_format(
            frame, 'sealed_all_perms',
            "{address = 0x0000000000000000, attributes = {[Sealed Global Executive User0 User1 User2 User3 MutableLoad CompartmentID BranchSealedPair System Unseal Seal StoreLocalCap StoreCap LoadCap Execute Store Load], otype = 0xa0, range = [0x0-0x0)}}")

        # Address tests.
        self.check_capability_format(
            frame, 'address_zero_flags',
            "{address = 0x00deadbeef000000, attributes = {[], range = [0xdeadbeef000000-0xdeadbeef000000)}}")
        self.check_capability_format(
            frame, 'address_nonzero_flags',
            "{address = 0x9d0000ffff00aaaa, attributes = {[], range = [0x9d0000ffff000000-0x9d0000ffff000000)}}")

        # Bounds tests.
        self.check_capability_format(
            frame, 'bounds_noie_zero',
            "{address = 0x0000000000000000, attributes = {[], range = [0x0-0x0)}}")

        self.check_capability_format(
            frame, 'bounds_noie_nocarry_gt',
            "{address = 0x000000000000c000, attributes = {[], range = [0xba52-0xba54)}}")
        self.check_capability_format(
            frame, 'bounds_noie_nocarry_eq',
            "{address = 0x0000000000000000, attributes = {[], range = [0x1284-0x1284)}}")
        self.check_capability_format(
            frame, 'bounds_noie_carry',
            "{address = 0x0000000000005000, attributes = {[], range = [0x4638-0x8634)}}")
        self.check_capability_format(
            frame, 'bounds_noie_carry_wrap',
            "{address = 0x0000000000000000, attributes = {[], range = [0xffffffffffffe228-0x10000000000002114)}}")

        self.check_capability_format(
            frame, 'bounds_noie_c1',
            "{address = 0x00000000beefe000, attributes = {[], range = [0xbef00002-0xbef00004)}}")
        self.check_capability_format(
            frame, 'bounds_noie_c0',
            "{address = 0x00000000beef0000, attributes = {[], range = [0xbeef0002-0xbeef0004)}}")
        self.check_capability_format(
            frame, 'bounds_noie_c_1',
            "{address = 0x00000000beef2000, attributes = {[], range = [0xbeee6002-0xbeee8004)}}")

        self.check_capability_format(
            frame, 'bounds_noie_c1_wrap',
            "{address = 0xffffffffffffe000, attributes = {[], range = [0x2-0x4)}}")
        self.check_capability_format(
            frame, 'bounds_noie_c_1_wrap',
            "{address = 0x0000000000000000, attributes = {[], range = [0xffffffffffff6002-0xffffffffffff8004)}}")

        self.check_capability_format(
            frame, 'bounds_noie_cb_1',
            "{address = 0x00000000beef2000, attributes = {[], range = [0xbeeec00a-0xbeef0004)}}")
        self.check_capability_format(
            frame, 'bounds_noie_ct1',
            "{address = 0x00000000beefc000, attributes = {[], range = [0xbeefc00b-0xbef00004)}}")

        self.check_capability_format(
            frame, 'bounds_ie_zero',
            "{address = 0x0000000000000000, attributes = {[], range = [0x0-0x4000)}}")
        self.check_capability_format(
            frame, 'bounds_ie_mid',
            "{address = 0x0000000000000000, attributes = {[], range = [0x0-0x200000000)}}")
        self.check_capability_format(
            frame, 'bounds_ie_ge50',
            "{address = 0x0000000000000000, attributes = {[], range = [0x0-0x10000000000000000)}}")

        self.check_capability_format(
            frame, 'bounds_ie_zero_nocarry_gt',
            "{address = 0x000000000000c000, attributes = {[], range = [0xba50-0xfa58)}}")
        self.check_capability_format(
            frame, 'bounds_ie_mid_nocarry_gt',
            "{address = 0x0000000000180000, attributes = {[], range = [0x174a00-0x1f4b00)}}")
        self.check_capability_format(
            frame, 'bounds_ie_ge50_nocarry_gt', "{address = 0x0000000000000000, attributes = {[], range = [0xe940000000000000-0x1e960000000000000)}}")

        self.check_capability_format(
            frame, 'bounds_ie_zero_nocarry_eq',
            "{address = 0x0000000000000000, attributes = {[], range = [0x1280-0x5280)}}")
        self.check_capability_format(
            frame, 'bounds_ie_mid_nocarry_eq',
            "{address = 0x0000000000000000, attributes = {[], range = [0x4a000000000000-0x14a000000000000)}}")
        self.check_capability_format(
            frame, 'bounds_ie_ge50_nocarry_eq',
            "{address = 0x0000000000000000, attributes = {[], range = [0x4a00000000000000-0x14a00000000000000)}}")

        self.check_capability_format(
            frame, 'bounds_ie_zero_carry',
            "{address = 0x0000000000005000, attributes = {[], range = [0x4638-0xc630)}}")
        self.check_capability_format(
            frame, 'bounds_ie_mid_carry',
            "{address = 0x0000050000000000, attributes = {[], range = [0x44638000000-0x4c630000000)}}")
        self.check_capability_format(
            frame, 'bounds_ie_ge50_carry',
            "{address = 0x0000000000000000, attributes = {[], range = [0x18c0000000000000-0x18c0000000000000)}}")

        self.check_capability_format(
            frame, 'bounds_ie_zero_carry_wrap',
            "{address = 0x0000000000000000, attributes = {[], range = [0xffffffffffffa220-0x10000000000002110)}}")
        self.check_capability_format(
            frame, 'bounds_ie_mid_carry_wrap',
            "{address = 0x0000000000000000, attributes = {[], range = [0xfffffffffffa2200-0x10000000000021100)}}")
        self.check_capability_format(
            frame, 'bounds_ie_ge50_carry_wrap',
            "{address = 0x0000000000000000, attributes = {[], range = [0x8880000000000000-0x8440000000000000)}}")

        self.check_capability_format(
            frame, 'bounds_ie_c1',
            "{address = 0x000000beefe00000, attributes = {[], range = [0xbef0000000-0xbef0400000)}}")
        self.check_capability_format(
            frame, 'bounds_ie_c0',
            "{address = 0x000000beef000000, attributes = {[], range = [0xbeef000000-0xbeef400000)}}")
        self.check_capability_format(
            frame, 'bounds_ie_c_1',
            "{address = 0x000000beef200000, attributes = {[], range = [0xbeee600000-0xbeeec00000)}}")

        self.check_capability_format(
            frame, 'bounds_ie_c1_wrap',
            "{address = 0xffffffffffe00000, attributes = {[], range = [0x0-0x400000)}}")
        self.check_capability_format(
            frame, 'bounds_ie_c_1_wrap',
            "{address = 0x0000000000000000, attributes = {[], range = [0xffffffffff600000-0xffffffffffc00000)}}")

        self.check_capability_format(
            frame, 'bounds_ie_cb_1',
            "{address = 0x000000beef200000, attributes = {[], range = [0xbeeec00000-0xbeef000000)}}")
        self.check_capability_format(
            frame, 'bounds_ie_ct1',
            "{address = 0x000000beefc00000, attributes = {[], range = [0xbeefc00000-0xbef0000000)}}")

        self.enableLogChannelsForCurrentTest()
        self.check_capability_format(
            frame, 'bounds_ie_48_fc',
            "{address = 0x0000000000000000, attributes = {[], range = [0xc000000000000000-0x10000000000000000)}}")
        self.check_capability_format(
            frame, 'bounds_ie_49_fc',
            "{address = 0x0000000000000000, attributes = {[], range = [0x8000000000000000-0x0)}}")
        self.check_capability_format(
            frame, 'bounds_ie_50_fc',
            "{address = 0x0000000000000000, attributes = {[], range = [0x0-0x0)}}")

        self.check_capability_format(
            frame, 'all_ones',
            "{address = 0xffffffffffffffff, attributes = {[Sealed Global Executive User0 User1 User2 User3 MutableLoad CompartmentID BranchSealedPair System Unseal Seal StoreLocalCap StoreCap LoadCap Execute Store Load], otype = 0x7fff, range = [0xffffffffffffffff-0xffffffffffffffff)}}")
        self.check_capability_format(
            frame, 'no_perms',
            "{address = 0xffffffffffffffff, attributes = {[Sealed], otype = 0x7fff, range = [0xffffffffffffffff-0xffffffffffffffff)}}")
        self.check_capability_format(
            frame, 'no_otype',
            "{address = 0xffffffffffffffff, attributes = {[Global Executive User0 User1 User2 User3 MutableLoad CompartmentID BranchSealedPair System Unseal Seal StoreLocalCap StoreCap LoadCap Execute Store Load], range = [0xffffffffffffffff-0xffffffffffffffff)}}")
        self.check_capability_format(
            frame, 'no_address',
            "{address = 0x0000000000000000, attributes = {[Sealed Global Executive User0 User1 User2 User3 MutableLoad CompartmentID BranchSealedPair System Unseal Seal StoreLocalCap StoreCap LoadCap Execute Store Load], otype = 0x7fff, range = [0xffffffffffffffff-0xffffffffffffffff)}}")
        self.check_capability_format(
            frame, 'no_bottom',
            "{address = 0xffffffffffffffff, attributes = {[Sealed Global Executive User0 User1 User2 User3 MutableLoad CompartmentID BranchSealedPair System Unseal Seal StoreLocalCap StoreCap LoadCap Execute Store Load], otype = 0x7fff, range = [0x0-0x3fff)}}")
        self.check_capability_format(
            frame, 'no_top',
            "{address = 0xffffffffffffffff, attributes = {[Sealed Global Executive User0 User1 User2 User3 MutableLoad CompartmentID BranchSealedPair System Unseal Seal StoreLocalCap StoreCap LoadCap Execute Store Load], otype = 0x7fff, range = [0xffffffffffffffff-0x10000000000000000)}}")
