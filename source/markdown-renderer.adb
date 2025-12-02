--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Pango.Cairo;
with System;

with Markdown.Block_Containers;
with Markdown.Blocks;
with Markdown.Blocks.Lists;
with Markdown.Blocks.Paragraphs;
with Markdown.Blocks.Fenced_Code;
with Markdown.Inlines;

with Glib.Object;

with Pango.Attributes;
with Pango.Enums;
with Pango.Layout;

with VSS.Characters.Latin;
with VSS.String_Vectors;
with VSS.Strings.Conversions;
with VSS.Unicode;

package body Markdown.Renderer is

   type Block_Offset is record
      Width       : Positive;
      Height      : Positive;
      Offset_X    : Natural;
      Offset_Y    : Natural;
      Prev_Margin : Natural := 0;
   end record;

   type Color is record
      Red, Green, Blue : Glib.Guint16;
   end record;

   function To_Color (Text : VSS.Strings.Virtual_String) return Color;

   type Dummy_Highlighter is new Markdown.Highlighters.Highlighter
     with null record;

   overriding procedure Highlight
     (Self   : Dummy_Highlighter;
      Info   : VSS.Strings.Virtual_String;
      Lines  : VSS.String_Vectors.Virtual_String_Vector;
      Action : not null access procedure
        (Text     : VSS.Strings.Virtual_String;
         Style    : Markdown.Styles.Style;
         New_Line : Boolean));

   Dummy : aliased Dummy_Highlighter;

   function Highlighter
     (Self : Renderer'Class;
      Language : VSS.Strings.Virtual_String)
      return Markdown.Highlighters.Highlighter_Access is
     (if Self.Highlighters.Contains (Language)
      then Self.Highlighters (Language)
      elsif Self.Highlighters.Contains (VSS.Strings.Empty_Virtual_String)
      then Self.Highlighters (VSS.Strings.Empty_Virtual_String)
      else Dummy'Access);

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

   procedure Render_List
     (Self    : Renderer'Class;
      Context : Cairo.Cairo_Context;
      List    : Markdown.Blocks.Lists.List;
      Offset  : in out Block_Offset);

   procedure Assign_Markup
     (Self   : Renderer'Class;
      Style  : Markdown.Styles.Style;
      Layout : Pango.Layout.Pango_Layout;
      Vector : Markdown.Inlines.Inline_Vector);
   --  Assign text and attributes to Pango layout based on inline vector.
   --  Use enclosing block Style for default text attributes.

   procedure Set_Span
     (Attr : Pango.Attributes.Pango_Attribute;
      From : VSS.Unicode.UTF8_Code_Unit_Offset;
      To   : VSS.Unicode.UTF8_Code_Unit_Offset);

   procedure Apply_Style
     (List  : Pango.Attributes.Pango_Attr_List;
      Style : Markdown.Styles.Style;
      From  : VSS.Unicode.UTF8_Code_Unit_Offset;
      To    : VSS.Unicode.UTF8_Code_Unit_Offset);

   procedure Show_Layout
     (Context : Cairo.Cairo_Context;
      Layout  : Pango.Layout.Pango_Layout;
      Style   : Markdown.Styles.Style;
      Offset  : in out Block_Offset);

   use type VSS.Unicode.UTF8_Code_Unit_Offset;

   function Next_Offset (Text : VSS.Strings.Virtual_String)
     return VSS.Unicode.UTF8_Code_Unit_Offset is
       (if Text.Is_Empty then 0
        else Text.At_Last_Character.Last_UTF8_Offset + 1);

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
      use type VSS.Strings.Virtual_String;

      function Attr_Size_New
        (Size : Glib.Gint) return Pango.Attributes.Pango_Attribute;
      pragma Import (C, Attr_Size_New, "pango_attr_size_new");
      --  Create a new font-size attribute in fractional points.

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

      if not Style.Font_Weight.Is_Empty then
         declare
            Attr : constant Pango.Attributes.Pango_Attribute :=
              Pango.Attributes.Attr_Weight_New
                (if Style.Font_Weight = "bold"
                 then Pango.Enums.Pango_Weight_Bold
                 else Pango.Enums.Pango_Weight_Normal);
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

      if not Style.Foreground_Color.Is_Empty then
         declare
            Value : constant Color := To_Color (Style.Foreground_Color);
            Attr : constant Pango.Attributes.Pango_Attribute :=
              Pango.Attributes.Attr_Foreground_New
                (Red => Value.Red,
                 Green => Value.Green,
                 Blue => Value.Blue);
         begin
            Set_Span (Attr, From, To);
            List.Insert (Attr);
         end;
      end if;
   end Apply_Style;

   -------------------
   -- Assign_Markup --
   -------------------

   procedure Assign_Markup
     (Self   : Renderer'Class;
      Style  : Markdown.Styles.Style;
      Layout : Pango.Layout.Pango_Layout;
      Vector : Markdown.Inlines.Inline_Vector)
   is
      function Attr_Style_New
        (Style : Pango.Enums.Style) return Pango.Attributes.Pango_Attribute;
      pragma Import (C, Attr_Style_New, "pango_attr_style_new");
      --  Create a new font style attribute.
      --  "style": the style

      procedure Walk
        (Cursor : in out Markdown.Inlines.Inline_Vectors.Cursor;
         Text   : in out VSS.Strings.Virtual_String;
         List   : Pango.Attributes.Pango_Attr_List);

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
                        From : constant VSS.Unicode.UTF8_Code_Unit_Offset :=
                          Next_Offset (Text);

                     begin
                        Text.Append (Item.Code_Span);

                        Apply_Style
                          (List,
                           Self.Code_Span_Style,
                           From,
                           Next_Offset (Text));
                     end;

                  when Markdown.Inlines.Start_Emphasis  =>
                     declare
                        From : constant VSS.Unicode.UTF8_Code_Unit_Offset :=
                          Next_Offset (Text);

                        Attr : constant Pango.Attributes.Pango_Attribute :=
                          Attr_Style_New (Pango.Enums.Pango_Style_Italic);
                     begin
                        Markdown.Inlines.Inline_Vectors.Next (Cursor);
                        Walk (Cursor, Text, List);
                        Set_Span (Attr, From, Next_Offset (Text));
                        List.Insert (Attr);
                     end;

                  when Markdown.Inlines.End_Emphasis    =>
                     exit;

                  when Markdown.Inlines.Start_Strong    =>
                     declare
                        From : constant VSS.Unicode.UTF8_Code_Unit_Offset :=
                          Next_Offset (Text);

                        Attr : constant Pango.Attributes.Pango_Attribute :=
                          Pango.Attributes.Attr_Weight_New
                            (Pango.Enums.Pango_Weight_Bold);
                     begin
                        Markdown.Inlines.Inline_Vectors.Next (Cursor);
                        Walk (Cursor, Text, List);
                        Set_Span (Attr, From, Next_Offset (Text));
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
      Apply_Style (List, Self.Default_Style, 0, -1);
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

   ---------------
   -- Highlight --
   ---------------

   overriding procedure Highlight
     (Self   : Dummy_Highlighter;
      Info   : VSS.Strings.Virtual_String;
      Lines  : VSS.String_Vectors.Virtual_String_Vector;
      Action : not null access procedure
        (Text     : VSS.Strings.Virtual_String;
         Style    : Markdown.Styles.Style;
         New_Line : Boolean)) is
   begin
      for Index in 1 .. Lines.Last_Index loop
         Action
           (Lines (Index),
            Markdown.Styles.Empty_Style,
            Index /= Lines.Last_Index);
      end loop;
   end Highlight;

   --------------------------
   -- Register_Highlighter --
   --------------------------

   procedure Register_Highlighter
     (Self     : in out Renderer'Class;
      Language : VSS.Strings.Virtual_String;
      Value    : not null Markdown.Highlighters.Highlighter_Access) is
   begin
      Self.Highlighters.Include (Language, Value);
   end Register_Highlighter;

   ------------
   -- Render --
   ------------

   procedure Render
     (Self     : Renderer'Class;
      Context  : Cairo.Cairo_Context;
      Width    : Positive;
      Height   : Positive;
      Document : Markdown.Documents.Document'Class)
   is
      Style : constant Markdown.Styles.Style := Self.Default_Style;

      Offset : Block_Offset :=
        (Width       => Width - Style.Right_Margin,
         Height      => Height - Style.Bottom_Margin,
         Offset_X    => Style.Left_Margin,
         Offset_Y    => Style.Top_Margin,
         Prev_Margin => 0);
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
      procedure Render_Inlines
        (Text  : Markdown.Inlines.Inline_Vector;
         Style : Markdown.Styles.Style);

      procedure Render_Code
        (Info        : VSS.Strings.Virtual_String;
         Lines       : VSS.String_Vectors.Virtual_String_Vector;
         Highlighter : not null Markdown.Highlighters.Highlighter_Access;
         Style       : Markdown.Styles.Style);

      -----------------
      -- Render_Code --
      -----------------

      procedure Render_Code
        (Info        : VSS.Strings.Virtual_String;
         Lines       : VSS.String_Vectors.Virtual_String_Vector;
         Highlighter : not null Markdown.Highlighters.Highlighter_Access;
         Style       : Markdown.Styles.Style)
      is
         procedure Action
           (Text     : VSS.Strings.Virtual_String;
            Style    : Markdown.Styles.Style;
            New_Line : Boolean);

         Result : VSS.Strings.Virtual_String;
         List   : constant Pango.Attributes.Pango_Attr_List :=
           Pango.Attributes.Pango_Attr_List_New;

         ------------
         -- Action --
         ------------

         procedure Action
           (Text     : VSS.Strings.Virtual_String;
            Style    : Markdown.Styles.Style;
            New_Line : Boolean)
         is
            From : constant VSS.Unicode.UTF8_Code_Unit_Offset :=
              Next_Offset (Result);

         begin
            if not Text.Is_Empty then
               Result.Append (Text);
               Apply_Style (List, Style, From, Next_Offset (Result));
            end if;

            if New_Line then
               Result.Append (VSS.Characters.Latin.Line_Feed);
            end if;
         end Action;

         Layout : constant Pango.Layout.Pango_Layout :=
           Create_Layout (Context);

      begin
         --  Apply_Style (List, Self.Default_Style, 0, -1);
         Apply_Style (List, Style, 0, -1);
         Highlighter.Highlight (Info, Lines, Action'Access);
         Layout.Set_Text (VSS.Strings.Conversions.To_UTF_8_String (Result));
         Layout.Set_Attributes (List);
         Show_Layout (Context, Layout, Style, Offset);
      end Render_Code;

      --------------------
      -- Render_Inlines --
      --------------------

      procedure Render_Inlines
        (Text  : Markdown.Inlines.Inline_Vector;
         Style : Markdown.Styles.Style)
      is
         Layout : constant Pango.Layout.Pango_Layout :=
           Create_Layout (Context);

      begin
         Self.Assign_Markup (Style, Layout, Text);
         Show_Layout (Context, Layout, Style, Offset);
      end Render_Inlines;

   begin
      if Block.Is_ATX_Heading then
         declare
            Heading : Markdown.Blocks.ATX_Headings.ATX_Heading renames
              Block.To_ATX_Heading;

            Style : constant Markdown.Styles.Style :=
              Self.Heading_Styles (Heading.Level);

            Text : constant Markdown.Inlines.Inline_Vector :=
              Heading.Text;

         begin
            Render_Inlines (Text, Style);
         end;
      elsif Block.Is_Paragraph then
         Render_Inlines (Block.To_Paragraph.Text, Self.Paragraph_Style);
      elsif Block.Is_List then
         Render_List (Self, Context, Block.To_List, Offset);
      elsif Block.Is_Fenced_Code_Block then
         Render_Code
           (Block.To_Fenced_Code_Block.Info_String,
            Block.To_Fenced_Code_Block.Text,
            Self.Highlighter (Block.To_Fenced_Code_Block.Info_String),
            Self.Code_Block_Style);
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

   ------------------
   -- Render_Block --
   ------------------

   procedure Render_List
     (Self    : Renderer'Class;
      Context : Cairo.Cairo_Context;
      List    : Markdown.Blocks.Lists.List;
      Offset  : in out Block_Offset)
   is
      use type VSS.Strings.Virtual_String;

      procedure Render_Marker
        (Marker : VSS.Strings.Virtual_String;
         Style  : Markdown.Styles.Style);

      procedure Render_Marker
        (Marker : VSS.Strings.Virtual_String;
         Style  : Markdown.Styles.Style)
      is
         Layout : constant Pango.Layout.Pango_Layout :=
           Create_Layout (Context);

         Text : Markdown.Inlines.Inline_Vector;

         Offset_Y : constant Natural := Offset.Offset_Y +
           Natural'Max (Style.Top_Margin, Offset.Prev_Margin);
      begin
         Text.Append
           (Markdown.Inlines.Inline'
             (Kind => Markdown.Inlines.Text,
              Text => Marker));

         Self.Assign_Markup (Style, Layout, Text);

         Cairo.Save (Context);

         Cairo.Move_To
           (Context,
            Glib.Gdouble (Offset.Offset_X - Style.Left_Margin),
            Glib.Gdouble (Offset_Y));

         Pango.Cairo.Show_Layout (Context, Layout);

         Cairo.Restore (Context);
      end Render_Marker;

      function Marker_Image
        (Index : Natural) return VSS.Strings.Virtual_String is
          (VSS.Strings.Conversions.To_Virtual_String (Index'Image) & ".");

      Style : constant Markdown.Styles.Style := Self.List_Item_Style;
      Index : Natural := (if List.Is_Ordered then List.Start else 0);
   begin
      Offset.Offset_X := Offset.Offset_X + Style.Left_Margin;
      Offset.Width := Offset.Width - Style.Left_Margin - Style.Right_Margin;

      for Item of List loop
         Render_Marker
          ((if List.Is_Ordered then Marker_Image (Index) else "-"), Style);

         Self.Render_Blocks
           (Context, Item, Tight => not List.Is_Loose, Offset => Offset);

         Index := Index + 1;
      end loop;

      Offset.Width := Offset.Width + Style.Left_Margin + Style.Right_Margin;
      Offset.Offset_X := Offset.Offset_X - Style.Left_Margin;
   end Render_List;

   --------------------------
   -- Set_Code_Block_Style --
   --------------------------

   procedure Set_Code_Block_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style) is
   begin
      Self.Code_Block_Style := Style;
   end Set_Code_Block_Style;

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

   -------------------------
   -- Set_List_Item_Style --
   -------------------------

   procedure Set_List_Item_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style) is
   begin
      Self.List_Item_Style := Style;
   end Set_List_Item_Style;

   -------------------------
   -- Set_Paragraph_Style --
   -------------------------

   procedure Set_Paragraph_Style
     (Self  : in out Renderer'Class;
      Style : Markdown.Styles.Style) is
   begin
      Self.Paragraph_Style := Style;
   end Set_Paragraph_Style;

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
         Klass       : System.Address;
         Start_Index : Glib.Guint;
         End_Index   : Glib.Guint;
      end record;

      Object : Internal
        with Import, Address => Pango.Attributes.Convert (Attr);
   begin
      Object.Start_Index := To_Guint (From);
      Object.End_Index := To_Guint (To);
   end Set_Span;

   ---------------------
   -- Set_Token_Style --
   ---------------------

   procedure Set_Token_Style
     (Self  : in out Renderer'Class;
      Token : Token_Kind;
      Style : Markdown.Styles.Style) is
   begin
      Self.Token_Styles (Token) := Style;
   end Set_Token_Style;

   -----------------
   -- Show_Layout --
   -----------------

   procedure Show_Layout
     (Context : Cairo.Cairo_Context;
      Layout  : Pango.Layout.Pango_Layout;
      Style   : Markdown.Styles.Style;
      Offset  : in out Block_Offset)
   is
      Width : constant Positive :=
        Positive'Max
          (50,
           Offset.Width - Offset.Offset_X -
             Style.Left_Margin - Style.Right_Margin);

      Ignore, Height : Glib.Gint;
   begin
      Offset.Offset_Y := Offset.Offset_Y +
        Natural'Max (Style.Top_Margin, Offset.Prev_Margin);

      Layout.Set_Width (Glib.Gint (Pango.Enums.Pango_Scale * Width));

      Cairo.Move_To
        (Context,
         Glib.Gdouble (Offset.Offset_X + Style.Left_Margin),
         Glib.Gdouble (Offset.Offset_Y));

      Pango.Cairo.Show_Layout (Context, Layout);
      Layout.Get_Size (Ignore, Height);

      Offset.Offset_Y := Offset.Offset_Y +
        Positive (Pango.Enums.To_Pixels (Height));

      Offset.Prev_Margin := Style.Bottom_Margin;
   end Show_Layout;

   function To_Color (Text : VSS.Strings.Virtual_String) return Color is

      function To_Number (Text : String) return Glib.Guint16 is
         (Glib.Guint16'Value ("16#" & Text & "00#"));

      Image : constant String :=
        VSS.Strings.Conversions.To_UTF_8_String (Text);
   begin
      return Result : Color do
         Result.Red := To_Number (Image (2 .. 3));
         Result.Green := To_Number (Image (4 .. 5));
         Result.Blue := To_Number (Image (6 .. 7));
      end return;
   end To_Color;

end Markdown.Renderer;
