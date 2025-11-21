--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Containers.Hashed_Maps;

with Markdown.Blocks.ATX_Headings;
with Markdown.Documents;
with Markdown.Highlighters;
with Markdown.Styles;

with Cairo;
with VSS.Strings.Hash;

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

   procedure Register_Highlighter
     (Self     : in out Renderer'Class;
      Language : VSS.Strings.Virtual_String;
      Value    : not null Markdown.Highlighters.Highlighter_Access);

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

   procedure Set_Paragraph_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style);

   function Paragraph_Style
     (Self : Renderer'Class) return Markdown.Styles.Style;

   procedure Set_Code_Span_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style);

   function Code_Span_Style
     (Self : Renderer'Class) return Markdown.Styles.Style;

   procedure Set_Code_Block_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style);

   function Code_Block_Style
     (Self : Renderer'Class) return Markdown.Styles.Style;

   procedure Set_List_Item_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style);

   function List_Item_Style
     (Self : Renderer'Class) return Markdown.Styles.Style;

private

   package Highlighter_Maps is new Ada.Containers.Hashed_Maps
     (Key_Type        => VSS.Strings.Virtual_String,
      Element_Type    => Markdown.Highlighters.Highlighter_Access,
      Hash            => VSS.Strings.Hash,
      Equivalent_Keys => VSS.Strings."=",
      "="             => Markdown.Highlighters."=");

   type Style_Array is array (Markdown.Blocks.ATX_Headings.Heading_Level) of
     Markdown.Styles.Style;

   type Renderer is tagged limited record
      Highlighters     : Highlighter_Maps.Map;
      Default_Style    : Markdown.Styles.Style;
      Heading_Styles   : Style_Array;
      Paragraph_Style  : Markdown.Styles.Style;
      Code_Span_Style  : Markdown.Styles.Style;
      Code_Block_Style : Markdown.Styles.Style;
      List_Item_Style  : Markdown.Styles.Style;
   end record;

   function Default_Style
     (Self : Renderer'Class) return Markdown.Styles.Style is
       (Self.Default_Style);

   function Heading_Style
     (Self  : Renderer'Class;
      Level : Markdown.Blocks.ATX_Headings.Heading_Level)
        return Markdown.Styles.Style is (Self.Heading_Styles (Level));

   function Paragraph_Style
     (Self : Renderer'Class) return Markdown.Styles.Style is
       (Self.Paragraph_Style);

   function Code_Span_Style
     (Self : Renderer'Class) return Markdown.Styles.Style is
       (Self.Code_Span_Style);

   function Code_Block_Style
     (Self : Renderer'Class) return Markdown.Styles.Style is
       (Self.Code_Block_Style);

   function List_Item_Style
     (Self : Renderer'Class) return Markdown.Styles.Style is
       (Self.List_Item_Style);

end Markdown.Renderer;
