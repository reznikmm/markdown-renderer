--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with VSS.Strings;

package Markdown.Styles is

   type Style is tagged private;

   procedure Set_Margin
     (Self   : in out Style;
      Top    : Natural := 0;
      Right  : Natural := 0;
      Bottom : Natural := 0;
      Left   : Natural := 0);

   function Top_Margin (Self : Style) return Natural;
   function Right_Margin (Self : Style) return Natural;
   function Bottom_Margin (Self : Style) return Natural;
   function Left_Margin (Self : Style) return Natural;

   procedure Set_Font_Family
     (Self  : in out Style;
      Value : VSS.Strings.Virtual_String);

   function Font_Family (Self : Style) return VSS.Strings.Virtual_String;

private

   type Style is tagged record
      Margin_Top    : Natural := 0;
      Margin_Right  : Natural := 0;
      Margin_Bottom : Natural := 0;
      Margin_Left   : Natural := 0;
      Font_Family   : VSS.Strings.Virtual_String;
   end record;

   function Top_Margin (Self : Style) return Natural is (Self.Margin_Top);
   function Right_Margin (Self : Style) return Natural is (Self.Margin_Right);
   function Bottom_Margin (Self : Style) return Natural is
     (Self.Margin_Bottom);

   function Left_Margin (Self : Style) return Natural is (Self.Margin_Left);
   function Font_Family (Self : Style) return VSS.Strings.Virtual_String is
     (Self.Font_Family);

end Markdown.Styles;
