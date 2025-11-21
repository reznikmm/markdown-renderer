--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Markdown.Parsers;

with Trendy_Test.Reports;

with Glib.Application;

with Testsuite.Elements;

procedure Testsuite.Driver is
   --  use type Trendy_Test.Test_Group;

   App : constant Glib.Application.Gapplication :=
     Glib.Application.Gapplication_New
     (Application_Id => "org.markdown.renderer.testsuite",
      Flags => Glib.Application.G_Application_Flags_None);

   procedure Run (Self : access Glib.Application.Gapplication_Record'Class);

   ---------
   -- Run --
   ---------

   procedure Run (Self : access Glib.Application.Gapplication_Record'Class) is
      pragma Unreferenced (Self);
      All_Tests : constant Trendy_Test.Test_Group :=
        Testsuite.Elements.Tests;
   begin
      Markdown.Parsers.Initialize;
      Trendy_Test.Register (All_Tests);
      Trendy_Test.Reports.Print_Basic_Report (Trendy_Test.Run);
      App.Quit;
   end Run;

   Ignore : Glib.Gint;
begin
   App.On_Activate (Call => Run'Unrestricted_Access);
   Ignore := App.Run;
   App.Unref;
end Testsuite.Driver;
