--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Markdown.Documents;
with Markdown.Renderer;
with Markdown.Parsers.Enable_GFM;
with Markdown.Styles;

with VSS.String_Vectors;

package body Testsuite.Elements is

   procedure Parse
     (Parser : in out Markdown.Parsers.Markdown_Parser;
      Source : VSS.String_Vectors.Virtual_String_Vector);

   procedure Set_Styles (Renderer : in out Markdown.Renderer.Renderer);

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

   ------------
   -- Header --
   ------------

   procedure Header (T : in out Trendy_Test.Operation'Class) is
   begin
      T.Register;

      declare
         Context : constant Cairo.Cairo_Context :=
          Testsuite.Create_Cairo_Context (800, 600);

         Parser   : Markdown.Parsers.Markdown_Parser;
         Renderer : Markdown.Renderer.Renderer;
      begin
         Set_Styles (Renderer);
         Parse (Parser, ["# `Header 1`"]);

         Renderer.Render
           (Context  => Context,
            Document => Parser.Document);
         Assert (T, Context, "header.png");
      end;
   end Header;

   -----------
   -- Parse --
   -----------

   procedure Parse
     (Parser : in out Markdown.Parsers.Markdown_Parser;
      Source : VSS.String_Vectors.Virtual_String_Vector) is
   begin
      Markdown.Parsers.Enable_GFM (Parser);

      for Line of Source loop
         Parser.Parse_Line (Line);
      end loop;
   end Parse;

   ----------------
   -- Set_Styles --
   ----------------

   procedure Set_Styles (Renderer : in out Markdown.Renderer.Renderer) is
   begin
      declare
         Style : Markdown.Styles.Style;
      begin
         Style.Set_Font_Family ("Courier New");
         Renderer.Set_Code_Span_Style (Style);
      end;
   end Set_Styles;

end Testsuite.Elements;