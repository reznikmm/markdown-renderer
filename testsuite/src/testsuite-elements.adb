--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Markdown.Blocks.ATX_Headings;
with Markdown.Documents;
with Markdown.Parsers.Enable_GFM;
with Markdown.Renderer;
with Markdown.Styles;

with VSS.String_Vectors;

package body Testsuite.Elements is

   procedure Parse
     (Parser : in out Markdown.Parsers.Markdown_Parser;
      Source : VSS.String_Vectors.Virtual_String_Vector);

   procedure Set_Styles (Renderer : in out Markdown.Renderer.Renderer);

   ----------------
   -- Code_Block --
   ----------------

   procedure Code_Block (T : in out Trendy_Test.Operation'Class) is
   begin
      T.Register (Parallelize => False);

      declare
         Context : constant Cairo.Cairo_Context :=
          Testsuite.Create_Cairo_Context (800, 600);

         Parser   : Markdown.Parsers.Markdown_Parser;
         Renderer : Markdown.Renderer.Renderer;
      begin
         Set_Styles (Renderer);
         Parse
          (Parser,
           ["This is a paragraph. It should be rendered with its style.",
            "",
            "```ada",
            "funtion Miiiiiiin (A, B : Integer) return Integer;",
            "```",
            "",
            "This is a paragraph. It should be rendered with its style.",
            ""]);

         Renderer.Render
           (Context  => Context,
            Width    => 800,
            Height   => 600,
            Document => Parser.Document);
         Assert (T, Context, "code_block.png");
      end;
   end Code_Block;

   -----------
   -- Empty --
   -----------

   procedure Empty (T : in out Trendy_Test.Operation'Class) is
   begin
      T.Register (Parallelize => False);

      declare
         Context : constant Cairo.Cairo_Context :=
          Testsuite.Create_Cairo_Context (800, 600);

         Document : Markdown.Documents.Document;

         Renderer : Markdown.Renderer.Renderer;
      begin
         Renderer.Render
           (Context  => Context,
            Width    => 800,
            Height   => 600,
            Document => Document);
         Assert (T, Context, "empty.png");
      end;
   end Empty;

   ------------
   -- Header --
   ------------

   procedure Header (T : in out Trendy_Test.Operation'Class) is
   begin
      T.Register (Parallelize => False);

      declare
         Context : constant Cairo.Cairo_Context :=
          Testsuite.Create_Cairo_Context (800, 600);

         Parser   : Markdown.Parsers.Markdown_Parser;
         Renderer : Markdown.Renderer.Renderer;
      begin
         Set_Styles (Renderer);
         Parse
          (Parser,
           ["# Header 1. `Code`",
            "## Header 2. *Italic*",
            "### Header 3. **Bold**",
            "#### Header 4"]);

         Renderer.Render
           (Context  => Context,
            Width    => 800,
            Height   => 600,
            Document => Parser.Document);
         Assert (T, Context, "header.png");
      end;
   end Header;

   ----------
   -- List --
   ----------

   procedure List (T : in out Trendy_Test.Operation'Class) is
   begin
      T.Register (Parallelize => False);

      declare
         Context : constant Cairo.Cairo_Context :=
          Testsuite.Create_Cairo_Context (800, 600);

         Parser   : Markdown.Parsers.Markdown_Parser;
         Renderer : Markdown.Renderer.Renderer;
      begin
         Set_Styles (Renderer);
         Parse
          (Parser,
           ["- Item 1",
            "- Item 2 with `code`",
            "- Item 3 with *italic* text",
            "- Item 4 with **bold** text",
            "",
            "1. First ordered item",
            "2. Second ordered item with `code`",
            "3. Third ordered item with *italic* text",
            "4. Fourth ordered item with **bold** text"]);
         Renderer.Render
           (Context  => Context,
            Width    => 800,
            Height   => 600,
            Document => Parser.Document);
         Assert (T, Context, "list.png");
      end;
   end List;

   ----------
   -- Para --
   ----------

   procedure Para (T : in out Trendy_Test.Operation'Class) is
   begin
      T.Register (Parallelize => False);

      declare
         Context : constant Cairo.Cairo_Context :=
          Testsuite.Create_Cairo_Context (800, 600);

         Parser   : Markdown.Parsers.Markdown_Parser;
         Renderer : Markdown.Renderer.Renderer;
      begin
         Set_Styles (Renderer);
         Parse
          (Parser,
           ["This is a paragraph. It should be rendered with its style.",
            "This is a paragraph. It should be rendered with its style.",
            "This is a paragraph. It should be rendered with its style.",
            "This is a paragraph. It should be rendered with its style.",
            "This is a paragraph. It should be rendered with its style.",
            "This is a paragraph. It should be rendered with its style.",
            "This is a paragraph. It should be rendered with its style.",
            "This is a paragraph. It should be rendered with its style.",
            --  "",
            "Put some markup in here paragraph:",
            "`Code`, *Italic*, **Bold**.",
            ""]);

         Renderer.Render
           (Context  => Context,
            Width    => 800,
            Height   => 600,
            Document => Parser.Document);
         Assert (T, Context, "para.png");
      end;
   end Para;

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
      pragma Warnings (Off, "static fixed-point value is not a multiple");

      Map : constant array (Markdown.Blocks.ATX_Headings.Heading_Level) of
        Markdown.Styles.Pango_Unit :=
         [1 => 32.0,
          2 => 24.0,
          3 => 19.2,
          4 => 16.0,
          5 => 12.8,
          6 => 11.2];

      pragma Warnings (On, "static fixed-point value is not a multiple");
   begin
      declare
         Style : Markdown.Styles.Style;
      begin
         Style.Set_Font_Family ("Ubuntu");
         Style.Set_Font_Size (16.0);
         Style.Set_Margin (Top => 10, Right => 20, Bottom => 0, Left => 30);
         Renderer.Set_Default_Style (Style);
      end;

      for Level in Map'Range loop
         declare
            Style : Markdown.Styles.Style;
         begin
            Style.Set_Font_Size (Map (Level));
            Renderer.Set_Heading_Style (Level, Style);
         end;
      end loop;

      declare
         Style : Markdown.Styles.Style;
      begin
         Style.Set_Font_Family ("Ubuntu");
         Style.Set_Font_Size (14.0);
         Renderer.Set_Paragraph_Style (Style);
      end;

      declare
         Style : Markdown.Styles.Style;
      begin
         Style.Set_Margin (Top => 0, Right => 0, Bottom => 0, Left => 30);
         Style.Set_Font_Family ("Ubuntu");
         Style.Set_Font_Size (14.0);
         Renderer.Set_List_Item_Style (Style);
      end;

      declare
         Style : Markdown.Styles.Style;
      begin
         Style.Set_Font_Family ("Ubuntu Mono");
         Renderer.Set_Code_Span_Style (Style);
      end;

      declare
         Style : Markdown.Styles.Style;
      begin
         Style.Set_Font_Family ("Ubuntu Mono");
         Style.Set_Font_Weight ("bold");
         Style.Set_Font_Size (14.0);
         Renderer.Set_Code_Block_Style (Style);
      end;
   end Set_Styles;

end Testsuite.Elements;
