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

      declare
         Context : constant Cairo.Cairo_Context :=
          Testsuite.Create_Cairo_Context (800, 600);

         Document : Markdown.Documents.Document;

         Renderer : Markdown.Renderer.Renderer;
      begin
         Renderer.Render
           (Context  => Context,
            Document => Document);
         Assert (T, Context, "empty.png");
      end;
   end Empty;

end Testsuite.Elements;