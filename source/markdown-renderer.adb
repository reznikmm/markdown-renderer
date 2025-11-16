--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Pango.Cairo;
with System;

with Markdown.Block_Containers;
with Markdown.Blocks;
with Markdown.Inlines;

with Glib.Object;

with Pango.Attributes;
with Pango.Enums;
with Pango.Layout;

with VSS.Characters.Latin;
with VSS.Strings;
with VSS.Strings.Conversions;
with VSS.Unicode;

package body Markdown.Renderer is

   type Block_Offset is record
      Top_Margin    : Natural := 0;
      Left_Margin   : Natural := 0;
   end record;

   function Create_Layout
     (Context : Cairo.Cairo_Context) return Pango.Layout.Pango_Layout;

   procedure Render_Blocks
     (Self     : Renderer'Class;
      Context  : Cairo.Cairo_Context;
      List     : Markdown.Block_Containers.Block_Container'Class;
      Tight    : Boolean;
      Offset   : in out Block_Offset);

   procedure Render_Block
     (Self     : Renderer'Class;
      Context  : Cairo.Cairo_Context;
      Block    : Markdown.Blocks.Block;
      Tight    : Boolean;
      Offset   : in out Block_Offset);

   procedure Assign_Markup
     (Self   : Renderer'Class;
      Style  : Markdown.Styles.Style;
      Layout : Pango.Layout.Pango_Layout;
      Vector : Markdown.Inlines.Inline_Vector);
   --  Assign text and attributes to Pango layout based on inline vector.
   --  Use enclosing block Style for default text attributes.

   -------------------
   -- Assign_Markup --
   -------------------

   procedure Assign_Markup
     (Self   : Renderer'Class;
      Style  : Markdown.Styles.Style;
      Layout : Pango.Layout.Pango_Layout;
      Vector : Markdown.Inlines.Inline_Vector)
   is
      use type VSS.Unicode.UTF8_Code_Unit_Offset;

      function Attr_Style_New
        (Style : Pango.Enums.Style) return Pango.Attributes.Pango_Attribute;
      pragma Import (C, Attr_Style_New, "pango_attr_style_new");
      --  Create a new font style attribute.
      --  "style": the style

      function Attr_Size_New
        (Size : Glib.Gint) return Pango.Attributes.Pango_Attribute;
      pragma Import (C, Attr_Size_New, "pango_attr_size_new");
      --  Create a new font-size attribute in fractional points.

      procedure Walk
        (Cursor : in out Markdown.Inlines.Inline_Vectors.Cursor;
         Text   : in out VSS.Strings.Virtual_String;
         List   : Pango.Attributes.Pango_Attr_List);

      procedure Set_Span
        (Attr : Pango.Attributes.Pango_Attribute;
         From : VSS.Unicode.UTF8_Code_Unit_Offset;
         To   : VSS.Unicode.UTF8_Code_Unit_Offset);

      procedure Apply_Style
        (List  : Pango.Attributes.Pango_Attr_List;
         Style : Markdown.Styles.Style;
         From  : VSS.Unicode.UTF8_Code_Unit_Offset;
         To    : VSS.Unicode.UTF8_Code_Unit_Offset);

      -----------------
      -- Apply_Style --
      -----------------

      procedure Apply_Style
        (List  : Pango.Attributes.Pango_Attr_List;
         Style : Markdown.Styles.Style;
         From  : VSS.Unicode.UTF8_Code_Unit_Offset;
         To    : VSS.Unicode.UTF8_Code_Unit_Offset)
      is
         use type Markdown.Styles.Pango_Unit;
      begin
         if not Style.Font_Family.Is_Empty then
            declare
               Attr : constant Pango.Attributes.Pango_Attribute :=
                 Pango.Attributes.Attr_Family_New
                   (VSS.Strings.Conversions.To_UTF_8_String
                     (Style.Font_Family));
            begin
               Set_Span (Attr, From, To);
               List.Insert (Attr);
            end;
         end if;

         if Style.Font_Size /= 0.0 then
            declare
               Attr : constant Pango.Attributes.Pango_Attribute :=
                 Attr_Size_New (Glib.Gint (Style.Font_Size * 1024.0));
            begin
               Set_Span (Attr, From, To);
               List.Insert (Attr);
            end;
         end if;
      end Apply_Style;

      --------------
      -- Set_Span --
      --------------

      procedure Set_Span
        (Attr : Pango.Attributes.Pango_Attribute;
         From : VSS.Unicode.UTF8_Code_Unit_Offset;
         To   : VSS.Unicode.UTF8_Code_Unit_Offset)
      is

         function To_Guint
           (Value : VSS.Unicode.UTF8_Code_Unit_Offset) return Glib.Guint is
             (if Value = -1 then Glib.Guint'Last else Glib.Guint (Value));

         type Internal is record
            Klass : System.Address;
            Start_Index : Glib.Guint;
            End_Index   : Glib.Guint;
         end record;

         Object : Internal
           with Import, Address => Pango.Attributes.Convert (Attr);
      begin
         Object.Start_Index := To_Guint (From);
         Object.End_Index := To_Guint (To);
      end Set_Span;

      ----------
      -- Walk --
      ----------

      procedure Walk
        (Cursor : in out Markdown.Inlines.Inline_Vectors.Cursor;
         Text   : in out VSS.Strings.Virtual_String;
         List   : Pango.Attributes.Pango_Attr_List) is
      begin
         while Markdown.Inlines.Inline_Vectors.Has_Element (Cursor) loop
            declare
               Item : Markdown.Inlines.Inline renames Vector (Cursor);
            begin
               case Item.Kind is
                  when Markdown.Inlines.Text            =>
                     Text.Append (Item.Text);

                  when Markdown.Inlines.Soft_Line_Break =>
                     Text.Append (' ');

                  when Markdown.Inlines.Hard_Line_Break =>
                     Text.Append (VSS.Characters.Latin.Line_Feed);

                  when Markdown.Inlines.Code_Span       =>
                     declare
                        To : VSS.Unicode.UTF8_Code_Unit_Offset;

                        From : constant VSS.Unicode.UTF8_Code_Unit_Offset :=
                          Text.At_Last_Character.Last_UTF8_Offset;

                     begin
                        Text.Append (Item.Code_Span);
                        To := Text.At_Last_Character.Last_UTF8_Offset + 1;

                        Apply_Style
                          (List,
                           Self.Code_Span_Style,
                           From,
                           To);
                     end;

                  when Markdown.Inlines.Start_Emphasis  =>
                     declare
                        To : VSS.Unicode.UTF8_Code_Unit_Offset;

                        From : constant VSS.Unicode.UTF8_Code_Unit_Offset :=
                          Text.At_Last_Character.Last_UTF8_Offset;

                        Attr : constant Pango.Attributes.Pango_Attribute :=
                          Attr_Style_New (Pango.Enums.Pango_Style_Italic);
                     begin
                        Markdown.Inlines.Inline_Vectors.Next (Cursor);
                        Walk (Cursor, Text, List);
                        To := Text.At_Last_Character.Last_UTF8_Offset + 1;
                        Set_Span (Attr, From, To);
                        List.Insert (Attr);
                     end;

                  when Markdown.Inlines.End_Emphasis    =>
                     exit;

                  when Markdown.Inlines.Start_Strong    =>
                     declare
                        To : VSS.Unicode.UTF8_Code_Unit_Offset;

                        From : constant VSS.Unicode.UTF8_Code_Unit_Offset :=
                          Text.At_Last_Character.Last_UTF8_Offset;

                        Attr : constant Pango.Attributes.Pango_Attribute :=
                          Pango.Attributes.Attr_Weight_New
                            (Pango.Enums.Pango_Weight_Bold);
                     begin
                        Markdown.Inlines.Inline_Vectors.Next (Cursor);
                        Walk (Cursor, Text, List);
                        To := Text.At_Last_Character.Last_UTF8_Offset;
                        Set_Span (Attr, From, To);
                        List.Insert (Attr);
                     end;

                  when Markdown.Inlines.End_Strong      =>
                     exit;

                  when Markdown.Inlines.Start_Link      =>
                     null;  -- TBD
                  when Markdown.Inlines.End_Link        =>
                     exit;

                  when others                           =>
                     raise Program_Error;
               end case;
            end;

            Markdown.Inlines.Inline_Vectors.Next (Cursor);
         end loop;
      end Walk;

      Cursor : Markdown.Inlines.Inline_Vectors.Cursor := Vector.First;
      Text   : VSS.Strings.Virtual_String;
      List   : constant Pango.Attributes.Pango_Attr_List :=
        Pango.Attributes.Pango_Attr_List_New;

   begin
      --  Apply_Style (List, Self.Default_Style, 0, -1);
      Apply_Style (List, Style, 0, -1);

      Walk (Cursor, Text, List);

      Layout.Set_Text (VSS.Strings.Conversions.To_UTF_8_String (Text));
      Layout.Set_Attributes (List);
   end Assign_Markup;

   -------------------
   -- Create_Layout --
   -------------------

   function Create_Layout
     (Context : Cairo.Cairo_Context) return Pango.Layout.Pango_Layout
   is
      use Glib.Object;
      use Pango.Layout;

      function Internal (Context : Cairo.Cairo_Context) return System.Address;
      pragma Import (C, Internal, "pango_cairo_create_layout");
      Stub : Pango_Layout_Record;
   begin
      return Pango_Layout (Get_User_Data (Internal (Context), Stub));
   end Create_Layout;

   ------------
   -- Render --
   ------------

   procedure Render
     (Self     : Renderer'Class;
      Context  : Cairo.Cairo_Context;
      Document : Markdown.Documents.Document'Class)
   is
      Offset : Block_Offset := (10, 300);
   begin
      Self.Render_Blocks (Context, Document, False, Offset);
   end Render;

   ------------------
   -- Render_Block --
   ------------------

   procedure Render_Block
     (Self     : Renderer'Class;
      Context  : Cairo.Cairo_Context;
      Block    : Markdown.Blocks.Block;
      Tight    : Boolean;
      Offset   : in out Block_Offset)
   is
   begin
      if Block.Is_ATX_Heading then
         declare
            Layout : constant Pango.Layout.Pango_Layout :=
              Create_Layout (Context);

            Heading : Markdown.Blocks.ATX_Headings.ATX_Heading renames
              Block.To_ATX_Heading;

            Text : constant Markdown.Inlines.Inline_Vector :=
              Heading.Text;
         begin
            Self.Assign_Markup
              (Self.Heading_Styles (Heading.Level), Layout, Text);

            Cairo.Move_To
              (Context,
               Glib.Gdouble (Offset.Left_Margin),
               Glib.Gdouble (Offset.Top_Margin));

            Pango.Cairo.Show_Layout (Context, Layout);
         end;
      end if;
   end Render_Block;

   -------------------
   -- Render_Blocks --
   -------------------

   procedure Render_Blocks
     (Self     : Renderer'Class;
      Context  : Cairo.Cairo_Context;
      List     : Markdown.Block_Containers.Block_Container'Class;
      Tight    : Boolean;
      Offset   : in out Block_Offset) is
   begin
      for Block of List loop
         Self.Render_Block (Context, Block, Tight, Offset);
      end loop;
   end Render_Blocks;

   -------------------------
   -- Set_Code_Span_Style --
   -------------------------

   procedure Set_Code_Span_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style) is
   begin
      Self.Code_Span_Style := Style;
   end Set_Code_Span_Style;

   -----------------------
   -- Set_Default_Style --
   -----------------------

   procedure Set_Default_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style) is
   begin
      Self.Default_Style := Style;
   end Set_Default_Style;

   ----------------------
   -- Set_Header_Style --
   ----------------------

   procedure Set_Heading_Style
     (Self  : in out Renderer'Class;
      Level : Markdown.Blocks.ATX_Headings.Heading_Level;
      Style : Markdown.Styles.Style) is
   begin
      Self.Heading_Styles (Level) := Style;
   end Set_Heading_Style;

end Markdown.Renderer;
