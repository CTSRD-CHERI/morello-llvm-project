"""
Make sure expr is disabled for AArch64 unless target.force-expr-evaluation is
set to true.
"""



import unittest2

import lldb
from lldbsuite.test.decorators import *
from lldbsuite.test.lldbtest import *
from lldbsuite.test import lldbutil


class ExprAArch64CommandsTestCase(TestBase):

    mydir = TestBase.compute_mydir(__file__)

    def setUp(self):
        # Call super's setUp().
        TestBase.setUp(self)

        # Disable confirmation prompt to avoid infinite wait
        self.runCmd("settings set auto-confirm true")
        self.addTearDownHook(
            lambda: self.runCmd("settings clear auto-confirm"))

        # Save host platform so we can restore it if we change it in some of the
        # tests (e.g. by creating aarch64 targets on non-aarch64 hosts).
        self.original_platform = self.dbg.GetSelectedPlatform()
        self.addTearDownHook(
            lambda: self.dbg.SetSelectedPlatform(self.original_platform))

    def test_expr_disabled_for_aarch64(self):
        target = self.dbg.CreateTargetWithFileAndArch(None, 'aarch64')
        self.assertTrue(target, VALID_TARGET)

        self.expect("settings show target.force-expr-evaluation",
                substrs=["target.force-expr-evaluation (boolean) = false"])
        self.expect("expression 22",
                substrs=["Expression evaluation is disabled for AArch64"],
                error=True)

        self.runCmd("settings set target.force-expr-evaluation true")
        self.expect("expression 22",
                substrs=["(int) $0 = 22"])

        self.runCmd("settings set target.force-expr-evaluation false")
        self.expect("expression 22",
                substrs=["Expression evaluation is disabled for AArch64"],
                error=True)

        self.dbg.DeleteTarget(target)
