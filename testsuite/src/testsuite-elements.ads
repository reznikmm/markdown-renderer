--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Trendy_Test;

package Testsuite.Elements is

   Tests : constant Trendy_Test.Test_Group;

private

   procedure Empty (T : in out Trendy_Test.Operation'Class);
   procedure Header (T : in out Trendy_Test.Operation'Class);
   procedure Para (T : in out Trendy_Test.Operation'Class);
   procedure List (T : in out Trendy_Test.Operation'Class);
   procedure Code_Block (T : in out Trendy_Test.Operation'Class);

   Tests : constant Trendy_Test.Test_Group :=
    [Empty'Access, Header'Access, Para'Access, List'Access, Code_Block'Access];

end Testsuite.Elements;
