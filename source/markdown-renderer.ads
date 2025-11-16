--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Markdown.Blocks.ATX_Headings;
with Markdown.Documents;
with Markdown.Styles;

with Cairo;

package Markdown.Renderer is

   type Renderer is tagged limited private;

   procedure Render
     (Self     : Renderer'Class;
      Context  : Cairo.Cairo_Context;
      Width    : Positive;
      Height   : Positive;
      Document : Markdown.Documents.Document'Class);
   --  Render the given Document into the given Cairo context.
   --  Width and Height specify the size of the corresponding surface.

   procedure Set_Default_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style);

   function Default_Style (Self : Renderer'Class) return Markdown.Styles.Style;

   procedure Set_Heading_Style
     (Self  : in out Renderer'Class;
      Level : Markdown.Blocks.ATX_Headings.Heading_Level;
      Style : Markdown.Styles.Style);

   function Heading_Style
     (Self  : Renderer'Class;
      Level : Markdown.Blocks.ATX_Headings.Heading_Level)
        return Markdown.Styles.Style;

   procedure Set_Code_Span_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style);

   function Code_Span_Style
     (Self : Renderer'Class) return Markdown.Styles.Style;

private

   type Style_Array is array (Markdown.Blocks.ATX_Headings.Heading_Level) of
     Markdown.Styles.Style;

   type Renderer is tagged limited record
      Default_Style   : Markdown.Styles.Style;
      Heading_Styles  : Style_Array;
      Code_Span_Style : Markdown.Styles.Style;
   end record;

   function Default_Style
     (Self : Renderer'Class) return Markdown.Styles.Style is
       (Self.Default_Style);

   function Heading_Style
     (Self  : Renderer'Class;
      Level : Markdown.Blocks.ATX_Headings.Heading_Level)
        return Markdown.Styles.Style is (Self.Heading_Styles (Level));

   function Code_Span_Style
     (Self : Renderer'Class) return Markdown.Styles.Style is
       (Self.Code_Span_Style);

end Markdown.Renderer;
