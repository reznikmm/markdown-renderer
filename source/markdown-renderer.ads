--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Markdown.Documents;
with Markdown.Styles;

with Cairo;

package Markdown.Renderer is

   type Renderer is tagged limited private;

   procedure Render
     (Self     : Renderer'Class;
      Context  : Cairo.Cairo_Context;
      Document : Markdown.Documents.Document'Class);

   procedure Set_Default_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style);

   function Default_Style (Self : Renderer'Class) return Markdown.Styles.Style;

   procedure Set_Code_Span_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style);

   function Code_Span_Style
     (Self : Renderer'Class) return Markdown.Styles.Style;

private

   type Renderer is tagged limited record
      Default_Style   : Markdown.Styles.Style;
      Code_Span_Style : Markdown.Styles.Style;
   end record;

   function Code_Span_Style
     (Self : Renderer'Class) return Markdown.Styles.Style is
       (Self.Code_Span_Style);

   function Default_Style
     (Self : Renderer'Class) return Markdown.Styles.Style is
       (Self.Default_Style);

end Markdown.Renderer;
