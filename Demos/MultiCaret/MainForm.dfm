object TMainForm: TTMainForm
  Left = 0
  Top = 0
  Caption = 'MultiCaretDemo'
  ClientHeight = 436
  ClientWidth = 719
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object SynEdit1: TSynEdit
    Left = 0
    Top = 0
    Width = 719
    Height = 436
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Pitch = fpFixed
    Font.Style = []
    TabOrder = 0
    CodeFolding.GutterShapeSize = 11
    CodeFolding.CollapsedLineColor = clGrayText
    CodeFolding.FolderBarLinesColor = clGrayText
    CodeFolding.IndentGuidesColor = clGray
    CodeFolding.IndentGuides = True
    CodeFolding.ShowCollapsedLine = False
    CodeFolding.ShowHintMark = True
    UseCodeFolding = False
    Gutter.AutoSize = True
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -13
    Gutter.Font.Name = 'Consolas'
    Gutter.Font.Style = []
    Gutter.GradientStartColor = clWindowText
    Gutter.GradientEndColor = clWindow
    Lines.Strings = (
      
        'This project demonstrates the code folding capabilities of Syned' +
        'it.'
      
        'Use the menu to open one of the demo files in the project direct' +
        'ory.'
      ''
      'line1'
      'line2'
      'line3'
      'line4'
      ''
      '- demo.cpp'
      '- demo.js'
      '- demo.py'
      
        'Then select "View, Code Folding" to activate Code Foldind and tr' +
        'y the '
      'folding commands under the View menu.'
      ''
      'SynEdit folding commands and their default shorcuts:'
      '  AddKey(ecFoldAll, VK_OEM_MINUS, [ssCtrl, ssShift]);'
      '  AddKey(ecUnfoldAll,  VK_OEM_PLUS, [ssCtrl, ssShift]);'
      '  AddKey(ecFoldNearest, VK_OEM_2, [ssCtrl]);  // Divide '#39'/'#39
      '  AddKey(ecUnfoldNearest, VK_OEM_2, [ssCtrl, ssShift]);'
      '  AddKey(ecFoldLevel1, ord('#39'K'#39'), [ssCtrl], Ord('#39'1'#39'), [ssCtrl]);'
      '  AddKey(ecFoldLevel2, ord('#39'K'#39'), [ssCtrl], Ord('#39'2'#39'), [ssCtrl]);'
      '  AddKey(ecFoldLevel3, ord('#39'K'#39'), [ssCtrl], Ord('#39'3'#39'), [ssCtrl]);'
      
        '  AddKey(ecUnfoldLevel1, ord('#39'K'#39'), [ssCtrl, ssShift], Ord('#39'1'#39'), ' +
        '[ssCtrl, ssShift]);'
      
        '  AddKey(ecUnfoldLevel2, ord('#39'K'#39'), [ssCtrl, ssShift], Ord('#39'2'#39'), ' +
        '[ssCtrl, ssShift]);'
      
        '  AddKey(ecUnfoldLevel3, ord('#39'K'#39'), [ssCtrl, ssShift], Ord('#39'3'#39'), ' +
        '[ssCtrl, ssShift]);'
      ''
      
        'Note: The JavaScript, and Python highlighters are Code Folding e' +
        'nabled, but'
      
        'the C++ highlighter is not.  Code folding for C++ is provided by' +
        ' a Synedit '
      'event handler (ScanForFoldRanges).'
      ''
      
        'You can find technical information about the implementation of c' +
        'ode folding'
      'in the unit SynEditCodeFolding.pas.')
    Options = [eoAutoIndent, eoDragDropEditing, eoEnhanceEndKey, eoGroupUndo, eoShowScrollHint, eoSmartTabDelete, eoSmartTabs, eoTabIndent, eoTabsToSpaces, eoTrimTrailingSpaces]
    TabWidth = 4
    FontSmoothing = fsmNone
  end
end
