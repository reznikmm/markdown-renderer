# markdown-renderer

[![Build with Alire](https://github.com/reznikmm/markdown-renderer/actions/workflows/alire.yml/badge.svg)](https://github.com/reznikmm/markdown-renderer/actions/workflows/alire.yml)

> A Pango/Cairo-Based Markdown Rendering Library for Ada

A lightweight library for rendering Markdown documents using Cairo graphics.
This library provides comprehensive Markdown rendering capabilities with
customizable styling, syntax highlighting, and support for various Markdown
elements while prioritizing simplicity and extensibility.

## Features

- Most of Markdown rendering support:
  - ATX headings with customizable styles per level
  - Paragraphs with configurable formatting
  - Code blocks with syntax highlighting
  - Inline code spans
  - Lists with customizable item styles
  - Various inline elements
- Cairo-based rendering for high-quality output
- Extensible syntax highlighting system:
  - Built-in Ada syntax highlighter
  - Plugin architecture for custom language highlighters
- Flexible styling system:
  - Customizable fonts, colors, and spacing
  - Individual styles for different Markdown elements
  - Token-based styling for syntax highlighting (10 token kinds)
- Pure Ada implementation with Cairo and Pango integration
- Type-safe API with tagged types

## Design Philosophy

This library focuses on providing a complete Markdown rendering solution
for Ada applications that need to display formatted text. The implementation
prioritizes:

- Extensibility through highlighter plugins
- Fine-grained control over visual presentation
- Integration with the Cairo graphics library
- Clean separation between content and presentation
- Type safety with Ada's strong typing system
- Efficient rendering with Pango text layout

## Installation

Add this library to your project using Alire:

```shell
alr with markdown_renderer --use=https://github.com/reznikmm/markdown-renderer
```

## Usage

### Basic Rendering

Render a Markdown document to a Cairo surface:

```ada
with Markdown.Renderer;
with Markdown.Documents;
with Cairo;

procedure Basic_Example is
   Renderer : Markdown.Renderer.Renderer;
   Document : Markdown.Documents.Document;
   Context  : Cairo.Cairo_Context;
begin
   -- Load or create your document
   -- ... initialize Document ...
   
   -- Render to Cairo context
   Renderer.Render
     (Context  => Context,
      Width    => 800,
      Height   => 600,
      Document => Document);
end Basic_Example;
```

### Customizing Styles

Configure styles for different Markdown elements:

```ada
with Markdown.Renderer;
with Markdown.Styles;
with VSS.Strings;

procedure Style_Example is
   Renderer : Markdown.Renderer.Renderer;
   Style    : Markdown.Styles.Style;
begin
   -- Configure default style
   Style.Set_Font_Family (VSS.Strings.To_Virtual_String ("Sans"));
   Style.Set_Font_Size (12.0);
   Style.Set_Foreground_Color (VSS.Strings.To_Virtual_String ("#000000"));
   Renderer.Set_Default_Style (Style);
   
   -- Configure heading styles
   Style.Set_Font_Size (24.0);
   Style.Set_Font_Weight (VSS.Strings.To_Virtual_String ("bold"));
   Renderer.Set_Heading_Style (Level => 1, Style => Style);
   
   -- Configure paragraph style with margins
   Style.Set_Margin (Top => 10, Bottom => 10);
   Renderer.Set_Paragraph_Style (Style);
   
   -- Configure code span style
   Style.Set_Font_Family (VSS.Strings.To_Virtual_String ("Monospace"));
   Style.Set_Foreground_Color (VSS.Strings.To_Virtual_String ("#c7254e"));
   Renderer.Set_Code_Span_Style (Style);
end Style_Example;
```

### Syntax Highlighting

Register syntax highlighters for code blocks:

```ada
with Markdown.Renderer;
with Markdown.Highlighters.Ada;
with Markdown.Styles;
with VSS.Strings;

procedure Highlighter_Example is
   Renderer    : Markdown.Renderer.Renderer;
   Ada_HL      : aliased Markdown.Highlighters.Ada.Ada_Highlighter;
   
   Keyword_Style : Markdown.Styles.Style;
   Comment_Style : Markdown.Styles.Style;
   String_Style  : Markdown.Styles.Style;
begin
   -- Initialize highlighter with styles
   Keyword_Style.Set_Foreground_Color
     (VSS.Strings.To_Virtual_String ("#0000ff"));
   Comment_Style.Set_Foreground_Color
     (VSS.Strings.To_Virtual_String ("#008000"));
   String_Style.Set_Foreground_Color
     (VSS.Strings.To_Virtual_String ("#a31515"));
   
   Ada_HL.Initialize
     (Keyword => Keyword_Style,
      Id      => Markdown.Styles.Style'(others => <>),
      Comment => Comment_Style,
      String  => String_Style,
      Char    => String_Style,
      Number  => Markdown.Styles.Style'(others => <>));
   
   -- Register highlighter for Ada language
   Renderer.Register_Highlighter
     (Language => VSS.Strings.To_Virtual_String ("ada"),
      Value    => Ada_HL'Access);
end Highlighter_Example;
```

### Advanced Styling

Work with margins, fonts, and token styles:

```ada
with Markdown.Renderer;
with Markdown.Styles;

procedure Advanced_Styling is
   Renderer : Markdown.Renderer.Renderer;
   Style    : Markdown.Styles.Style;
begin
   -- Configure code block style with background
   Style.Set_Font_Family (VSS.Strings.To_Virtual_String ("Courier New"));
   Style.Set_Font_Size (10.0);
   Style.Set_Margin (Top => 15, Right => 10, Bottom => 15, Left => 10);
   Style.Set_Background_Color (VSS.Strings.To_Virtual_String ("#f5f5f5"));
   Renderer.Set_Code_Block_Style (Style);
   
   -- Configure list item style
   Style.Set_Margin (Top => 5, Left => 20);
   Renderer.Set_List_Item_Style (Style);
   
   -- Configure token styles for syntax highlighting
   for Token in Markdown.Renderer.Token_Kind'Range loop
      Style.Set_Foreground_Color
        (VSS.Strings.To_Virtual_String ("#" & Token'Image));
      Renderer.Set_Token_Style (Token, Style);
   end loop;
end Advanced_Styling;
```

## Style System

The library provides a comprehensive styling system through `Markdown.Styles.Style`:

- **Font Properties**: Family, weight, and size (in Pango units: 1/1024 of a point)
- **Colors**: Foreground and background colors (specified as hex strings)
- **Spacing**: Top, right, bottom, and left margins
- **Element Styles**: Separate styles for headings (6 levels), paragraphs, code spans, code blocks, and list items
- **Token Styles**: 10 customizable token styles for syntax highlighting

## Highlighter System

Create custom syntax highlighters by implementing the `Markdown.Highlighters.Highlighter` interface:

```ada
type Custom_Highlighter is limited new Highlighter with private;

procedure Highlight
  (Self   : Custom_Highlighter;
   Info   : VSS.Strings.Virtual_String;
   Lines  : VSS.String_Vectors.Virtual_String_Vector;
   Action : not null access procedure
     (Text     : VSS.Strings.Virtual_String;
      Style    : Markdown.Styles.Style;
      New_Line : Boolean));
```

The built-in Ada highlighter demonstrates:
- Keyword recognition
- String and character literal handling
- Comment detection
- Number formatting
- Identifier styling

## Dependencies

This library requires:
- Cairo graphics library
- Pango text layout library
- [AdaCore Markdown parser](https://github.com/AdaCore/markdown)
- VSS (Virtual String Subsystem)

## Performance Notes

- Efficient Cairo and Pango integration for text rendering
- Optimized for document display and printing
- Supports various Cairo surfaces (image, PDF, SVG, etc.)

## Maintainer

[@MaximReznik](https://github.com/reznikmm)

## Contribute

Contributions are welcome! Feel free to submit a pull request.

## License

This project is licensed under the Apache 2.0 License with LLVM Exceptions.
See the [LICENSES](LICENSES) files for details.
