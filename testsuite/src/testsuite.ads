--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Cairo;

with Trendy_Test;

package Testsuite is

   function Create_Cairo_Context
     (Width, Height : Positive) return Cairo.Cairo_Context;

   procedure Assert
     (Operation : in out Trendy_Test.Operation'Class;
      Context   : Cairo.Cairo_Context; File : String);

end Testsuite;
