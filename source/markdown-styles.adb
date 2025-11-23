--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

package body Markdown.Styles is

   ---------------------
   -- Set_Font_Family --
   ---------------------

   procedure Set_Font_Family
     (Self  : in out Style;
      Value : VSS.Strings.Virtual_String) is
   begin
      Self.Font_Family := Value;
   end Set_Font_Family;

   -------------------
   -- Set_Font_Size --
   -------------------

   procedure Set_Font_Size
     (Self  : in out Style;
      Value : Pango_Unit) is
   begin
      Self.Font_Size := Value;
   end Set_Font_Size;

   ---------------------
   -- Set_Font_Weight --
   ---------------------

   procedure Set_Font_Weight
     (Self  : in out Style;
      Value : VSS.Strings.Virtual_String) is
   begin
      Self.Font_Weight := Value;
   end Set_Font_Weight;

   --------------------------
   -- Set_Foreground_Color --
   --------------------------

   procedure Set_Foreground_Color
     (Self  : in out Style;
      Value : VSS.Strings.Virtual_String)
   is
      use type VSS.Strings.Character_Count;
   begin
      pragma Assert (Value.Character_Length = 6);
      Self.Foreground := Value;
   end Set_Foreground_Color;

   ----------------
   -- Set_Margin --
   ----------------

   procedure Set_Margin
     (Self   : in out Style;
      Top    : Natural := 0;
      Right  : Natural := 0;
      Bottom : Natural := 0;
      Left   : Natural := 0) is
   begin
      Self.Margin_Top    := Top;
      Self.Margin_Right  := Right;
      Self.Margin_Bottom := Bottom;
      Self.Margin_Left   := Left;
   end Set_Margin;

end Markdown.Styles;
