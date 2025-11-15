--  SPDX-FileCopyrightText: 2025 Max Reznik <reznikmm@gmail.com>
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
----------------------------------------------------------------

with Ada.Command_Line;
with Ada.Directories;

with Ada.Streams;
with Ada.Streams.Stream_IO;
with Ada.Text_IO;
with Cairo.Image_Surface;
with Cairo.Png;
with Glib;

package body Testsuite is

   procedure Compare
     (Operation : in out Trendy_Test.Operation'Class;
      Actual    : String;
      Expected  : String);

   ------------
   -- Assert --
   ------------

   procedure Assert
     (Operation : in out Trendy_Test.Operation'Class;
      Context   : Cairo.Cairo_Context;
      File      : String)
   is
      use type Cairo.Cairo_Status;
      Ok : Cairo.Cairo_Status;
   begin
      Ok := Cairo.Png.Write_To_Png
       (Cairo.Get_Group_Target (Context),
        Filename => "/tmp/" & File);

      Operation.Assert (Ok = Cairo.Cairo_Status_Success);

      Compare
        (Operation => Operation,
         Actual    => "/tmp/" & File,
         Expected  => Ada.Directories.Containing_Directory
           (Ada.Command_Line.Command_Name) & "/../share/" & File);
   end Assert;

   -------------
   -- Compare --
   -------------

   procedure Compare
     (Operation : in out Trendy_Test.Operation'Class;
      Actual    : String;
      Expected  : String)
   is
      use type Ada.Directories.File_Size;
      Input_Actual   : Ada.Streams.Stream_IO.File_Type;
      Input_Expected : Ada.Streams.Stream_IO.File_Type;

      Differ : constant String :=
        "Files " & Actual & " and " & Expected & " differ";
   begin
      if Ada.Directories.Size (Actual) /= Ada.Directories.Size (Expected) then
         Ada.Text_IO.Put_Line
           (Ada.Text_IO.Standard_Error,
            Differ & " in size");
         Operation.Assert (False);
      end if;

      Ada.Streams.Stream_IO.Open
        (File => Input_Actual,
         Name => Actual,
         Mode => Ada.Streams.Stream_IO.In_File);

      Ada.Streams.Stream_IO.Open
        (File => Input_Expected,
         Name => Expected,
         Mode => Ada.Streams.Stream_IO.In_File);

      declare
         use type Ada.Streams.Stream_Element_Count;
         use type Ada.Streams.Stream_Element_Array;
         Actual : Ada.Streams.Stream_Element_Array (1 .. 512);
         Expected : Ada.Streams.Stream_Element_Array (1 .. 512);
         Last : Ada.Streams.Stream_Element_Count;
      begin
         loop
            Ada.Streams.Stream_IO.Read
              (File => Input_Actual,
               Item => Actual,
               Last => Last);
            Ada.Streams.Stream_IO.Read
              (File => Input_Expected,
               Item => Expected,
               Last => Last);

            exit when Last = 0;

            if Actual (1 .. Last) /= Expected (1 .. Last) then
               Ada.Text_IO.Put_Line
                 (Ada.Text_IO.Standard_Error,
                  Differ & " in content");
               Operation.Assert (False);
            end if;
         end loop;
      end;

      Ada.Streams.Stream_IO.Close (Input_Actual);
      Ada.Streams.Stream_IO.Close (Input_Expected);
   end Compare;

   --------------------------
   -- Create_Cairo_Context --
   --------------------------

   function Create_Cairo_Context
     (Width, Height : Positive) return Cairo.Cairo_Context is
   begin
      return Cairo.Create
        (Cairo.Image_Surface.Create
          (Format => Cairo.Image_Surface.Cairo_Format_RGB24,
           Width  => Glib.Gint (Width),
           Height => Glib.Gint (Height)));
   end Create_Cairo_Context;

end Testsuite;
