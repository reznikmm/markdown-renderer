--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Markdown.Documents;
with Markdown.Renderer;

package body Testsuite.Elements is

   -----------
   -- Empty --
   -----------

   procedure Empty (T : in out Trendy_Test.Operation'Class) is
   begin
      T.Register;
      T.Assert (True);
   end Empty;

end Testsuite.Elements;